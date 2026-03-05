# frozen_string_literal: true

# Load error classes first so they're available for job retry declarations
require_relative "../../app/services/tapas_xq/error"

module TapasXq
  class Configuration
    attr_accessor :base_url, :username, :password, :timeout, :enabled

    def initialize
      @base_url = ENV.fetch("TAPAS_XQ_BASE_URL", "http://localhost:8080/tapas-xq")
      @username = ENV.fetch("TAPAS_XQ_USERNAME", "username")
      @password = ENV.fetch("TAPAS_XQ_PASSWORD", "password")
      @timeout = ENV.fetch("TAPAS_XQ_TIMEOUT", "30").to_i
      @enabled = ActiveModel::Type::Boolean.new.cast(
        ENV.fetch("TAPAS_XQ_ENABLED", "true")
      )
    end

    def disabled?
      !enabled
    end
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end
