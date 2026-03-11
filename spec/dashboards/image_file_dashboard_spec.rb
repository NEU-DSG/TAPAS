# frozen_string_literal: true

require "rails_helper"

RSpec.describe ImageFileDashboard do
  let(:expected_attribute_types_keys) do
    %i[id depositor_id description file_format image_url imageable title created_at updated_at]
  end

  let(:expected_collection_attributes) do
    %i[title image_url file_format imageable created_at]
  end

  let(:expected_show_page_attributes) do
    %i[id title description image_url file_format imageable depositor_id created_at updated_at]
  end

  let(:expected_form_attributes) do
    %i[title description image_url file_format depositor_id]
  end

  let(:expected_collection_filter_keys) { [] }

  it_behaves_like "a dashboard"

  describe "ATTRIBUTE_TYPES field mappings" do
    it "maps imageable as Polymorphic" do
      expect(described_class::ATTRIBUTE_TYPES[:imageable]).to eq(Administrate::Field::Polymorphic)
    end
  end

  describe "#display_resource" do
    subject(:dashboard) { described_class.new }

    it "returns the image file title when present" do
      image_file = build(:image_file, title: "My Image")
      expect(dashboard.display_resource(image_file)).to eq("My Image")
    end

    it "returns a fallback string when title is nil" do
      image_file = ImageFile.new(id: 42, title: nil)
      expect(dashboard.display_resource(image_file)).to eq("ImageFile #42")
    end
  end
end
