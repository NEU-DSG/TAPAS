# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TapasXq::Client, type: :service do
  let(:client) { described_class.new }
  let(:base_url) { TapasXq.configuration.base_url }

  describe '#post' do
    it 'makes POST request with auth and returns response body' do
      stub_request(:post, "#{base_url}/test")
        .with(basic_auth: [ client.username, client.password ])
        .to_return(status: 201, body: "<response>success</response>")

      result = client.post('/test', { param: 'value' })
      expect(result).to eq("<response>success</response>")
    end

    it 'accepts 200 status code' do
      stub_request(:post, "#{base_url}/test")
        .to_return(status: 200, body: "<response/>")

      result = client.post('/test')
      expect(result).to eq("<response/>")
    end

    it 'accepts 202 status code' do
      stub_request(:post, "#{base_url}/test")
        .to_return(status: 202, body: "<response/>")

      result = client.post('/test')
      expect(result).to eq("<response/>")
    end

    it 'sends params as form parameters in the request body' do
      stub_request(:post, "#{base_url}/test-project/test-doc")
        .with(body: { file: '<TEI/>', collections: 'col1,col2' })
        .to_return(status: 201, body: "<mods/>")

      result = client.post('/test-project/test-doc', { file: '<TEI/>', collections: 'col1,col2' })
      expect(result).to eq("<mods/>")
    end

    it 'raises InvalidResponseError on unexpected 2xx status code' do
      stub_request(:post, "#{base_url}/test")
        .to_return(status: 204, body: "")

      expect {
        client.post('/test')
      }.to raise_error(TapasXq::InvalidResponseError, /Unexpected status code: 204/)
    end

    it 'raises ConnectionError on SocketError' do
      stub_request(:post, "#{base_url}/test")
        .to_raise(SocketError.new("Connection refused"))

      expect {
        client.post('/test')
      }.to raise_error(TapasXq::ConnectionError, /Cannot connect/)
    end

    it 'raises ConnectionError on Errno::ECONNREFUSED' do
      stub_request(:post, "#{base_url}/test")
        .to_raise(Errno::ECONNREFUSED)

      expect {
        client.post('/test')
      }.to raise_error(TapasXq::ConnectionError)
    end

    it 'raises AuthenticationError on 401' do
      stub_request(:post, "#{base_url}/test")
        .to_return(status: 401, body: "Unauthorized")

      expect {
        client.post('/test')
      }.to raise_error(TapasXq::AuthenticationError, /Invalid TAPAS-XQ credentials/)
    end

    it 'raises TimeoutError on timeout' do
      stub_request(:post, "#{base_url}/test")
        .to_timeout

      expect {
        client.post('/test')
      }.to raise_error(TapasXq::TimeoutError, /timed out/)
    end

    it 'raises ServerError on 500' do
      stub_request(:post, "#{base_url}/test")
        .to_return(status: 500, body: "Internal Server Error")

      expect {
        client.post('/test')
      }.to raise_error(TapasXq::ServerError)
    end

    it 'raises InvalidResponseError on unexpected status code' do
      stub_request(:post, "#{base_url}/test")
        .to_return(status: 418, body: "I'm a teapot")

      expect {
        client.post('/test')
      }.to raise_error(TapasXq::InvalidResponseError, /Unexpected status code: 418/)
    end
  end

  describe '#get' do
    it 'makes GET request with auth and returns response body' do
      stub_request(:get, "#{base_url}/test")
        .with(basic_auth: [ client.username, client.password ])
        .to_return(status: 200, body: "<data>content</data>")

      result = client.get('/test')
      expect(result).to eq("<data>content</data>")
    end

    it 'raises NotFoundError on 404' do
      stub_request(:get, "#{base_url}/test")
        .to_return(status: 404, body: "Not Found")

      expect {
        client.get('/test')
      }.to raise_error(TapasXq::NotFoundError, /Resource not found/)
    end

    it 'raises ForbiddenError on 403' do
      stub_request(:get, "#{base_url}/test")
        .to_return(status: 403, body: "Forbidden")

      expect {
        client.get('/test')
      }.to raise_error(TapasXq::ForbiddenError, /Access to resource is forbidden/)
    end

    it 'raises AuthenticationError on 401' do
      stub_request(:get, "#{base_url}/test")
        .to_return(status: 401)

      expect {
        client.get('/test')
      }.to raise_error(TapasXq::AuthenticationError)
    end

    it 'raises TimeoutError on timeout' do
      stub_request(:get, "#{base_url}/test")
        .to_timeout

      expect {
        client.get('/test')
      }.to raise_error(TapasXq::TimeoutError, /timed out/)
    end

    it 'raises ServerError on 500' do
      stub_request(:get, "#{base_url}/test")
        .to_return(status: 500)

      expect {
        client.get('/test')
      }.to raise_error(TapasXq::ServerError)
    end

    it 'raises ConnectionError on connection failure' do
      stub_request(:get, "#{base_url}/test")
        .to_raise(SocketError.new("Connection refused"))

      expect {
        client.get('/test')
      }.to raise_error(TapasXq::ConnectionError)
    end
  end

  describe '#delete' do
    it 'makes DELETE request with auth and returns response body' do
      stub_request(:delete, "#{base_url}/test")
        .with(basic_auth: [ client.username, client.password ])
        .to_return(status: 202, body: "<deleted/>")

      result = client.delete('/test')
      expect(result).to eq("<deleted/>")
    end

    it 'raises AuthenticationError on 401' do
      stub_request(:delete, "#{base_url}/test")
        .to_return(status: 401)

      expect {
        client.delete('/test')
      }.to raise_error(TapasXq::AuthenticationError)
    end

    it 'raises ServerError on 500' do
      stub_request(:delete, "#{base_url}/test")
        .to_return(status: 500)

      expect {
        client.delete('/test')
      }.to raise_error(TapasXq::ServerError)
    end

    it 'raises ConnectionError on connection failure' do
      stub_request(:delete, "#{base_url}/test")
        .to_raise(Errno::ECONNREFUSED)

      expect {
        client.delete('/test')
      }.to raise_error(TapasXq::ConnectionError)
    end
  end

  describe 'configuration' do
    it 'uses default configuration from TapasXq.configuration' do
      expect(client.base_url).to eq(TapasXq.configuration.base_url)
      expect(client.username).to eq(TapasXq.configuration.username)
      expect(client.password).to eq(TapasXq.configuration.password)
      expect(client.timeout).to eq(TapasXq.configuration.timeout)
    end

    it 'allows overriding configuration via constructor' do
      custom_client = described_class.new(
        base_url: 'http://custom.example.com',
        username: 'custom_user',
        password: 'custom_pass',
        timeout: 60
      )

      expect(custom_client.base_url).to eq('http://custom.example.com')
      expect(custom_client.username).to eq('custom_user')
      expect(custom_client.password).to eq('custom_pass')
      expect(custom_client.timeout).to eq(60)
    end
  end
end
