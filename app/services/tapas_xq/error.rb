# frozen_string_literal: true

module TapasXq
  # Base error class for all TAPAS-XQ related errors
  class Error < StandardError; end

  # Raised when unable to establish connection to TAPAS-XQ
  class ConnectionError < Error; end

  # Raised when authentication with TAPAS-XQ fails
  class AuthenticationError < Error; end

  # Raised when a TAPAS-XQ request times out
  class TimeoutError < Error; end

  # Raised when TAPAS-XQ returns an unexpected response format
  class InvalidResponseError < Error; end

  # Raised when a requested resource is not found in TAPAS-XQ
  class NotFoundError < Error; end

  # Raised when access to a TAPAS-XQ resource is forbidden (e.g. private file)
  class ForbiddenError < Error; end

  # Raised when TAPAS-XQ returns a server error (5xx)
  class ServerError < Error; end
end
