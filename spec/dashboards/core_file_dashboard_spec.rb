# frozen_string_literal: true

require "rails_helper"

RSpec.describe CoreFileDashboard do
  let(:expected_attribute_types_keys) do
    %i[id collection_core_files collections depositor description image_file
       is_public ography_type tei_authors tei_contributors title created_at updated_at]
  end

  let(:expected_collection_attributes) do
    %i[title depositor ography_type is_public created_at]
  end

  let(:expected_show_page_attributes) do
    %i[id title description depositor collections ography_type
       tei_authors tei_contributors is_public image_file created_at updated_at]
  end

  let(:expected_form_attributes) do
    %i[title description depositor collections ography_type is_public]
  end

  let(:expected_collection_filter_keys) do
    %i[public private ography processing_failed processing_pending]
  end

  it_behaves_like "a dashboard"

  describe "COLLECTION_FILTERS behavior" do
    let(:depositor) { create(:user) }
    let(:project) { create(:project, depositor: depositor) }
    let(:collection) { create(:collection, project: project, depositor: depositor) }

    let!(:public_file) do
      create(:core_file, depositor: depositor, is_public: true).tap do |cf|
        cf.collections = [ collection ]
      end
    end

    let!(:private_file) do
      create(:core_file, depositor: depositor, is_public: false).tap do |cf|
        cf.collections = [ collection ]
      end
    end

    let!(:ography_file) do
      create(:core_file, depositor: depositor, ography_type: "personography").tap do |cf|
        cf.collections = [ collection ]
      end
    end

    let!(:failed_file) do
      create(:core_file, depositor: depositor, processing_status: "failed").tap do |cf|
        cf.collections = [ collection ]
      end
    end

    let!(:pending_file) do
      create(:core_file, depositor: depositor, processing_status: "pending").tap do |cf|
        cf.collections = [ collection ]
      end
    end

    it "public filter returns only public core files" do
      result = described_class::COLLECTION_FILTERS[:public].call(CoreFile.all)
      expect(result).to include(public_file)
      expect(result).not_to include(private_file)
    end

    it "private filter returns only private core files" do
      result = described_class::COLLECTION_FILTERS[:private].call(CoreFile.all)
      expect(result).to include(private_file)
      expect(result).not_to include(public_file)
    end

    it "ography filter returns files with ography_type set" do
      result = described_class::COLLECTION_FILTERS[:ography].call(CoreFile.all)
      expect(result).to include(ography_file)
    end

    it "processing_failed filter returns files with failed status" do
      result = described_class::COLLECTION_FILTERS[:processing_failed].call(CoreFile.all)
      expect(result).to include(failed_file)
      expect(result).not_to include(pending_file)
    end

    it "processing_pending filter returns files with pending status" do
      result = described_class::COLLECTION_FILTERS[:processing_pending].call(CoreFile.all)
      expect(result).to include(pending_file)
      expect(result).not_to include(failed_file)
    end
  end

  describe "#display_resource" do
    it "returns the core file title" do
      core_file = build(:core_file, title: "My TEI File")
      expect(described_class.new.display_resource(core_file)).to eq("My TEI File")
    end
  end
end
