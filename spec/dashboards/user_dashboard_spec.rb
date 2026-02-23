# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserDashboard do
  let(:expected_attribute_types_keys) do
    %i[id admin_at bio current_sign_in_at current_sign_in_ip email
       encrypted_password image_file institution last_sign_in_at
       last_sign_in_ip name project_members projects remember_created_at
       reset_password_sent_at reset_password_token sign_in_count
       created_at updated_at]
  end

  let(:expected_collection_attributes) do
    %i[email name institution admin_at sign_in_count created_at]
  end

  let(:expected_show_page_attributes) do
    %i[id admin_at bio current_sign_in_at current_sign_in_ip email
       encrypted_password image_file institution last_sign_in_at
       last_sign_in_ip name project_members projects remember_created_at
       reset_password_sent_at reset_password_token sign_in_count
       created_at updated_at]
  end

  let(:expected_form_attributes) do
    %i[email name bio institution admin_at image_file]
  end

  let(:expected_collection_filter_keys) { %i[admin active] }

  it_behaves_like "a dashboard"

  describe "COLLECTION_FILTERS behavior" do
    let!(:admin_user) { create(:user, :admin) }
    let!(:regular_user) { create(:user, admin_at: nil) }
    let!(:active_user) { create(:user, sign_in_count: 5) }
    let!(:inactive_user) { create(:user, sign_in_count: 0) }

    it "admin filter returns only admin users" do
      result = described_class::COLLECTION_FILTERS[:admin].call(User.all)
      expect(result).to include(admin_user)
      expect(result).not_to include(regular_user)
    end

    it "active filter returns users with sign_in_count > 0" do
      result = described_class::COLLECTION_FILTERS[:active].call(User.all)
      expect(result).to include(active_user)
      expect(result).not_to include(inactive_user)
    end
  end

  describe "#display_resource" do
    it "returns the user email" do
      user = build(:user, email: "test@example.com")
      expect(described_class.new.display_resource(user)).to eq("test@example.com")
    end
  end
end
