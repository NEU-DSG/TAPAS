class RemoveDiscardedAtFromCollections < ActiveRecord::Migration[8.1]
  def change
    remove_column :collections, :discarded_at, :datetime
  end
end
