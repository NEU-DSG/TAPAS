class RemoveDiscardedAtFromCoreFiles < ActiveRecord::Migration[8.1]
  def change
    remove_column :core_files, :discarded_at, :datetime
  end
end
