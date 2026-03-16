class AddAltTextToImageFiles < ActiveRecord::Migration[8.1]
  def change
    add_column :image_files, :alt_text, :text
  end
end
