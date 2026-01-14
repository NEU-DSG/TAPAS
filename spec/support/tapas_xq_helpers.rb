# frozen_string_literal: true

module TapasXqHelpers
  def tapas_xq_url(project_id:, doc_id:)
    "#{TapasXq.configuration.base_url}/#{project_id}/#{doc_id}"
  end

  def stub_tapas_xq_store(project_id:, doc_id:, mods_xml: "<mods/>")
    stub_request(:post, tapas_xq_url(project_id: project_id, doc_id: doc_id))
      .to_return(status: 201, body: mods_xml, headers: { 'Content-Type' => 'application/xml' })
  end

  def stub_tapas_xq_store_failure(project_id:, doc_id:, status: 500, body: "Internal Server Error")
    stub_request(:post, tapas_xq_url(project_id: project_id, doc_id: doc_id))
      .to_return(status: status, body: body)
  end

  def stub_tapas_xq_retrieve_tei(project_id:, doc_id:, tei_xml: "<TEI></TEI>")
    stub_request(:get, "#{TapasXq.configuration.base_url}/#{project_id}/#{doc_id}/tei")
      .to_return(status: 200, body: tei_xml, headers: { 'Content-Type' => 'application/xml' })
  end

  def stub_tapas_xq_retrieve_mods(project_id:, doc_id:, mods_xml: "<mods></mods>")
    stub_request(:get, "#{TapasXq.configuration.base_url}/#{project_id}/#{doc_id}/mods")
      .to_return(status: 200, body: mods_xml, headers: { 'Content-Type' => 'application/xml' })
  end

  def stub_tapas_xq_retrieve_tfe(project_id:, doc_id:, tfe_xml: "<tfe></tfe>")
    stub_request(:get, "#{TapasXq.configuration.base_url}/#{project_id}/#{doc_id}/tfe")
      .to_return(status: 200, body: tfe_xml, headers: { 'Content-Type' => 'application/xml' })
  end

  def stub_tapas_xq_connection_error(project_id:, doc_id:)
    stub_request(:post, tapas_xq_url(project_id: project_id, doc_id: doc_id))
      .to_raise(SocketError.new("Connection refused"))
  end

  def stub_tapas_xq_timeout(project_id:, doc_id:)
    stub_request(:post, tapas_xq_url(project_id: project_id, doc_id: doc_id))
      .to_timeout
  end

  def stub_tapas_xq_auth_failure(project_id:, doc_id:)
    stub_request(:post, tapas_xq_url(project_id: project_id, doc_id: doc_id))
      .to_return(status: 401, body: "Unauthorized")
  end
end

RSpec.configure do |config|
  config.include TapasXqHelpers, type: :service
  config.include TapasXqHelpers, type: :job
  config.include TapasXqHelpers, type: :model
  config.include TapasXqHelpers, type: :request
end
