class AddForeignKeysToTables < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :bikes, :customers

    add_foreign_key :repairs, :bikes
    add_foreign_key :repairs, :employees, column: :mechanic_id

    add_foreign_key :repair_line_items, :repairs
    add_foreign_key :repair_line_items, :services

    add_foreign_key :payments, :repairs
  end
end
