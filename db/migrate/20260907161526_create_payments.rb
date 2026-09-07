class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.integer :repair_id, null: false
      t.decimal :amount, precision: 8, scale: 2, null: false
      t.string :method, null: false
      t.datetime :paid_at, null: false

      t.timestamps
    end
    add_index :payments, :repair_id
  end
end
