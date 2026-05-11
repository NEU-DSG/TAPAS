class AddDefaultIsPublicToCollections < ActiveRecord::Migration[8.1]
  def change
    change_column_default :collections, :is_public, from: nil, to: true
  end
end
