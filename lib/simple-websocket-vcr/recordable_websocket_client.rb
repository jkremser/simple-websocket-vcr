require 'delegate'
require 'websocket-client-simple'
require 'base64'
require 'simple-websocket-vcr/errors'

module VCR
  module WebSocket
    include Errors

    class RecordableWebsocketClient
      include EventEmitter

      attr_reader :live, :client
      attr_accessor :recording, :open

      def initialize(cassette, real_client)
        raise NoCassetteError 'specify the cassette' unless cassette

        if cassette.recording?
          @live = true
          @client = real_client
        else
          @live = false
          @open = true
        end
        @recording = cassette.next_session
      end

      def send(data_param, opt = { type: :text })
        data = data_param.dup
        data = Base64.encode64(data) if opt[:type] != :text
        _write(:send, data, opt)
      end

      # or on
      def on(event, params = {}, &block)
        _read(:add_listener, event, params, &block)
      end

      def emit(event, *data)
        @recording << { operation: 'read', data: data } if live
        super(event, *data)
      end

      def open?
        if live
          @client.open?
        else
          @open
        end
      end

      def close
        if live
          @recording << { operation: 'close' }
          @client.close
        else
          record = @recording.shift
          _ensure_operation('close', record['operation'])
          @open = false
        end
      end

      private

      def _write(method, data, opt)
        if live
          @client.__send__(method, data, opt)
          @recording << { operation: 'write', data: data }
        else
          record = @recording.shift
          _ensure_operation('write', record['operation'])
          _ensure_data(data, record['data'])
        end
      end

      def _read(method, event, params, &block)
        if live
          rec = @recording
          @client.on(event, params) do |msg|
            msg = Base64.decode64(msg) if msg.type != :text
            rec << { operation: 'read', type: msg.type, data: msg }
            yield(msg)
          end
          @client.__send__(method, event, params, &block)
        else
          raise EOFError if @recording.empty?
          record = _take_first_read
          return if record.nil?
          _ensure_operation('read', record['operation'])
          data = record['data']
          data = Base64.decode64(msg) if record['type'] != 'text'
          emit(event, data)
        end
      end

      def _take_first_read
        @recording.delete_at(@recording.index { |record| record['operation'] == 'read' } || @recording.length)
      end

      def _ensure_operation(desired, actual)
        string = "Expected to '#{desired}' but next in recording was '#{actual}'"
        raise OperationMismatchError string unless desired == actual
      end

      def _ensure_data(desired, actual)
        string = "Expected data to be '#{desired}' but next in recording was '#{actual}'"
        raise DataMismatchError string unless desired == actual
      end
    end
  end
end
