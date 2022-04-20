# NBP Fetcher

This small script fetches Bank of Poland's exchange rates for last 6 months and averages them out.

By default, it supports EUR and USD checks against PLN.

## Usage

By default the script spits out Euro data.

You can run it simply with:

```shell
$ ./run.sh
{
  "currency": "EUR",
  "average": 4.1133,
  "last": 4.2887,
  "favorable": false
}
```

All that little script is doing is wrapping this call:

```shell
$ ruby -r./salaries -e"puts NbpFetcher.run.to_json"
```

To apply EUR or USD specifically, use:

```
ruby -r./salaries -e"puts NbpFetcher.run('USD').to_json"
```

Just change USD to EUR.