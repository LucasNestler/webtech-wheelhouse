class AddTakenInByToRepairOrders < ActiveRecord::Migration[8.0]
  # NULL for the repairs that existed before this column.
  def change
    add_reference :repair_orders, :taken_in_by, null: true, foreign_key: { to_table: :users }
  end
end
