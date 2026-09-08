class CreateRepairLineItems < ActiveRecord::Migration[8.0]
  def change
    create_table :repair_line_items do |t|
      t.integer :repair_order_id, null: false
      t.integer :service_id, null: false
      t.decimal :charged_price, null: false, precision: 8, scale: 2

      t.timestamps
    end
  end
end
