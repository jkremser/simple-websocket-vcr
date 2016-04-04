require 'simple_websocket_vcr/errors'
require 'fileutils'

module WebSocketVCR
  include Errors

  class Cassette
    attr_reader :name, :options, :recording, :sessions

    alias_method :recording?, :recording

    def initialize(name, options)
      @name = name
      @options = options
      @using_json = WebSocketVCR.configuration.json_cassettes
      @name += @using_json ? '.json' : '.yml'

      if File.exist?(filename)
        @recording = false
        file_content = File.open(filename, &:read)

        # do the ERB substitution
        unless @options[:erb].nil?
          require 'ostruct'
          namespace = OpenStruct.new(@options[:erb])
          file_content = ERB.new(file_content).result(namespace.instance_eval{ binding })
        end

        # parse JSON/YAML
        if @using_json
          parsed_content = JSON.parse(file_content)
          @sessions = RecordedJsonSession.load(parsed_content)
        else
          parsed_content = YAML.load(file_content)
          @sessions = RecordedYamlSession.load(parsed_content)
        end

      else
        fail "No cassette '#{name}' found and recording has been turned off" if @options[:record] == :none
        @recording = true
        @sessions = []
      end
    end

    def next_session
      if recording?
        @sessions.push(@using_json ? RecordedJsonSession.new([]) : RecordedYamlSession.new([]))
        @sessions.last
      else
        fail NoMoreSessionsError if @sessions.empty?
        @sessions.shift
      end
    end

    def save
      return unless recording?
      dirname = File.dirname(filename)
      # make sure the directory structure is there
      FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
      if @using_json
        text = JSON.pretty_generate(@sessions.map(&:record_entries))
      else
        # TODO: :data: !ruby/string:WebSocket::Frame::Data 'GenericErrorResponse={"e..
        text = { 'websocket_interactions' => @sessions.map(&:record_entries) }.to_yaml(Indent: 8)
      end
      File.open(filename, 'w') { |f| f.write(text) }
    end

    protected

    def filename
      "#{WebSocketVCR.configuration.cassette_library_dir}/#{name}"
    end
  end

  class RecordedSession
    attr_reader :record_entries

    def initialize(entries)
      @record_entries = entries
    end

    def store(entry)
      hash = entry.is_a?(RecordEntry) ? entry.attributes.map(&:to_s) : entry.map { |k, v| [k.to_s, v.to_s] }.to_h
      @record_entries << hash
    end

    def next
      RecordEntry.parse(@record_entries.shift)
    end

    def head
      @record_entries.empty? ? nil : RecordEntry.parse(@record_entries.first)
    end

    def method_missing(method_name, *args, &block)
      @record_entries.__send__(method_name, *args, &block)
    end
  end

  class RecordedJsonSession < RecordedSession
    def self.load(json)
      json.map { |session| RecordedJsonSession.new(session) }
    end
  end

  class RecordedYamlSession < RecordedSession
    def self.load(yaml)
      yaml['websocket_interactions'].map { |session| RecordedYamlSession.new(session) }
    end
  end

  class RecordEntry
    attr_accessor :operation, :type, :data

    def self.parse(obj)
      record_entry = RecordEntry.new
      record_entry.operation = obj['operation']
      record_entry.type = obj['type'] if obj['type']
      record_entry.data = obj['data'] if obj['data']
      record_entry
    end
  end
end
