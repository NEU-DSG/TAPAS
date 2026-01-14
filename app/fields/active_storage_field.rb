# frozen_string_literal: true

require "administrate/field/base"

# Custom Administrate field for ActiveStorage attachments
# Provides display and upload capabilities for attached files
class ActiveStorageField < Administrate::Field::Base
  def to_s
    data.filename.to_s if data.attached?
  end

  def attached?
    data.attached?
  end

  def url
    Rails.application.routes.url_helpers.rails_blob_path(data, disposition: "attachment") if attached?
  end

  def filename
    data.filename.to_s if attached?
  end

  def byte_size
    data.byte_size if attached?
  end

  def content_type
    data.content_type if attached?
  end
end
