class CreateImageFiles < ActiveRecord::Migration[8.1]
  def change
    create_table :image_files do |t|
      t.string "title", null: false
      t.integer "depositor_id", null: false
      t.text "description"
      t.string "file_format"
      t.string "imageable_type", null: false
      t.bigint "imageable_id", null: false
      t.string "image_url", null: false
      t.timestamps

      t.index ["imageable_type", "imageable_id"], name: "index_image_files_on_imageable_type_and_imageable_id"
    end
  end
end
