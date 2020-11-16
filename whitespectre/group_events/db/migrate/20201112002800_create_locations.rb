class CreateLocations < ActiveRecord::Migration[6.0]
  def change
    create_table :locations, primary_key: :uuid do |t|
      t.string :name, null: false

      t.timestamps
    end

    # Changes the integer primary key to string with 50-character limit
    change_column :locations, :uuid, :string, limit: 50
  end
end
