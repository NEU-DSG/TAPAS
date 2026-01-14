# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TapasXq::RetrievalService, type: :service do
  let(:project_id) { 123 }
  let(:doc_id) { 456 }
  let(:service) { described_class.new(project_id, doc_id) }

  describe '#retrieve_tei' do
    it 'fetches TEI XML from TAPAS-XQ' do
      tei_xml = "<TEI><teiHeader><title>Test Document</title></teiHeader></TEI>"
      stub_tapas_xq_retrieve_tei(
        project_id: project_id,
        doc_id: doc_id,
        tei_xml: tei_xml
      )

      result = service.retrieve_tei

      expect(result).to eq(tei_xml)
    end

    it 'raises NotFoundError if TEI does not exist' do
      stub_request(:get, "#{TapasXq.configuration.base_url}/#{project_id}/#{doc_id}/tei")
        .to_return(status: 404, body: "Not Found")

      expect {
        service.retrieve_tei
      }.to raise_error(TapasXq::NotFoundError)
    end

    it 'raises AuthenticationError on 401' do
      stub_request(:get, "#{TapasXq.configuration.base_url}/#{project_id}/#{doc_id}/tei")
        .to_return(status: 401, body: "Unauthorized")

      expect {
        service.retrieve_tei
      }.to raise_error(TapasXq::AuthenticationError)
    end

    it 'raises ConnectionError on connection failure' do
      stub_request(:get, "#{TapasXq.configuration.base_url}/#{project_id}/#{doc_id}/tei")
        .to_raise(SocketError.new("Connection refused"))

      expect {
        service.retrieve_tei
      }.to raise_error(TapasXq::ConnectionError)
    end
  end

  describe '#retrieve_mods' do
    it 'fetches MODS XML from TAPAS-XQ' do
      mods_xml = "<mods><title>Test Document</title><author>John Doe</author></mods>"
      stub_tapas_xq_retrieve_mods(
        project_id: project_id,
        doc_id: doc_id,
        mods_xml: mods_xml
      )

      result = service.retrieve_mods

      expect(result).to eq(mods_xml)
    end

    it 'raises NotFoundError if MODS does not exist' do
      stub_request(:get, "#{TapasXq.configuration.base_url}/#{project_id}/#{doc_id}/mods")
        .to_return(status: 404, body: "Not Found")

      expect {
        service.retrieve_mods
      }.to raise_error(TapasXq::NotFoundError)
    end

    it 'raises ServerError on 500' do
      stub_request(:get, "#{TapasXq.configuration.base_url}/#{project_id}/#{doc_id}/mods")
        .to_return(status: 500, body: "Internal Server Error")

      expect {
        service.retrieve_mods
      }.to raise_error(TapasXq::ServerError)
    end
  end

  describe '#retrieve_tfe' do
    it 'fetches TFE XML from TAPAS-XQ' do
      tfe_xml = "<tfe><project>123</project><collections>coll1,coll2</collections></tfe>"
      stub_tapas_xq_retrieve_tfe(
        project_id: project_id,
        doc_id: doc_id,
        tfe_xml: tfe_xml
      )

      result = service.retrieve_tfe

      expect(result).to eq(tfe_xml)
    end

    it 'raises NotFoundError if TFE does not exist' do
      stub_request(:get, "#{TapasXq.configuration.base_url}/#{project_id}/#{doc_id}/tfe")
        .to_return(status: 404, body: "Not Found")

      expect {
        service.retrieve_tfe
      }.to raise_error(TapasXq::NotFoundError)
    end

    it 'raises TimeoutError on timeout' do
      stub_request(:get, "#{TapasXq.configuration.base_url}/#{project_id}/#{doc_id}/tfe")
        .to_timeout

      expect {
        service.retrieve_tfe
      }.to raise_error(TapasXq::TimeoutError)
    end
  end

  describe 'initialization' do
    it 'accepts project_id and doc_id' do
      expect(service.project_id).to eq(project_id)
      expect(service.doc_id).to eq(doc_id)
    end

    it 'uses default client if none provided' do
      expect(service.client).to be_a(TapasXq::Client)
    end

    it 'accepts custom client' do
      custom_client = TapasXq::Client.new(base_url: 'http://custom.example.com')
      custom_service = described_class.new(project_id, doc_id, client: custom_client)

      expect(custom_service.client).to eq(custom_client)
    end
  end
end
