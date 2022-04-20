#!/usr/bin/env bash

currencies=$(ruby -r'./salaries' -e'puts NbpFetcher.run.to_json')

if command -v jq &> /dev/null
then
  echo "$currencies" | jq
else
  echo "$currencies"
fi
