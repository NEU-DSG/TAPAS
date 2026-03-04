class Collection < ApplicationRecord
  include SolrHelpers

  # validations
  validates_presence_of :depositor_id, :project_id, :title
  validate :depositor_is_project_member
  validate :visibility_consistent_with_project

  # associations
  belongs_to :depositor, class_name: "User"
  belongs_to :project
  has_one :image_file, as: :imageable
  has_many :collection_core_files, dependent: :destroy
  has_many :core_files, through: :collection_core_files

  # callbacks
  after_save :index_record
  after_update :update_record

  private

  def depositor_is_project_member
    return unless depositor && project
    unless project.project_members.exists?(user: depositor)
      errors.add(:depositor, "must be a project member to deposit a collection")
    end
  end

  def visibility_consistent_with_project
    return unless project && is_public?
    unless project.is_public?
      errors.add(:is_public, "cannot be public when the project is private")
    end
  end

  public

  def to_solr(solr_doc = {})
    solr_doc["active_record_model_ssi"] = self.class.to_s
    solr_doc["depositor_tesim"] = depositor.id
    solr_doc["table_id_ssi"] = id
    solr_doc["id"] = "#{self.class}_#{id}"
    solr_doc["edit_access_person_ssim"] = project.members["owner"].empty? ? depositor_id : project.owner[0].id
    solr_doc["project_ssim"] = project.id
    solr_doc["title_info_title_ssi"] = title
    solr_doc["access_ssim"] = is_public ? "public" : "private"
    solr_doc["image_file_ssi"] = "public/assets/logo_no_text.png" # this string will be replaced with S3 storage bucket url

    solr_doc
  end
end
