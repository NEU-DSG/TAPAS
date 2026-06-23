# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectInvitation, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:creator).class_name("User") }
  end

  describe "validations" do
    it "rejects a duplicate token" do
      existing = create(:project_invitation)
      duplicate = build(:project_invitation, token: existing.token)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:token]).to be_present
    end
  end

  describe "token generation" do
    it "generates a token before create" do
      invitation = create(:project_invitation)
      expect(invitation.token).to be_present
    end

    it "generates a unique token" do
      invitations = create_list(:project_invitation, 3)
      tokens = invitations.map(&:token)
      expect(tokens.uniq.length).to eq(3)
    end

    it "does not overwrite a token that was set manually" do
      invitation = create(:project_invitation)
      expect(invitation.token).to be_present
    end
  end

  describe "expires_at default" do
    it "defaults to 90 days from now" do
      invitation = create(:project_invitation)
      expect(invitation.expires_at).to be_within(1.minute).of(90.days.from_now)
    end

    it "does not override an explicitly set expires_at" do
      custom_time = 30.days.from_now
      invitation = create(:project_invitation, expires_at: custom_time)
      expect(invitation.expires_at).to be_within(1.second).of(custom_time)
    end
  end

  describe "scopes" do
    let!(:active_invitation)  { create(:project_invitation) }
    let!(:expired_invitation) { create(:project_invitation, :expired) }
    let!(:revoked_invitation) { create(:project_invitation, :revoked) }

    describe ".active" do
      it "returns invitations that are not expired and not revoked" do
        expect(ProjectInvitation.active).to include(active_invitation)
        expect(ProjectInvitation.active).not_to include(expired_invitation, revoked_invitation)
      end
    end

    describe ".expired" do
      it "returns invitations past their expiry date that are not revoked" do
        expect(ProjectInvitation.expired).to include(expired_invitation)
        expect(ProjectInvitation.expired).not_to include(active_invitation, revoked_invitation)
      end
    end

    describe ".revoked" do
      it "returns invitations with a revoked_at timestamp" do
        expect(ProjectInvitation.revoked).to include(revoked_invitation)
        expect(ProjectInvitation.revoked).not_to include(active_invitation, expired_invitation)
      end
    end
  end

  describe "#expired?" do
    it "returns false for a current invitation" do
      expect(build(:project_invitation)).not_to be_expired
    end

    it "returns true for an expired invitation" do
      expect(build(:project_invitation, :expired)).to be_expired
    end
  end

  describe "#revoked?" do
    it "returns false when revoked_at is nil" do
      expect(build(:project_invitation)).not_to be_revoked
    end

    it "returns true when revoked_at is set" do
      expect(build(:project_invitation, :revoked)).to be_revoked
    end
  end

  describe "#usable?" do
    it "returns true for an active invitation" do
      expect(create(:project_invitation)).to be_usable
    end

    it "returns false for an expired invitation" do
      expect(build(:project_invitation, :expired)).not_to be_usable
    end

    it "returns false for a revoked invitation" do
      expect(build(:project_invitation, :revoked)).not_to be_usable
    end
  end

  describe "pending member ability lockout" do
    let(:project) { create(:project, is_public: false) }
    let(:user)    { create(:user) }

    before { create(:project_member, project: project, user: user, status: :pending) }

    it "does not grant read access to the project" do
      ability = Ability.new(user)
      expect(ability).not_to be_able_to(:read, project)
    end

    it "does not grant update access to the project" do
      ability = Ability.new(user)
      expect(ability).not_to be_able_to(:update, project)
    end
  end
end
