# frozen_string_literal: true

module TapasXq
  class Error < StandardError; end
  class ConnectionError < Error; end
  class AuthenticationError < Error; end
  class TimeoutError < Error; end
  class InvalidResponseError < Error; end
  class NotFoundError < Error; end

  # E.g. a private file.
  class ForbiddenError < Error; end

  # TAPAS-XQ returned a 5xx.
  class ServerError < Error; end
end
