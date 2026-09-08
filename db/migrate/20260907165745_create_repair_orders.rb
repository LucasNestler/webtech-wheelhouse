class CreateRepairOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :repair_orders do |t|
      t.integer :bike_id, null: false
      t.integer :mechanic_id
      t.string :status, null: false, default: "Dropped Off"
      t.date :promised_on, null: false
      t.datetime :quoted_at
      t.boolean :quote_accepted
      t.datetime :completed_at
      t.datetime :picked_up_at

      t.timestamps
    end
  end
end
