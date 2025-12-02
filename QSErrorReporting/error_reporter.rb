# frozen_string_literal: true

require 'grpc'
require_relative 'Protos/Reception_pb'
require_relative 'Protos/Reception_services_pb'

module QSErrorReporting
  # Main error reporting class that sends errors to the server via gRPC
  class ErrorReporter
    # Server connection settings (hardcoded)
    SERVER_HOST = 'fail.cloud.qsolution.ru'
    SERVER_PORT = 4202
    USE_TLS = false  # Set to true when migrated to port 443
    TIMEOUT = 10

    attr_reader :config

    # Initialize the error reporter with configuration
    # @param config [Hash] Configuration hash with the following keys:
    #   - product_code [Integer] Product identification code
    #   - modification [String] Product modification name
    #   - version [String] Application version
    #   - user_name [String] User name (optional)
    #   - user_email [String] User email (optional)
    #   - database_name [String] Database name (optional)
    def initialize(config)
      @config = config
      validate_config!
      @stub = create_stub
    end

    # Report an error to the server
    # @param exception [Exception] The exception to report
    # @param report_type [Symbol] Type of report (:automatic, :user, :known)
    # @param user_description [String] Optional user description
    # @param log [String] Optional log content
    # @return [Boolean] True if error was successfully reported
    def report_error(exception, report_type: :automatic, user_description: '', log: '')
      request = build_request(exception, report_type, user_description, log)

      begin
        @stub.submit_error(request, deadline: Time.now + TIMEOUT)
        true
      rescue GRPC::BadStatus => e
        warn "Failed to report error to server: #{e.message}"
        false
      rescue StandardError => e
        warn "Unexpected error while reporting: #{e.message}"
        false
      end
    end

    # Install global exception handler
    # This captures unhandled exceptions and reports them automatically
    def install_global_handler!
      at_exit do
        if $! && !$!.is_a?(SystemExit)
          report_error($!, report_type: :automatic)
        end
      end
    end

    private

    def validate_config!
      required_keys = [:product_code, :modification, :version]
      missing_keys = required_keys - @config.keys

      unless missing_keys.empty?
        raise ArgumentError, "Missing required configuration keys: #{missing_keys.join(', ')}"
      end
    end

    def create_stub
      server_url = "#{SERVER_HOST}:#{SERVER_PORT}"

      if USE_TLS
        credentials = GRPC::Core::ChannelCredentials.new
        QS::ErrorReporting::Reception::Stub.new(server_url, credentials)
      else
        QS::ErrorReporting::Reception::Stub.new(server_url, :this_channel_is_insecure)
      end
    end

    def build_request(exception, report_type, user_description, log)
      request = QS::ErrorReporting::SubmitErrorRequest.new

      # User info
      request.user = QS::ErrorReporting::UserInfo.new(
        name: @config.fetch(:user_name, ''),
        email: @config.fetch(:user_email, '')
      )

      # App info
      request.app = QS::ErrorReporting::AppInfo.new(
        product_code: @config[:product_code],
        modification: @config[:modification],
        version: @config[:version]
      )

      # Database info
      request.db = QS::ErrorReporting::DatabaseInfo.new(
        name: @config.fetch(:database_name, '')
      )

      # Error info
      request.report = QS::ErrorReporting::ErrorInfo.new(
        stack_trace: format_stack_trace(exception),
        user_description: user_description,
        log: log,
        message: exception.message
      )

      # Report type
      request.report_type = case report_type
                            when :user
                              QS::ErrorReporting::ReportType::REPORT_TYPE_USER
                            when :known
                              QS::ErrorReporting::ReportType::REPORT_TYPE_KNOWN
                            else
                              QS::ErrorReporting::ReportType::REPORT_TYPE_AUTOMATIC
                            end

      request
    end

    def format_stack_trace(exception)
      backtrace = exception.backtrace || []
      "#{exception.class}: #{exception.message}\n#{backtrace.join("\n")}"
    end
  end
end
