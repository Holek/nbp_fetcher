#!/usr/bin/env ruby

require 'csv'
require 'optparse'
require 'json'
require 'open-uri'
require 'date'

class Result
  def initialize(average:, last:, currency:)
    @average = average
    @last = last
    @currency = currency
  end

  attr_reader :last, :currency

  def inspect
    "#<#{self.class.to_s} currency=#{currency} average=#{average.to_f} last=#{last.to_f}>"
  end

  def average
    # Magic number to round to 4 decimals
    @average.round(4)
  end

  def favorable?
    average >= last
  end

  def to_json
    {currency: currency, average: average.to_f, last: last.to_f, favorable: favorable?}.to_json
  end
end

class NbpFetcher
  @@url_template = 'https://www.nbp.pl/kursy/Archiwum/archiwum_tab_a_{YEAR}.csv'

  ROW_MAP = {"EUR" => "1EUR", "USD" => "1USD"}

  def self.run(currency = "EUR")
    new.run(currency)
  end

  def initialize
    @today = Date.today
    @six_months_ago = @today << 6
  end

  attr_reader :today, :six_months_ago

  def run(currency)
		fetch
		get_results(currency)
	end

  def fetch
    if six_months_ago.year != today.year
      fetch_year(six_months_ago.year)
    end
    fetch_year(today.year)
  end

  def get_results(currency)
    unless %w(USD EUR).include?(currency)
      STDERR.puts "We only accept EUR or USD as foreign currencies for now"
      exit 1
    end

    exchange_rates_during_half_year = parse_csv_between(six_months_ago, today, currency)

    average = exchange_rates_during_half_year.sum(Rational(0)) / Rational(exchange_rates_during_half_year.size)
    last = exchange_rates_during_half_year.last
    Result.new(average: average, last: last, currency: currency)
  end

  def parse_csv_between(after_date, until_date, currency)
    range = (after_date..until_date).map(&method(:date_as_nbp))
    rates = []
    if after_date.year != until_date.year
      rates += parse_csv_year(range, after_date.year, currency)
    end
    rates += parse_csv_year(range, until_date.year, currency)
    rates
  end

  def parse_csv_year(range, year, currency)
    log("Parsing CSV for #{year}")
    parse_year(year).select { |row| range.include?(row["data"]) }.map do |row|
      full, rest = row[ROW_MAP[currency]].split(",")
      Rational([full,rest].join.to_i, 10**(rest.size))
    end
  end

  def parse_year(year)
    CSV.read("tables/#{year}.csv", headers:true, encoding: 'Windows-1252', col_sep: ";")
  end

  def fetch_year(year)
    log("Fetching CSV for year #{year}")
    write = URI.open(@@url_template.gsub("{YEAR}", year.to_s), &:read)
    File.write("tables/#{year}.csv", write)
  end

  def log(*args)
    #puts *args
  end

  def latest_data_available?
    !parse_csv_year([date_as_nbp(today)], today.year, "EUR").empty?
  rescue Errno::ENOENT
    false
  end

  def date_as_nbp(date)
    date.to_s.gsub("-","")
  end
end



Options = Struct.new(:currency, :salary, :format, :all, :average_given, :average)

class Parser
  def self.parse(options)
    args = Options.new("EUR", 20_000, "markdown", false, false, 0.0)

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: #{File.basename(__FILE__)} [options]"

      opts.on("-c", "--currency=USD|EUR", "Currency to track, currently USD or EUR are available") do |c|
        args.currency = c
      end

      opts.on("-a", "--all", "Show all supported currencies") do |a|
        args.all = a
      end

      opts.on("-f", "--format=markdown|line|text", "Output format (line format only supported in single currencies)") do |f|
        args.format = f
      end

			opts.on("-s", "--salary=20000", "Monthly salary in PLN to convert to in desired currency (full amounts only)") do |s|
				args.salary = s.to_i
			end

      opts.on("-v", "--average[=OPTIONAL]", Float, "Currency rate to use to calculate difference from as a float (by default, average of last 6 months)") do |avg|
        if avg
          args.average_given = true
          args.average = Rational(avg)
        end
      end

      opts.on("-h", "--help", "Prints this help") do
        puts opts
        exit
      end
    end

    opt_parser.parse!(options)
    return args
  end
