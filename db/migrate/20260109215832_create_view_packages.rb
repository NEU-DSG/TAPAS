class CreateViewPackages < ActiveRecord::Migration[8.1]
  def change
    create_table :view_packages do |t|
      t.string "human_name"
      t.string "machine_name"
      t.text "description"
      t.text "file_type"
      t.text "css_files"
      t.text "js_files"
      t.text "parameters"
      t.text "run_process"
      t.string "dir_name"
      t.datetime "git_timestamp"
      t.string "git_branch"
      t.timestamps
    end
  end
end
