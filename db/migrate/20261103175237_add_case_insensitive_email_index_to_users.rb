class AddCaseInsensitiveEmailIndexToUsers < ActiveRecord::Migration[8.0]
  # The model downcases every address, but only this index makes the database
  # itself refuse Ana@Wheelhouse.cl when ana@wheelhouse.cl already exists.
  def change
    add_index :users, "lower(email_address)", unique: true, name: "index_users_on_lower_email_address"
  end
end
