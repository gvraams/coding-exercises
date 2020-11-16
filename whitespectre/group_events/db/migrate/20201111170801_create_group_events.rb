class CreateGroupEvents < ActiveRecord::Migration[6.0]
  def change
    create_table :group_events, primary_key: :uuid do |t|
      t.integer   :status, default: 10, null: false
      t.string    :name
      t.string    :description
      t.string    :location_id, null: false
      t.string    :created_by_id, null: false
      t.datetime  :start_date
      t.datetime  :end_date
      t.integer   :duration
      t.datetime  :deleted_at, index: true, default: nil

      t.timestamps
    end

    # Changes the integer primary key to string with 50-character limit
    change_column :group_events, :uuid, :string, limit: 50
  end
end
