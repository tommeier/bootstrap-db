class CreateTimeData < ActiveRecord::Migration
  def change
    create_table :time_data do |t|
      t.text :subject
      t.time :time_value
      t.timestamp :timestamp_value

      t.timestamps
    end
  end
end
