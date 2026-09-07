class CreateRepairLineItems < ActiveRecord::Migration[8.1]
  def change
    create_table :repair_line_items do |t|
      t.integer :repair_id, null: false
      t.integer :service_id, null: false
      t.decimal :charged_price, precision: 8, scale: 2, null: false

      t.timestamps
    end
    add_index :repair_line_items, :repair_id
    add_index :repair_line_items, :service_id
  end
end
