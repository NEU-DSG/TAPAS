# frozen_string_literal: true

module TapasXq
  # Retrieves TEI, MODS, and TFE (TAPAS-friendly environment) files from
  # TAPAS-XQ as XML strings. Raises TapasXq::Error on API failure.
  class Retrieval
    attr_reader :client, :project_id, :doc_id

    # @param project_id [String, Integer] The project ID
    # @param doc_id [String, Integer] The document ID
    # @param client [TapasXq::Client, nil] Optional client for testing
    def initialize(project_id, doc_id, client: nil)
      @project_id = project_id
      @doc_id = doc_id
      @client = client || TapasXq::Client.new
    end

    def retrieve_tei
      client.get("/#{project_id}/#{doc_id}/tei")
    end

    def retrieve_mods
      client.get("/#{project_id}/#{doc_id}/mods")
    end

    def retrieve_tfe
      client.get("/#{project_id}/#{doc_id}/tfe")
    end
  end
end
