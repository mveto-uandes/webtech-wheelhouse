class CreateRepairs < ActiveRecord::Migration[8.1]
  def change
    create_table :repairs do |t|
      t.integer :bike_id, null: false
      t.integer :mechanic_id
      t.string :status, null: false, default: "received"
      t.text :reported_problem, null: false
      t.text :diagnosis
      t.date :promised_on
      t.datetime :handed_back_at

      t.timestamps
    end
    add_index :repairs, :bike_id
    add_index :repairs, :mechanic_id
  end
end
