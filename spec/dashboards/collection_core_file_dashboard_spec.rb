# frozen_string_literal: true

require "rails_helper"

RSpec.describe CollectionCoreFileDashboard do
  let(:expected_attribute_types_keys) do
    %i[id collection core_file created_at updated_at]
  end

  let(:expected_collection_attributes) do
    %i[id collection core_file created_at]
  end

  let(:expected_show_page_attributes) do
    %i[id collection core_file created_at updated_at]
  end

  let(:expected_form_attributes) do
    %i[collection core_file]
  end

  let(:expected_collection_filter_keys) { [] }

  it_behaves_like "a dashboard"
end
