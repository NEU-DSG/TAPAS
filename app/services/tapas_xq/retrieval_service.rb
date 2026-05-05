# frozen_string_literal: true

module TapasXq
  # Service for retrieving TEI, MODS, and TFE files from TAPAS-XQ
  # Useful for debugging, syncing, and displaying stored content
  class RetrievalService
    attr_reader :client, :project_id, :doc_id

    # @param project_id [String, Integer] The project ID
    # @param doc_id [String, Integer] The document ID
    # @param client [TapasXq::Client, nil] Optional client for testing
    def initialize(project_id, doc_id, client: nil)
      @project_id = project_id
      @doc_id = doc_id
      @client = client || TapasXq::Client.new
    end

    # Retrieve the TEI file from TAPAS-XQ
    # @return [String] TEI XML content
    # @raise [TapasXq::Error] On API failure
    def retrieve_tei
      client.get("/#{project_id}/#{doc_id}/tei")
    end

    # Retrieve the MODS metadata from TAPAS-XQ
    # @return [String] MODS XML content
    # @raise [TapasXq::Error] On API failure
    def retrieve_mods
      client.get("/#{project_id}/#{doc_id}/mods")
    end

    # Retrieve the TFE (TAPAS-friendly environment) metadata from TAPAS-XQ
    # @return [String] TFE XML content
    # @raise [TapasXq::Error] On API failure
    def retrieve_tfe
      client.get("/#{project_id}/#{doc_id}/tfe")
    end
  end
end
