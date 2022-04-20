require 'csv'
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

  def run(currency)
    unless %w(USD EUR).include?(currency)
      STDERR.puts "We only accept EUR or USD as foreign currencies for now"
      exit 1
    end
    today = Date.today
    six_months_ago = today << 6

    if six_months_ago.year != today.year
      fetch_year(six_months_ago.year)
    end
    fetch_year(today.year)

    exchange_rates_during_half_year = parse_csv_between(six_months_ago, today, currency)

    average = exchange_rates_during_half_year.sum(Rational(0)) / Rational(exchange_rates_during_half_year.size)
    last = exchange_rates_during_half_year.last
    Result.new(average: average, last: last, currency: currency)
  end

  def parse_csv_between(after_date, until_date, currency)
    range = (after_date...until_date).map { |d| d.to_s.gsub("-","") }
    rates = []
    if after_date.year != until_date.year
      rates += parse_csv_year(range, after_date.year, currency)
    end
    rates += parse_csv_year(range, until_date.year, currency)
    rates
  end

  def parse_csv_year(range, year, currency)
    log("Parsing CSV for #{year}")
    csv = CSV.read("tables/#{year}.csv", headers:true, encoding: 'Windows-1252', col_sep: ";")
    csv.select { |row| range.include?(row["data"]) }.map do |row|
      full, rest = row[ROW_MAP[currency]].split(",")
      Rational([full,rest].join.to_i, 10**(rest.size))
    end
  end

  def fetch_year(year)
    log("Fetching CSV for year #{year}")
    write = URI.open(@@url_template.gsub("{YEAR}", year.to_s), &:read)
    File.write("tables/#{year}.csv", write)
  end

  def log(*args)
    #puts *args
  end
end



