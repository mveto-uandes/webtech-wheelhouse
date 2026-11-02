# The account that took the repair in. Repairs from before accounts existed
# have nobody here.
class AddTakenInByToRepairs < ActiveRecord::Migration[8.1]
  def change
    add_reference :repairs, :taken_in_by, null: true, foreign_key: { to_table: :users }
  end
end
