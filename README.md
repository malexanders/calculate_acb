# README

## Setup DB and Install Dependencies
1. Install postgres
2. bundle install
3. bundle exec rake db:create db:migrate

## Import Cointracking Trades
1. Change headings is cointracking export to:
```
"type","buy_volume","buy_asset","sell_volume","sell_asset","fee_volume","fee_asset","exchange","group","comment","date"
```
2. bundle exec rake cointracking:import_to_db[`path_to_cointracking_export`]

