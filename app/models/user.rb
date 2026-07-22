class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :trackable

  # Past spam registrations came from real people, so every new account is
  # held for human admin review before it can sign in.
  enum :account_status, { pending_review: 0, active: 1 }

  has_one :image_file, as: :imageable, dependent: :destroy
  accepts_nested_attributes_for :image_file, allow_destroy: true
  has_many :project_members, dependent: :destroy
  has_many :projects, through: :project_members

  before_destroy :notify_and_reassign_contributed_files, prepend: true

  def active_for_authentication?
    super && active?
  end

  def inactive_message
    pending_review? ? :pending_review : super
  end

  def role_in(project)
    project_members.find_by(project: project)&.role
  end

  def sole_owned_projects
    Project
      .joins(:project_members)
      .where(project_members: { user: self, role: "owner" })
      .where(
        Project.joins(:project_members)
               .where(project_members: { role: "owner" })
               .group("projects.id")
               .having("COUNT(project_members.id) = 1")
               .select("projects.id").arel.exists
      )
  end

  # Check if user is an admin based on admin_at timestamp
  def admin?
    admin_at.present?
  end

  private

  def notify_and_reassign_contributed_files
    contributed_project_ids = project_members.where.not(role: "owner").pluck(:project_id)
    return if contributed_project_ids.empty?

    Project.where(id: contributed_project_ids).each do |project|
      files = project.core_files.where(depositor_id: id)
      next if files.empty?

      project_owner = project.owner.first
      next unless project_owner

      AccountDeletionMailer
        .contributor_files_notification(project_owner, files.to_a, name || email)
        .deliver_later
      files.update_all(depositor_id: project_owner.id)
    end
  end
end
