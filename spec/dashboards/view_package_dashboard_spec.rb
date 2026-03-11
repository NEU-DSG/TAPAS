# frozen_string_literal: true

require "rails_helper"

RSpec.describe ViewPackageDashboard do
  let(:expected_attribute_types_keys) do
    %i[id css_files description dir_name file_type git_branch git_timestamp
       human_name js_files machine_name parameters run_process created_at updated_at]
  end

  let(:expected_collection_attributes) do
    %i[id css_files description dir_name]
  end

  let(:expected_show_page_attributes) do
    %i[id css_files description dir_name file_type git_branch git_timestamp
       human_name js_files machine_name parameters run_process created_at updated_at]
  end

  let(:expected_form_attributes) do
    %i[css_files description dir_name file_type git_branch git_timestamp
       human_name js_files machine_name parameters run_process]
  end

  let(:expected_collection_filter_keys) { [] }

  it_behaves_like "a dashboard"
end
