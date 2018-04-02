require 'csv'

namespace :kraken_ledger do
  desc "Add crypto asset value in CAD at point of sale"
  task :add_crypto_value_in_cad, [:file_path] => :environment do |t, args|
    trades = []
    FIAT_CURRENCY_CODES = ["CAD, USD"]
    CSV.foreach(args[:file_path], headers: true) do |row|
      row = HashWithIndifferentAccess.new(row)

      if row[:type] == "trade"
        trades << row
      end
    end

    trades.map! do |trade|
      asset = trade[:asset].slice(1..-1)
      if ["CAD", "USD"].include?(asset)
        trade
      else
        unix_time_stamp = Time.parse(trade[:time]).utc.to_i
        response = HTTParty.get("https://min-api.cryptocompare.com/data/pricehistorical?fsym=#{asset}&tsyms=BTC,CAD,USD&ts=#{unix_time_stamp}")
        trade.merge(cad_per_unit: response.parsed_response[asset]["CAD"])
      end
    end
  end

  desc "Organize buy and sell trades by asset"
  task :organize_buy_and_sell_by_asset, [:file_path] => :environment do |t, args|
    trades = []
    FIAT_CURRENCY_CODES = ["CAD, USD"]
    CSV.foreach(args[:file_path], headers: true) do |row|
      row = HashWithIndifferentAccess.new(row)

      if row[:type] == "trade"
        trades << row
      end
    end

    # Organize all buy and sell trades by asset
    asset_codes = trades.map{ |trade| trade[:asset] }.uniq
    buy_and_sell_trades_by_asset_code = HashWithIndifferentAccess.new()

    asset_codes.each do |asset_code|
      buy_and_sell_trades_by_asset_code.merge!({ "#{asset_code}":{ buy: [], sell: [] } })
      trades.each_slice(2) do |buy_sell_pair|
        next unless buy_sell_pair.length == 2

        asset_1_hash = HashWithIndifferentAccess.new(buy_sell_pair[0])
        asset_2_hash = HashWithIndifferentAccess.new(buy_sell_pair[1])

        if (asset_1_hash[:asset] == asset_code) && asset_1_hash[:amount].to_i.negative?
          buy_and_sell_trades_by_asset_code["#{asset_code}"]["sell"] << buy_sell_pair
        elsif (asset_1_hash[:asset] == asset_code) && asset_1_hash[:amount].to_i.positive?
          buy_and_sell_trades_by_asset_code["#{asset_code}"]["buy"] << buy_sell_pair
        elsif (asset_2_hash[:asset] == asset_code) && asset_2_hash[:amount].to_i.negative?
          buy_and_sell_trades_by_asset_code["#{asset_code}"]["sell"] << buy_sell_pair
        elsif (asset_2_hash[:asset] == asset_code) && asset_2_hash[:amount].to_i.positive?
          buy_and_sell_trades_by_asset_code["#{asset_code}"]["buy"] << buy_sell_pair
        end
      end
    end
    p buy_and_sell_trades_by_asset_code
  end
end

# bundle exec rake cointracking:import_to_db["/Users/matthew/projects/calculate_acb/lib/assets/cointracking_trades_export.csv"]
namespace :cointracking do
  desc "Parse Overview and Manual Import and enter into DB"
  task :import_to_db, [:file_path] => :environment do |t, args|
    trades = []
    CSV.foreach(args[:file_path], headers: true) do |row|
      row = HashWithIndifferentAccess.new(row)

      if row["type"] == "Trade"
        trades << row
      end
    end

    trades.each_with_index.map do |trade, i|
      trade.slice!(:group, :comment)
      puts `clear`
      sell_asset = trade["sell_asset"]
      if ["CAD"].include?(sell_asset)
        print "#{i+1}"
        Trade.create(trade)
      else
        print "#{i+1}"
        unix_time_stamp = Time.parse(trade[:date]).utc.to_i
        response = HTTParty.get("https://min-api.cryptocompare.com/data/pricehistorical?fsym=#{sell_asset}&tsyms=BTC,CAD,USD&ts=#{unix_time_stamp}")
        trade.merge!(
            sold_asset_value_cad: response.parsed_response[sell_asset]["CAD"].to_f
        )

        Trade.create(trade)
      end
    end
    pp Trade.all
  end
end
