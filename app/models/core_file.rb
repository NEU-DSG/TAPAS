class CoreFile < ApplicationRecord
  include SolrHelpers

  PROCESSING_STATUSES = %w[pending processing completed failed].freeze

  # validations
  validates :title, :depositor_id, presence: true
  validates :collections, presence: true, if: -> { persisted? }
  validates :processing_status, inclusion: { in: PROCESSING_STATUSES }, allow_nil: true
  validate :collections_same_project, if: -> { collections.any? }

  # associations
  belongs_to :depositor, class_name: "User"
  has_one_attached :tei_file
  has_one :image_file, as: :imageable, dependent: :destroy
  has_many :collection_core_files, dependent: :destroy
  has_many :collections, through: :collection_core_files

  # Scopes
  scope :processing_pending, -> { where(processing_status: "pending") }
  scope :processing_failed, -> { where(processing_status: "failed") }
  scope :processing_completed, -> { where(processing_status: "completed") }

  # callbacks
  after_save :index_core_file
  after_update :update_indexed_core_file
  after_create :enqueue_tapas_xq_processing

  def project
    collections[0]&.project
  end

  def processing_pending?
    processing_status == "pending"
  end

  def processing_failed?
    processing_status == "failed"
  end

  def processing_completed?
    processing_status == "completed"
  end

  def retry_processing!
    return false unless processing_failed?

    update!(
      processing_status: "pending",
      processing_error: nil
    )
    ProcessTeiFileJob.perform_later(id)
    true
  end

  def self.all_ography_types
    %w[personography orgography bibliography otherography odd_file placeography]
  end

  def to_solr(solr_doc = {})
    solr_doc["active_record_model_ssi"] = self.class.to_s
    solr_doc["depositor_tesim"] = depositor.id
    solr_doc["table_id_ssi"] = id
    solr_doc["id"] = "#{self.class}_#{id}"
    solr_doc["edit_access_person_ssim"] = project.members["owner"].empty? ? depositor_id : project.owner[0].id
    solr_doc["collections_ssim"] = collections.map(&:id)
    solr_doc["project_ssim"] = project.id
    solr_doc["title_info_title_ssi"] = title
    solr_doc["creator_tesim"] = tei_authors
    solr_doc["all_text_timv"] => nil # TODO: 'timv' is a datetime object datafield type in Solr, so it's unclear what this was intended to capture
    solr_doc["type_ssim"] = self.is_ography? ? self.ography_type : "TEI Record"
    solr_doc["access_ssim"] = is_public ? "public" : "private"
    solr_doc["image_file_ssi"] = "public/assets/logo_no_text.png" # this string will be replaced with S3 storage bucket url
    solr_doc["is_ography_for_ssim"] = is_ography_for

    solr_doc
  end

  def is_ography?
    ography_type.present?
  end

  def is_ography_for
    is_ography? ? collection_ids : []
  end

  private

  def index_core_file
    index_record(self)
  end

  def update_indexed_core_file
    update_record(self)
  end

  def enqueue_tapas_xq_processing
    ProcessTeiFileJob.perform_later(id) if tei_file.attached?
  end

  def collections_same_project
    project_ids = collections.map(&:project_id).uniq
    if project_ids.size > 1
      errors.add(:collections, "must all belong to the same project")
    end
  end
end
