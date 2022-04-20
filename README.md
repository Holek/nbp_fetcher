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
    -s, --salary=15000               Monthly salary in PLN to convert to in desired currency (full amounts only)
    -h, --help                       Prints this help
```

Simple usage:

```
$ ruby ./salaries.rb -cEUR
Salary given: 15000 PLN

Average rate of EUR in last 6 months: 4.6288
Exchange rate known as of today:      4.6295

If you wanted to exchange your contract today:
* You would be given 3240.58 EUR on the contract
* And you would earn 15002.27 PLN with today's exchange rate
```

[Why 15000 PLN?](https://geek.justjoin.it/programista-15k-czyli-wszystko-co-musisz-wiedziec-o-pracy-w-it-w-polsce) [pl]