end

def all_supported_currencies(opts)
  fetcher = NbpFetcher.new
  fetcher.fetch unless fetcher.latest_data_available?

  eur = fetcher.get_results("EUR")
  usd = fetcher.get_results("USD")

  if opts.average_given
    eur_avg = usd_avg = opts.average
    second_column = "Rate given"
  else
    eur_avg = eur.average
    usd_avg = usd.average
    second_column = "Average rate in last 6 months"
  end

  eur_salary_exchanged = (Rational(opts.salary) / eur_avg).round(2)
  eur_and_back = (eur_salary_exchanged * eur.last).round(2)

  usd_salary_exchanged = (Rational(opts.salary) / usd_avg).round(2)
  usd_and_back = (usd_salary_exchanged * usd.last).round(2)

  puts <<~MD
    # Salary conversion

    Given salary: **#{opts.salary} PLN**

    | Currency | #{second_column} | Salary in that average | Rate of currency today | Converted back to PLN on #{Date.today.to_s} |
    | -------- | #{"-"* second_column.length} | ---------------------- | ---------------------- | ----------------------------------- |
    | USD      | #{usd_avg.to_f.to_s.ljust(second_column.size)} | $#{usd_salary_exchanged.to_f.to_s.ljust(21)} | #{usd.last.to_f.to_s.ljust(22)} | #{(usd_and_back.to_f.to_s + " PLN").ljust(35)} |
    | EUR      | #{eur_avg.to_f.to_s.ljust(second_column.size)} | €#{eur_salary_exchanged.to_f.to_s.ljust(21)} | #{eur.last.to_f.to_s.ljust(22)} | #{(eur_and_back.to_f.to_s + " PLN").ljust(35)} |



  MD

end

def single_currency(opts)
  fetcher = NbpFetcher.new
  fetcher.fetch unless fetcher.latest_data_available?

  result = fetcher.get_results(opts.currency)

  if opts.average_given
    avg = opts.average
    rate_text = "Rate given"
  else
    avg = result.average
    rate_text = "Average rate of #{opts.currency} in last 6 months"
  end
  salary_exchanged = (Rational(opts.salary) / avg).round(2)
  and_back = (salary_exchanged * result.last).round(2)

  case opts.format
  when "markdown"
    puts <<~MD
      # Salary conversion to #{opts.currency}

      * Given salary: #{opts.salary} PLN
      * #{rate_text}: *#{avg.to_f}*
      * Exchange rate known as of today: *#{result.last.to_f}*

      If you wanted to exchagne your contract today:

      * You would be given #{salary_exchanged.to_f} #{opts.currency} on the contract
      * And you would earn #{and_back.to_f} PLN with today's exchange rate
    MD
  when "line"
    puts "⋍#{salary_exchanged.to_f}#{opts.currency}=#{and_back.to_f}PLN"
  else
    puts "Salary given: #{opts.salary} PLN"
    puts
    puts "#{rate_text}: #{avg.to_f}"
    puts "Exchange rate known as of today:      #{result.last.to_f}"
    puts
    puts "If you wanted to exchange your contract today:"
    puts "* You would be given #{salary_exchanged.to_f} #{opts.currency} on the contract"
    puts "* And you would earn #{and_back.to_f} PLN with today's exchange rate"
  end

end

if __FILE__ == $0
	if ARGV.empty?
		Parser.parse(["-h"])
	else
		opts = Parser.parse(ARGV)
    if opts.all
      all_supported_currencies(opts)
    else
      single_currency(opts)
    end
  end
end

