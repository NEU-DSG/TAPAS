# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectDashboard do
  let(:expected_attribute_types_keys) do
    %i[id collections core_files depositor description image_file
       institution is_public project_members title users created_at updated_at]
  end

  let(:expected_collection_attributes) do
    %i[title depositor institution is_public created_at]
  end

  let(:expected_show_page_attributes) do
    %i[id collections core_files depositor description image_file
       institution is_public project_members title users created_at updated_at]
  end

  let(:expected_form_attributes) do
    %i[collections core_files depositor description image_file
       institution is_public project_members title users]
  end

  let(:expected_collection_filter_keys) { %i[public private recent] }

  it_behaves_like "a dashboard"

  describe "ATTRIBUTE_TYPES field mappings" do
    it "maps depositor as BelongsTo" do
      expect(described_class::ATTRIBUTE_TYPES[:depositor]).to eq(Administrate::Field::BelongsTo)
    end

    it "maps collections as HasMany" do
      expect(described_class::ATTRIBUTE_TYPES[:collections]).to eq(Administrate::Field::HasMany)
    end

    it "maps is_public as Boolean" do
      expect(described_class::ATTRIBUTE_TYPES[:is_public]).to eq(Administrate::Field::Boolean)
    end
  end

  describe "COLLECTION_FILTERS behavior" do
    let(:depositor) { create(:user) }
    let!(:public_project) { create(:project, depositor: depositor, is_public: true) }
    let!(:private_project) { create(:project, depositor: depositor, is_public: false) }
    let!(:recent_project) { create(:project, depositor: depositor, created_at: 5.days.ago) }
    let!(:old_project) { create(:project, depositor: depositor, created_at: 60.days.ago) }

    it "public filter returns only public projects" do
      result = described_class::COLLECTION_FILTERS[:public].call(Project.all)
      expect(result).to include(public_project)
      expect(result).not_to include(private_project)
    end

    it "private filter returns only private projects" do
      result = described_class::COLLECTION_FILTERS[:private].call(Project.all)
      expect(result).to include(private_project)
      expect(result).not_to include(public_project)
    end

    it "recent filter returns projects created within 30 days" do
      result = described_class::COLLECTION_FILTERS[:recent].call(Project.all)
      expect(result).to include(recent_project)
      expect(result).not_to include(old_project)
    end
  end

  describe "#display_resource" do
    it "returns the project title" do
      project = build(:project, title: "My Project")
      expect(described_class.new.display_resource(project)).to eq("My Project")
    end
  end
end
