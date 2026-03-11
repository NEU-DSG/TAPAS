# frozen_string_literal: true

RSpec.shared_examples "a dashboard" do
  describe "ATTRIBUTE_TYPES" do
    it "is a frozen hash" do
      expect(described_class::ATTRIBUTE_TYPES).to be_a(Hash)
      expect(described_class::ATTRIBUTE_TYPES).to be_frozen
    end

    it "contains the expected keys" do
      expect(described_class::ATTRIBUTE_TYPES.keys).to match_array(expected_attribute_types_keys)
    end
  end

  describe "COLLECTION_ATTRIBUTES" do
    it "is a frozen array of symbols" do
      expect(described_class::COLLECTION_ATTRIBUTES).to be_an(Array)
      expect(described_class::COLLECTION_ATTRIBUTES).to be_frozen
      expect(described_class::COLLECTION_ATTRIBUTES).to all(be_a(Symbol))
    end

    it "contains the expected attributes in order" do
      expect(described_class::COLLECTION_ATTRIBUTES).to eq(expected_collection_attributes)
    end

    it "is a subset of ATTRIBUTE_TYPES keys" do
      expect(described_class::COLLECTION_ATTRIBUTES - described_class::ATTRIBUTE_TYPES.keys).to be_empty
    end
  end

  describe "SHOW_PAGE_ATTRIBUTES" do
    it "is a frozen array of symbols" do
      expect(described_class::SHOW_PAGE_ATTRIBUTES).to be_an(Array)
      expect(described_class::SHOW_PAGE_ATTRIBUTES).to be_frozen
      expect(described_class::SHOW_PAGE_ATTRIBUTES).to all(be_a(Symbol))
    end

    it "contains the expected attributes in order" do
      expect(described_class::SHOW_PAGE_ATTRIBUTES).to eq(expected_show_page_attributes)
    end

    it "is a subset of ATTRIBUTE_TYPES keys" do
      expect(described_class::SHOW_PAGE_ATTRIBUTES - described_class::ATTRIBUTE_TYPES.keys).to be_empty
    end
  end

  describe "FORM_ATTRIBUTES" do
    it "is a frozen array of symbols" do
      expect(described_class::FORM_ATTRIBUTES).to be_an(Array)
      expect(described_class::FORM_ATTRIBUTES).to be_frozen
      expect(described_class::FORM_ATTRIBUTES).to all(be_a(Symbol))
    end

    it "contains the expected attributes in order" do
      expect(described_class::FORM_ATTRIBUTES).to eq(expected_form_attributes)
    end

    it "is a subset of ATTRIBUTE_TYPES keys" do
      expect(described_class::FORM_ATTRIBUTES - described_class::ATTRIBUTE_TYPES.keys).to be_empty
    end

    it "excludes id and timestamp fields" do
      expect(described_class::FORM_ATTRIBUTES).not_to include(:id)
      expect(described_class::FORM_ATTRIBUTES).not_to include(:created_at)
      expect(described_class::FORM_ATTRIBUTES).not_to include(:updated_at)
    end
  end

  describe "COLLECTION_FILTERS" do
    it "is a frozen hash" do
      expect(described_class::COLLECTION_FILTERS).to be_a(Hash)
      expect(described_class::COLLECTION_FILTERS).to be_frozen
    end

    it "contains the expected filter keys" do
      expect(described_class::COLLECTION_FILTERS.keys).to match_array(expected_collection_filter_keys)
    end

    it "maps each filter to a callable" do
      described_class::COLLECTION_FILTERS.each_value do |filter|
        expect(filter).to respond_to(:call)
      end
    end
  end
end
