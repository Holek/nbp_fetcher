# NBP Fetcher

This small script fetches Bank of Poland's exchange rates for last 6 months and averages them out.

By default, it supports EUR and USD checks against PLN.

## Compatibility

This script is compatible with all Ruby versions 2.5 and newer. Basically, you can just run it as is.

## Usage

By default the script prints out this help prompt

```shell
$ ./salaries.rb
Usage: salaries.rb [options]
    -c, --currency=USD|EUR           Currency to track, currently USD or EUR are available
    -a, --all                        Show all supported currencies
    -f, --format=markdown|line|text  Output format (line format only supported in single currencies)
    -s, --salary=20000               Monthly salary in PLN to convert to in desired currency (full amounts only)
    -v, --average[=OPTIONAL]         Currency rate to use to calculate difference from as a float (by default, average of last 6 months)
    -h, --help                       Prints this help
```

Simple usage:

```
$ ruby ./salaries.rb -cEUR
# Salary conversion to EUR

* Given salary: 15000 PLN
* Average rate of EUR in last 6 months: *4.6308*
* Exchange rate known as of today: *4.5876*

If you wanted to exchagne your contract today:

* You would be given 3239.18 EUR on the contract
* And you would earn 14860.06 PLN with today's exchange rate
```

[Why 15000 PLN?](https://geek.justjoin.it/programista-15k-czyli-wszystko-co-musisz-wiedziec-o-pracy-w-it-w-polsce) [pl]
