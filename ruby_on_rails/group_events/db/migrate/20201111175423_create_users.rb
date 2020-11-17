class CreateUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :users, primary_key: :uuid do |t|
      t.string  :name, null: false
      t.string  :email, null: false
      t.string  :password, null: false

      t.timestamps
    end

    # Changes the integer primary key to string with 50-character limit
    change_column :users, :uuid, :string, limit: 50
  end
end
