# frozen_string_literal: true

require "rails_helper"

RSpec.describe CollectionDashboard do
  let(:expected_attribute_types_keys) do
    %i[id collection_core_files core_files depositor description
       image_file is_public project title created_at updated_at]
  end

  let(:expected_collection_attributes) do
    %i[title project depositor is_public created_at]
  end

  let(:expected_show_page_attributes) do
    %i[id collection_core_files core_files depositor description
       image_file is_public project title created_at updated_at]
  end

  let(:expected_form_attributes) do
    %i[collection_core_files core_files depositor description
       image_file is_public project title]
  end

  let(:expected_collection_filter_keys) { %i[public private] }

  it_behaves_like "a dashboard"

  describe "COLLECTION_FILTERS behavior" do
    let(:depositor) { create(:user) }
    let(:project) { create(:project, depositor: depositor) }
    let!(:public_collection) do
      create(:collection, project: project, depositor: depositor, is_public: true)
    end
    let!(:private_collection) do
      create(:collection, project: project, depositor: depositor, is_public: false)
    end

    it "public filter returns only public collections" do
      result = described_class::COLLECTION_FILTERS[:public].call(Collection.all)
      expect(result).to include(public_collection)
      expect(result).not_to include(private_collection)
    end

    it "private filter returns only private collections" do
      result = described_class::COLLECTION_FILTERS[:private].call(Collection.all)
      expect(result).to include(private_collection)
      expect(result).not_to include(public_collection)
    end
  end

  describe "#display_resource" do
    it "returns the collection title" do
      collection = build(:collection, title: "My Collection")
      expect(described_class.new.display_resource(collection)).to eq("My Collection")
    end
  end
end
