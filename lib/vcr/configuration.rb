module VCR
  module WebSocket
    class Configuration
      attr_accessor :cassette_library_dir, :hook_uris

      def initialize
        reset_defaults!
      end

      def reset_defaults!
        @cassette_library_dir = 'spec/fixtures/vcr_cassettes'
        @hook_uris = []
      end
    end
  end
end
