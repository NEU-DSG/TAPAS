class Project < ApplicationRecord
  include SolrHelpers

  # validations
  validates_presence_of :depositor_id, :title

  # associations
  belongs_to :depositor, class_name: "User"
  has_one :image_file, as: :imageable, dependent: :destroy
  has_many :collections
  has_many :core_files, through: :collections
  has_many :project_members
  has_many :users, through: :project_members

  # callbacks
  after_save :index_record
  after_update :update_record

  def project_group
    ProjectMember
      .all
      .where(project_id: id)
      .group_by(&:role)
  end

  def members
    user_members = {}

    project_group.each do |k, v|
      user_members[k] = v.map!(&:user)
    end

    user_members
  end

  def contributors
    members['contributor']
  end

  def owner
    members['owner']
  end

  def to_solr(solr_doc = {})
    solr_doc["active_record_model_ssi"] = self.class.to_s
    solr_doc['depositor_tesim'] = depositor_id
    solr_doc['table_id_ssi'] = id
    solr_doc['id'] = "#{self.class.to_s}_#{id}"
    solr_doc['edit_access_person_ssim'] = project_members.empty? ? depositor_id : owner.first.id
    solr_doc['title_info_title_ssi'] = title
    solr_doc['access_ssim'] = is_public ? "public" : "private"
    solr_doc['image_file_ssi'] = 'public/assets/logo_no_text.png'

    solr_doc
  end

  public

  def publicly_visible
    where(is_public: true)
  end
end
