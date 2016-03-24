require 'delegate'
require 'websocket-client-simple'
require 'base64'
require 'simple_websocket_vcr/errors'

module VCR
  module WebSocket
    include Errors

    class RecordableWebsocketClient
      include EventEmitter

      attr_reader :live, :client
      attr_accessor :recording, :open, :thread

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

      def send(data, opt = { type: :text })
        _write(:send, data, opt)
      end

      def on(event, params = {}, &block)
        super(event, params, &block) unless @live
        _read(event, params, &block)
      end

      def emit(event, *data)
        @recording << { operation: 'read', data: data } if @live
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
          @recording << { operation: 'close' }
          @client.close
        else
          sleep 0.5 if @recording.first['operation'] != 'close'
          record = @recording.shift
          _ensure_operation('close', record['operation'])
          Thread.kill @thread if @thread
          @open = false
        end
      end

      private

      def _write(method, data, opt)
        text_data = opt[:type] == :text ? data.dup : Base64.encode64(data.dup)
        if @live
          @client.__send__(method, data, opt)
          @recording << { operation: 'write', data: text_data }
        else
          sleep 0.5 if @recording.first['operation'] != 'write'
          record = @recording.shift
          _ensure_operation('write', record['operation'])
          _ensure_data(text_data, record['data'])
        end
      end

      def _read(event, params, &_block)
        if @live
          rec = @recording
          @client.on(event, params) do |msg|
            data = msg.type == :text ? msg.data : Base64.decode64(msg.data)
            rec << { operation: 'read', type: msg.type, data: data }
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
          while @open && !@recording.empty?
            begin
              if @recording.first['operation'] == 'read'
                record = @recording.shift
                data = record['data']
                data = Base64.decode64(msg) if record['type'] != 'text'
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
        @recording.delete_at(@recording.index { |record| record['operation'] == 'read' } || @recording.length)
      end

      def _ensure_operation(desired, actual)
        string = "Expected to '#{desired}' but the next operation in recording was '#{actual}'"
        raise string unless desired == actual
      end

      def _ensure_data(desired, actual)
        string = "Expected data to be '#{desired}' but next data in recording was '#{actual}'"
        raise string unless desired == actual
      end
    end
  end
end
