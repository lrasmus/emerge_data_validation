class CreateSubmissions < ActiveRecord::Migration
  def change
    create_table :submissions do |t|
      t.string :data_dictionary
      t.string :data_file
      t.string :content_type
      t.string :organization

      t.timestamps
    end
  end
end
