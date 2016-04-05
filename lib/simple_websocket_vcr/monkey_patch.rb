module WebSocket::Client::Simple
  class << self
    alias_method :real_connect, :connect

    def connect(url, options = {})
      if WebSocketVCR.configuration.hook_uris.any? { |u| url.include?(u) }
        cassette = WebSocketVCR.cassette
        live = cassette.recording?
        real_client = real_connect(url, options) if live
        fake_client = WebSocketVCR::RecordableWebsocketClient.new(cassette, live ? real_client : nil)
        yield fake_client if block_given?
        fake_client
      else
        real_connect(url, options)
      end
    end
  end
end
