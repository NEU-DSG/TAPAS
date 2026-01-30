# frozen_string_literal: true

module TapasXq
  # Service for storing TEI files in TAPAS-XQ and generating MODS/TFE metadata
  class StorageService
    attr_reader :client, :core_file

    # @param core_file [CoreFile] The core file to process
    # @param client [TapasXq::Client, nil] Optional client for testing
    def initialize(core_file, client: nil)
      @core_file = core_file
      @client = client || TapasXq::Client.new
    end

    # Upload TEI to TAPAS-XQ and generate MODS/TFE metadata
    # @return [Hash] Hash containing mods_xml, tapas_xq_project_id, tapas_xq_doc_id
    # @raise [ArgumentError] If prerequisites not met
    # @raise [TapasXq::Error] On API failure
    def store
      validate_prerequisites!

      project_id = core_file.project.id
      doc_id = core_file.id

      params = build_request_params
      path = "/#{project_id}/#{doc_id}"

      mods_xml = client.post(path, params)

      {
        mods_xml: mods_xml,
        tapas_xq_project_id: project_id.to_s,
        tapas_xq_doc_id: doc_id.to_s
      }
    rescue TapasXq::Error => e
      Rails.logger.error("TAPAS-XQ storage failed for CoreFile #{core_file.id}: #{e.message}")
      raise
    end

    private

    def validate_prerequisites!
      raise ArgumentError, "TEI file not attached" unless core_file.tei_file.attached?
      raise ArgumentError, "CoreFile must have project" unless core_file.project
    end

    def build_request_params
      {
        file: core_file.tei_file.download,
        collections: core_file.collections.pluck(:id).join(","),
        'is-public': core_file.is_public.to_s,
        title: core_file.title,
        authors: core_file.tei_authors || "",
        contributors: core_file.tei_contributors || ""
      }
    end
  end
end
