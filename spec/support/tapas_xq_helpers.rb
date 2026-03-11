# frozen_string_literal: true

module TapasXqHelpers
  def tapas_xq_url(project_id:, doc_id:)
    "#{TapasXq.configuration.base_url}/#{project_id}/#{doc_id}"
  end

  def stub_tapas_xq_store(project_id:, doc_id:, mods_xml: "<mods/>")
    stub_request(:post, tapas_xq_url(project_id: project_id, doc_id: doc_id))
      .to_return(status: 201, body: mods_xml)
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

  def stub_tapas_xq_store_failure(project_id:, doc_id:, status: 500)
    stub_request(:post, tapas_xq_url(project_id: project_id, doc_id: doc_id))
      .to_return(status: status, body: "Error")
  end
end

RSpec.configure do |config|
  config.include TapasXqHelpers
end
