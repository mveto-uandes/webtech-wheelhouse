# An account has a role and may belong to one member of the staff. Emails are
# stored lowercased by the model; the index compares them lowercased too, so the
# database refuses Ana@Wheelhouse.cl next to ana@wheelhouse.cl however the row
# got there.
class AddRoleAndEmployeeToUsers < ActiveRecord::Migration[8.1]
  def change
    # Mechanic is the role with the fewest permissions (see docs/decisions.md).
    add_column :users, :role, :string, null: false, default: "mechanic"
    add_reference :users, :employee, null: true, foreign_key: true, index: { unique: true }

    remove_index :users, :email_address, unique: true
    add_index :users, "lower(email_address)", unique: true, name: "index_users_on_lower_email_address"
  end
end
