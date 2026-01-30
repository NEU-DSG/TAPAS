# frozen_string_literal: true

class AddTapasXqFieldsToCoreFiles < ActiveRecord::Migration[8.1]
  def change
    add_column :core_files, :mods_xml, :mediumtext
    add_column :core_files, :tfe_xml, :text
    add_column :core_files, :processing_status, :string, default: 'pending'
    add_column :core_files, :processing_error, :text
    add_column :core_files, :tapas_xq_project_id, :string
    add_column :core_files, :tapas_xq_doc_id, :string

    add_index :core_files, :processing_status
    add_index :core_files, [ :tapas_xq_project_id, :tapas_xq_doc_id ],
              unique: true,
              name: 'index_core_files_on_tapas_xq_ids'
  end
end
