class CreateTrades < ActiveRecord::Migration[5.1]
  def change
    create_table :trades do |t|
      t.string     :type
      t.string     :buy_asset
      t.decimal    :buy_volume
      t.string     :sell_asset
      t.decimal    :sell_volume
      t.string     :fee_asset
      t.decimal    :fee_volume
      t.string     :exchange
      t.datetime   :date
      t.decimal    :sold_asset_value_cad
      t.timestamps
    end
  end
end
