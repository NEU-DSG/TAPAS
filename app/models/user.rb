class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :trackable

  has_one :image_file, as: :imageable, dependent: :destroy
  accepts_nested_attributes_for :image_file, allow_destroy: true
  has_many :project_members, dependent: :destroy
  has_many :projects, through: :project_members

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
end
