# frozen_string_literal: true

module QSErrorReporting
  # Module for capturing and buffering console output
  # This allows us to collect the last N lines of logs when an error occurs
  class LogBuffer
    attr_reader :max_lines

    def initialize(max_lines: 300)
      @max_lines = max_lines
      @buffer = []
      @mutex = Mutex.new
      @original_stdout = nil
      @original_stderr = nil
    end

    # Start capturing console output
    def start_capture
      return if @original_stdout # Already capturing

      @original_stdout = $stdout
      @original_stderr = $stderr

      # Create a custom IO object that writes to both original output and our buffer
      $stdout = OutputCapture.new(@original_stdout, self)
      $stderr = OutputCapture.new(@original_stderr, self)
    end

    # Stop capturing console output
    def stop_capture
      return unless @original_stdout

      $stdout = @original_stdout
      $stderr = @original_stderr
      @original_stdout = nil
      @original_stderr = nil
    end

    # Add a line to the buffer
    # @param line [String] The line to add
    def add_line(line)
      @mutex.synchronize do
        @buffer << "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} | #{line}"
        @buffer.shift if @buffer.size > @max_lines
      end
    end

    # Get the last N lines from the buffer
    # @param count [Integer] Number of lines to retrieve (default: all)
    # @return [String] The collected log lines
    def get_last_lines(count = nil)
      @mutex.synchronize do
        lines = count ? @buffer.last(count) : @buffer
        lines.join("\n")
      end
    end

    # Clear the buffer
    def clear
      @mutex.synchronize do
        @buffer.clear
      end
    end

    # Get the current buffer size
    # @return [Integer] Number of lines in buffer
    def size
      @mutex.synchronize do
        @buffer.size
      end
    end

    # Custom IO class that captures output
    class OutputCapture
      def initialize(original_io, log_buffer)
        @original_io = original_io
        @log_buffer = log_buffer
      end

      def write(string)
        # Write to original output
        @original_io.write(string)

        # Add to buffer (split by lines)
        string.to_s.each_line do |line|
          @log_buffer.add_line(line.chomp) unless line.strip.empty?
        end

        string.length
      end

      def puts(*args)
        args.each do |arg|
          write("#{arg}\n")
        end
        nil
      end

      def print(*args)
        args.each { |arg| write(arg.to_s) }
        nil
      end

      def printf(format, *args)
        write(format % args)
        nil
      end

      # Forward all other methods to original IO
      def method_missing(method, *args, &block)
        @original_io.send(method, *args, &block)
      end

      def respond_to_missing?(method, include_private = false)
        @original_io.respond_to?(method, include_private) || super
      end
    end
  end
end
