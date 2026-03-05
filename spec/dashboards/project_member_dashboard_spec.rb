# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectMemberDashboard do
  let(:expected_attribute_types_keys) do
    %i[id is_project_depositor project role user created_at updated_at]
  end

  let(:expected_collection_attributes) do
    %i[id is_project_depositor project role]
  end

  let(:expected_show_page_attributes) do
    %i[id is_project_depositor project role user created_at updated_at]
  end

  let(:expected_form_attributes) do
    %i[is_project_depositor project role user]
  end

  let(:expected_collection_filter_keys) { [] }

  it_behaves_like "a dashboard"
end
