require 'csv'

namespace :acb do
  desc "Reformat kraken ledgers export for acb calculation"
  task :reformat_kraken_ledger, [:file_path] => :environment do |t, args|
    trades = []
    FIAT_CURRENY_CODES = ["CAD, USD"]
    CSV.foreach(args[:file_path], headers: true) do |row|
      row = HashWithIndifferentAccess.new(row)

      if row[:type] == "trade"
        trades << row
      end
    end

    trades.each_slice(2) do |buy_sell_pair|
      next unless buy_sell_pair.length == 2
      asset_1_hash = HashWithIndifferentAccess.new(buy_sell_pair[0])
      asset_2_hash = HashWithIndifferentAccess.new(buy_sell_pair[1])

      # Assumption: Asset with negative amount is the sold asset
      if asset_1_hash[:amount].to_i.negative?
        sold_asset_hash = asset_1_hash
        bought_asset_hash = asset_2_hash
      else
        sold_asset_hash = asset_2_hash
        bought_asset_hash = asset_1_hash
      end

      # Strip first char from asset code (starts with X or Z for some reason)
      bought_asset = bought_asset_hash[:asset].slice!(1..-1)
      sold_asset = sold_asset_hash[:asset].slice!(1..-1)

      if FIAT_CURRENY_CODES.include?(sold_asset)
        p "At #{Time.parse(sold_asset_hash[:time])}:"
        p "Bought #{bought_asset_hash[:amount]} #{bought_asset} with #{sold_asset_hash[:amount]} #{sold_asset}"
      else
        unix_time_stamp = Time.parse(sold_asset_hash[:time]).utc.to_i

        response = HTTParty.get("https://min-api.cryptocompare.com/data/pricehistorical?fsym=#{sold_asset}&tsyms=BTC,CAD,USD&ts=#{unix_time_stamp}")

        value_per_unit_in_cad = response.parsed_response[sold_asset]["CAD"]

        p "At #{Time.parse(sold_asset_hash[:time])}:"
        p "Bought #{bought_asset_hash[:amount]} #{bought_asset} with #{sold_asset_hash[:amount]} #{sold_asset} (#{value_per_unit_in_cad}CAD/#{sold_asset})"
      end

      # Organize all buy orders and sell orders for a certain asset

    end
  end
end
