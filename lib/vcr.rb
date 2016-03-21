require 'vcr/cassette'
require 'vcr/configuration'
require 'vcr/errors'
require 'vcr/recordable_websocket_client'
require 'vcr/version'
require 'json'
require 'websocket-client-simple'

module VCR
  module WebSocket
    def configure
      yield configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def cassette
      @cassette
    end

    def cassette=(v)
      @cassette = v
    end

    def disabled
      @disabled || false
    end

    def disabled=(v)
      @disabled = v
    end

    def save_session
    end

    def use_cassette(name, _options = {})
      raise ArgumentError, '`VCR.use_cassette` requires a block.' unless block_given?
      self.cassette = Cassette.new(name)
      yield
      cassette.save
      self.cassette = nil
    end

    def record(example, context, options = {}, &block)
      raise ArgumentError, '`VCR.record` requires a block.' unless block_given?
      name = filename_helper(example, context)
      use_cassette(name, options, &block)
    end

    def turn_off!(options = {})
      # TODO: impl
    end

    def turned_on?
      # TODO: impl
    end

    def turn_on!
      # TODO: impl
    end

    private

    def filename_helper(example, context)
      if context.class.metadata[:parent_example_group].nil?
        example_name = example.description.gsub(/\s+/, '_')
        directory = context.class.metadata[:description].gsub(/\s+/, '_')
      else
        example_name = "#{context.class.metadata[:description]}_#{example.description}".gsub(/\s+/, '_')
        directory = context.class.metadata[:parent_example_group][:description].gsub(/\s+/, '_')
      end
      "#{directory}/#{example_name}.json"
    end

    module_function :configure, :configuration, :cassette, :cassette=, :disabled, :disabled=, :save_session,
                    :use_cassette, :record, :turn_off!, :turned_on?, :turn_on!, :filename_helper
  end
end

module WebSocket::Client::Simple
  class << self
    alias real_connect connect

    def connect(url, options = {})
      if VCR::WebSocket.configuration.hook_uris.any? { |u| url.include?(u) }
        cassette = VCR::WebSocket.cassette
        live = cassette.recording?
        real_client = real_connect(url, options) if live
        fake_client = VCR::WebSocket::RecordableWebsocketClient.new(cassette, live ? real_client : nil)
        yield fake_client if block_given?
        fake_client
      else
        real_connect(url, options)
      end
    end
  end
end
