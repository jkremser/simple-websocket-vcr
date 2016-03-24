require 'simple_websocket_vcr/errors'
require 'fileutils'

module VCR
  module WebSocket
    include Errors

    class Cassette
      attr_reader :name, :recording

      alias recording? recording

      def initialize(name)
        @name = name

        if File.exist?(filename)
          @recording = false
          @contents = File.open(filename, &:read)
          @sessions = JSON.parse(@contents)
        else
          @recording = true
          @sessions = []
        end
      end

      def next_session
        if recording?
          @sessions << []
          @sessions.last
        else
          raise NoMoreSessionsError if @sessions.empty?
          @sessions.shift
        end
      end

      def save
        return unless recording?
        dirname = File.dirname(filename)
        FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
        File.open(filename, 'w') { |f| f.write(JSON.pretty_generate(@sessions)) }
      end

      protected

      def filename
        "#{VCR::WebSocket.configuration.cassette_library_dir}/#{name}"
      end
    end
  end
end
