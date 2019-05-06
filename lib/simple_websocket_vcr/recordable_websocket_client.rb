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
      @session.store(operation: 'read', event: event, data: data) if @live
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
        @session.store(operation: 'write', event: 'close')
        @client.close
      else
        sleep 0.5 if @session.head && @session.head.event != 'close'
        @session.record_entries.size.times do
          record = @session.next
          _ensure_event('close', record.event)
          emit(record.event, record.data) if record.operation == 'read'
        end
        Thread.kill @thread if @thread
        @open = false
      end
    end

    private

    def _write(method, data, opt)
      text_data = opt[:type] == :text ? data.dup : Base64.encode64(data.dup)
      if @live
        @client.__send__(method, data, opt)
        @session.store(operation: 'write', event: method, data: text_data)
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
          params = { operation: 'read', event: event }
          unless msg.nil?
            data = msg.type.to_s == 'text' ? msg.data : Base64.encode64(msg.data)
            params.merge!(type: msg.type, data: data)
          end
          rec.store(params)
          yield(msg)
        end
      else
        wait_for_reads unless @thread && @thread.alive?
      end
    end

    def wait_for_reads
      @thread = Thread.new do
        # if the next recorded operation is a 'read', take all the reads until next write
        # and translate them to the events
        while @open && !@session.empty?
          begin
            if @session.head.operation == 'read'
              record = @session.next

              emit(record.event, parse_data(record))
              break if __events.empty?
            else
              sleep 0.1 # TODO: config
            end
          end
        end
      end
    end

    def parse_data(record)
      if (data = record.data)
        data = Base64.decode64(data) if record.type != 'text'
        data = ::WebSocket::Frame::Data.new(data)

        def data.data
          self
        end
      end
      data
    end

    def _take_first_read
      @session.delete_at(@session.index { |record| record.operation == 'read' } || @session.length)
    end

    def _ensure_operation(desired, actual)
      string = "Expected to '#{desired}' but the next operation in recording was '#{actual}'"
      fail string unless desired == actual
    end

    def _ensure_event(desired, actual)
      string = "Expected to '#{desired}' but the next event in recording was '#{actual}'"
      fail string unless desired == actual
    end

    def _ensure_data(desired, actual)
      string = "Expected data to be '#{desired}' but next data in recording was '#{actual}'"
      fail string unless desired == actual
    end
  end
end
