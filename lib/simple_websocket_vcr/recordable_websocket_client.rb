require 'delegate'
require 'websocket-client-simple'
require 'base64'
require 'simple_websocket_vcr/errors'

module WebSocketVCR
  include Errors

  class RecordableWebsocketClient
    include EventEmitter

    attr_reader :live, :client
    attr_accessor :session, :open, :thread

    def initialize(cassette, real_client)
      fail NoCassetteError 'specify the cassette' unless cassette

      if cassette.recording?
        @live = true
        @client = real_client
      else
        @live = false
        @open = true
      end
      @session = cassette.next_session
    end

    def send(data, opt = { type: :text })
      _write(:send, data, opt)
    end

    def on(event, params = {}, &block)
      super(event, params, &block) unless @live
      _read(event, params, &block)
    end

    def emit(event, *data)
      @session.store(operation: 'read', data: data) if @live
      super(event, *data)
    end

    def open?
      if @live
        @client.open?
      else
        @open
      end
    end

    def close
      if @live
        @session.store(operation: 'close')
        @client.close
      else
        sleep 0.5 if @session.head.operation != 'close'
        record = @session.next
        _ensure_operation('close', record.operation)
        Thread.kill @thread if @thread
        @open = false
      end
    end

    private

    def _write(method, data, opt)
      text_data = opt[:type] == :text ? data.dup : Base64.encode64(data.dup)
      if @live
        @client.__send__(method, data, opt)
        @session.store(operation: 'write', data: text_data)
      else
        sleep 0.5 if @session.head.operation != 'write'
        record = @session.next
        _ensure_operation('write', record.operation)
        _ensure_data(text_data, record.data)
      end
    end

    def _read(event, params, &_block)
      if @live
        rec = @session
        @client.on(event, params) do |msg|
          data = msg.type == :text ? msg.data : Base64.decode64(msg.data)
          rec.store(operation: 'read', type: msg.type, data: data)
          yield(msg)
        end
      else
        wait_for_reads(event, params[:once])
      end
    end

    def wait_for_reads(event, once = false)
      @thread = Thread.new do
        # if the next recorded operation is a 'read', take all the reads until next write
        # and translate them to the events
        while @open && !@session.empty?
          begin
            if @session.head.operation == 'read'
              record = @session.next
              data = record.data
              data = Base64.decode64(msg) if record.type != 'text'
              data = ::WebSocket::Frame::Data.new(data)

              def data.data
                self
              end

              emit(event, data)
              break if once
            else
              sleep 0.1 # TODO: config
            end
          end
        end
      end
    end

    def _take_first_read
      @session.delete_at(@session.index { |record| record.operation == 'read' } || @session.length)
    end

    def _ensure_operation(desired, actual)
      string = "Expected to '#{desired}' but the next operation in recording was '#{actual}'"
      fail string unless desired == actual
    end

    def _ensure_data(desired, actual)
      string = "Expected data to be '#{desired}' but next data in recording was '#{actual}'"
      fail string unless desired == actual
    end
  end
end
