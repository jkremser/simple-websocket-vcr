module VCR
  module WebSocket
    class Configuration
      attr_accessor :cassette_library_dir, :hook_uris, :json_cassettes

      def initialize
        reset_defaults!
      end

      def reset_defaults!
        @cassette_library_dir = 'spec/fixtures/vcr_cassettes'
        @hook_uris = []
        @json_cassettes = false
      end

      def method_missing(method_name, *_args, &_block)
        puts 'unknown method: ' + method_name.to_s
      end
    end
  end
end
