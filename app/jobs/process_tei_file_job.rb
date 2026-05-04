# frozen_string_literal: true

# Background job to process TEI files via TAPAS-XQ
# Uploads TEI to TAPAS-XQ, stores MODS/TFE metadata, and updates processing status
class ProcessTeiFileJob < ApplicationJob
  queue_as :default

  # Retry transient errors with backoff
  retry_on TapasXq::TimeoutError, wait: 5.seconds, attempts: 3
  retry_on TapasXq::ConnectionError, wait: 10.seconds, attempts: 3

  # Discard permanent errors and mark as failed
  discard_on TapasXq::AuthenticationError do |job, error|
    core_file = CoreFile.find(job.arguments.first)
    core_file.update!(
      processing_status: "failed",
      processing_error: "Authentication failed: #{error.message}"
    )
  end

  discard_on ActiveRecord::RecordNotFound do |job, error|
    Rails.logger.error("CoreFile not found: #{job.arguments.first}")
  end

  def perform(core_file_id)
    core_file = CoreFile.find(core_file_id)

    # Skip if TAPAS-XQ disabled (development without TAPAS-XQ)
    if TapasXq.configuration.disabled?
      Rails.logger.info("TAPAS-XQ disabled, skipping processing for CoreFile #{core_file_id}")
      core_file.update!(processing_status: "completed")
      return
    end

    # Skip if already processing or completed
    return if [ "processing", "completed" ].include?(core_file.processing_status)

    core_file.update!(processing_status: "processing")

    storage_service = TapasXq::StorageService.new(core_file)
    result = storage_service.store

    core_file.update!(
      mods_xml: result[:mods_xml],
      tapas_xq_project_id: result[:tapas_xq_project_id],
      tapas_xq_doc_id: result[:tapas_xq_doc_id],
      processing_status: "completed",
      processing_error: nil
    )

    Rails.logger.info("TAPAS-XQ processing completed for CoreFile #{core_file_id}")
  rescue TapasXq::Error => e
    core_file.update!(
      processing_status: "failed",
      processing_error: e.message
    )
    raise # Re-raise for retry logic
  rescue StandardError => e
    core_file.update!(
      processing_status: "failed",
      processing_error: "Unexpected error: #{e.message}"
    )
    Rails.logger.error("Unexpected error processing CoreFile #{core_file_id}: #{e.class} - #{e.message}")
    raise
  end
end
