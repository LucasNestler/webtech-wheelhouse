class AddForeignKeysToTables < ActiveRecord::Migration[8.0]
  def change
    add_index :bikes, :customer_id
    add_foreign_key :bikes, :customers

    add_index :repair_orders, :bike_id
    add_foreign_key :repair_orders, :bikes

    add_index :repair_orders, :mechanic_id
    add_foreign_key :repair_orders, :mechanics

    add_index :repair_line_items, :repair_order_id
    add_foreign_key :repair_line_items, :repair_orders

    add_index :repair_line_items, :service_id
    add_foreign_key :repair_line_items, :services
  end
end
