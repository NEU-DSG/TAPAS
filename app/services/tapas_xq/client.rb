# frozen_string_literal: true

require "rest-client"

module TapasXq
  # HTTP client for communicating with the TAPAS-XQ API
  # Handles authentication, timeouts, and error handling
  class Client
    attr_reader :base_url, :username, :password, :timeout

    def initialize(base_url: nil, username: nil, password: nil, timeout: nil)
      @base_url = base_url || TapasXq.configuration.base_url
      @username = username || TapasXq.configuration.username
      @password = password || TapasXq.configuration.password
      @timeout = timeout || TapasXq.configuration.timeout
    end

    # Make a POST request to TAPAS-XQ
    # @param path [String] The API endpoint path (e.g., '/:project_id/:doc_id')
    # @param params [Hash] Form parameters to send
    # @return [String] Response body
    # @raise [TapasXq::Error] On any failure
    def post(path, params = {})
      response = RestClient::Request.execute(
        method: :post,
        url: "#{base_url}#{path}",
        user: username,
        password: password,
        timeout: timeout,
        payload: params
      )
      handle_response(response)
    rescue RestClient::Unauthorized
      raise TapasXq::AuthenticationError, "Invalid TAPAS-XQ credentials"
    rescue RestClient::Exceptions::OpenTimeout, RestClient::Exceptions::ReadTimeout
      raise TapasXq::TimeoutError, "TAPAS-XQ request timed out after #{timeout}s"
    rescue RestClient::ExceptionWithResponse => e
      handle_error_response(e)
    rescue SocketError, Errno::ECONNREFUSED => e
      raise TapasXq::ConnectionError, "Cannot connect to TAPAS-XQ: #{e.message}"
    end

    # Make a GET request to TAPAS-XQ
    # @param path [String] The API endpoint path
    # @return [String] Response body
    # @raise [TapasXq::Error] On any failure
    def get(path)
      response = RestClient::Request.execute(
        method: :get,
        url: "#{base_url}#{path}",
        user: username,
        password: password,
        timeout: timeout
      )
      handle_response(response)
    rescue RestClient::NotFound
      raise TapasXq::NotFoundError, "Resource not found"
    rescue RestClient::Forbidden
      raise TapasXq::ForbiddenError, "Access to resource is forbidden"
    rescue RestClient::Unauthorized
      raise TapasXq::AuthenticationError, "Invalid TAPAS-XQ credentials"
    rescue RestClient::Exceptions::OpenTimeout, RestClient::Exceptions::ReadTimeout
      raise TapasXq::TimeoutError, "TAPAS-XQ request timed out"
    rescue RestClient::ExceptionWithResponse => e
      handle_error_response(e)
    rescue SocketError, Errno::ECONNREFUSED => e
      raise TapasXq::ConnectionError, "Cannot connect to TAPAS-XQ: #{e.message}"
    end

    # Make a DELETE request to TAPAS-XQ
    # @param path [String] The API endpoint path
    # @return [String] Response body
    # @raise [TapasXq::Error] On any failure
    def delete(path)
      response = RestClient::Request.execute(
        method: :delete,
        url: "#{base_url}#{path}",
        user: username,
        password: password,
        timeout: timeout
      )
      handle_response(response)
    rescue RestClient::Unauthorized
      raise TapasXq::AuthenticationError, "Invalid TAPAS-XQ credentials"
    rescue RestClient::ExceptionWithResponse => e
      handle_error_response(e)
    rescue SocketError, Errno::ECONNREFUSED => e
      raise TapasXq::ConnectionError, "Cannot connect to TAPAS-XQ: #{e.message}"
    end

    private

    def handle_error_response(exception)
      case exception.http_code
      when 500..599
        raise TapasXq::ServerError, "TAPAS-XQ server error: #{exception.message}"
      else
        raise TapasXq::InvalidResponseError, "Unexpected status code: #{exception.http_code}"
      end
    end

    def handle_response(response)
      case response.code
      when 200, 201, 202
        response.body
      else
        raise TapasXq::InvalidResponseError,
              "Unexpected status code: #{response.code}"
      end
    end
  end
end
