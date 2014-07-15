class CreateDateData < ActiveRecord::Migration
  def change
    create_table :date_data do |t|
      t.text :subject
      t.date :date_value
      t.datetime :datetime_value

      t.timestamps
    end
  end
end
