# frozen_string_literal: true

namespace :tapas_xq do
  desc "Retry all failed CoreFile processing"
  task retry_failed: :environment do
    failed_files = CoreFile.processing_failed

    puts "Found #{failed_files.count} failed CoreFiles"

    failed_files.find_each do |core_file|
      if core_file.retry_processing!
        puts "✓ Re-queued: #{core_file.title} (ID: #{core_file.id})"
      else
        puts "✗ Cannot retry: #{core_file.title} (ID: #{core_file.id})"
      end
    end

    puts "\nDone! Check SolidQueue for job progress."
  end

  desc "Reprocess all CoreFiles (use with caution)"
  task reprocess_all: :environment do
    puts "WARNING: This will re-upload ALL CoreFiles to TAPAS-XQ"
    puts "Press Ctrl+C to cancel, or Enter to continue..."
    STDIN.gets

    CoreFile.find_each do |core_file|
      next unless core_file.tei_file.attached?

      core_file.update!(processing_status: "pending", processing_error: nil)
      ProcessTeiFileJob.perform_later(core_file.id)

      puts "✓ Queued: #{core_file.title} (ID: #{core_file.id})"
    end

    puts "\nDone!"
  end

  desc "Check TAPAS-XQ connection"
  task check_connection: :environment do
    begin
      client = TapasXq::Client.new
      # Try to get the API documentation endpoint
      response = client.get("/api")
      puts "✓ Connected to TAPAS-XQ at #{TapasXq.configuration.base_url}"
      puts "  Response status: 200 OK"
      puts "  Response length: #{response.length} bytes"
    rescue TapasXq::Error => e
      puts "✗ Cannot connect to TAPAS-XQ"
      puts "  Error: #{e.class} - #{e.message}"
      puts "\nCheck your configuration:"
      puts "  TAPAS_XQ_BASE_URL: #{TapasXq.configuration.base_url}"
      puts "  TAPAS_XQ_USERNAME: #{TapasXq.configuration.username}"
      puts "  TAPAS_XQ_ENABLED: #{TapasXq.configuration.enabled}"
      exit 1
    end
  end

  desc "Sync MODS from TAPAS-XQ for a CoreFile"
  task :sync_mods, [ :core_file_id ] => :environment do |t, args|
    unless args[:core_file_id]
      puts "Error: core_file_id required"
      puts "Usage: rails tapas_xq:sync_mods[123]"
      exit 1
    end

    core_file = CoreFile.find(args[:core_file_id])

    unless core_file.tapas_xq_project_id && core_file.tapas_xq_doc_id
      puts "✗ CoreFile not yet uploaded to TAPAS-XQ"
      puts "  processing_status: #{core_file.processing_status}"
      exit 1
    end

    service = TapasXq::RetrievalService.new(
      core_file.tapas_xq_project_id,
      core_file.tapas_xq_doc_id
    )

    begin
      mods_xml = service.retrieve_mods
      core_file.update!(mods_xml: mods_xml)

      puts "✓ Synced MODS for: #{core_file.title}"
      puts "  MODS size: #{mods_xml.length} bytes"
    rescue TapasXq::Error => e
      puts "✗ Error: #{e.message}"
      exit 1
    end
  end

  desc "Show processing status summary"
  task status: :environment do
    total = CoreFile.count
    pending = CoreFile.processing_pending.count
    processing = CoreFile.where(processing_status: "processing").count
    completed = CoreFile.processing_completed.count
    failed = CoreFile.processing_failed.count

    puts "TAPAS-XQ Processing Status Summary"
    puts "=" * 40
    puts "Total CoreFiles:      #{total}"
    puts "Pending:              #{pending}"
    puts "Processing:           #{processing}"
    puts "Completed:            #{completed}"
    puts "Failed:               #{failed}"
    puts

    if failed > 0
      puts "Failed CoreFiles:"
      CoreFile.processing_failed.limit(10).each do |cf|
        puts "  [#{cf.id}] #{cf.title}"
        puts "      Error: #{cf.processing_error&.truncate(80)}"
      end

      if failed > 10
        puts "  ... and #{failed - 10} more"
      end

      puts "\nRun 'rails tapas_xq:retry_failed' to retry all failed processing."
    end
  end
end
