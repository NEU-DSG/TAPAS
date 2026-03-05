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
  has_many :project_members
  has_many :projects, through: :project_members

  def role
    ProjectMember.find_by_user_id(id).role ||= "reader"
  end

  # Check if user is an admin based on admin_at timestamp
  def admin?
    admin_at.present?
  end
end
