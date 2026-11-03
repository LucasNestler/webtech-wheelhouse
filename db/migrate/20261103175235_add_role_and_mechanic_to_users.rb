class AddRoleAndMechanicToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :role, :string, null: false, default: "mechanic"
    add_reference :users, :mechanic, null: true, foreign_key: true, index: { unique: true }
  end
end
