require 'vcr'
require 'thread'
require 'websocket-client-simple'
require 'json'

describe 'VCR for WS' do
  HOST = 'localhost:8080'.freeze

  let(:example) do |e|
    e
  end

  before(:each) do
    VCR::WebSocket.configuration.reset_defaults!
  end

  it 'should record the very first message caught on the client yielded by the connect method' do
    VCR::WebSocket.configure do |c|
      c.hook_uris = [HOST]
    end
    VCR::WebSocket.record(example, self) do
      url = "ws://#{HOST}/hawkular/command-gateway/ui/ws"
      c = WebSocket::Client::Simple.connect url do |client|
        client.on(:message, once: true, &:data)
      end
      sleep 1

      expect(c).not_to be nil
      expect(c.open?).to be true
    end
  end

  it 'should record also the outgoing communication' do
    VCR::WebSocket.configure do |c|
      c.hook_uris = [HOST]
    end
    VCR::WebSocket.record(example, self) do
      url = "ws://#{HOST}/hawkular/command-gateway/ui/ws"
      c = WebSocket::Client::Simple.connect url do |client|
        client.on(:message, once: true, &:data)
      end
      sleep 1
      c.send('something 1')
      c.send('something 2')
      c.send('something 3')

      expect(c).not_to be nil
      expect(c.open?).to be true
    end
  end

  it 'should record the closing event' do
    VCR::WebSocket.configure do |c|
      c.hook_uris = [HOST]
    end
    VCR::WebSocket.record(example, self) do
      url = "ws://#{HOST}/hawkular/command-gateway/ui/ws"
      c = WebSocket::Client::Simple.connect url do |client|
        client.on(:message, once: true, &:data)
      end
      sleep 1

      expect(c).not_to be nil
      expect(c.open?).to be true
      sleep 1
      c.close
      expect(c.open?).to be false
    end
  end

  it 'should record complex communications' do
    VCR::WebSocket.configure do |c|
      c.hook_uris = [HOST]
    end
    cassette_path = '/EXPLICIT/some_explicitly_specified_cassette.json'
    VCR::WebSocket.use_cassette(cassette_path) do
      url = "ws://#{HOST}/hawkular/command-gateway/ui/ws"
      c = WebSocket::Client::Simple.connect url do |client|
        client.on(:message, once: true, &:data)
      end
      sleep 1
      c.send('something_1')
      c.on(:message, once: true, &:data)
      sleep 1

      c.send('something_2')
      c.on(:message, once: true, &:data)
      sleep 1

      expect(c).not_to be nil
      expect(c.open?).to be true
      c.close
      expect(c.open?).to be false
      sleep 1
    end

    # check that everything was recorded in the json file
    file_path = VCR::WebSocket.configuration.cassette_library_dir + cassette_path
    expect(File.readlines(file_path).grep(/WelcomeResponse/).size).to eq(1)
    # once in the client message and once in the GenericErrorResponse from the server
    expect(File.readlines(file_path).grep(/something_1/).size).to eq(2)
    expect(File.readlines(file_path).grep(/something_2/).size).to eq(2)
    expect(File.readlines(file_path).grep(/close/).size).to eq(1)
  end

  context 'automatically picked cassette name is ok, when using context foo' do
    it 'and example bar' do
      VCR::WebSocket.record(example, self) do
        # nothing
      end
      prefix = VCR::WebSocket.configuration.cassette_library_dir
      name = 'automatically_picked_cassette_name_is_ok,_when_using_context_foo_and_example_bar.json'
      expect(File.exist?(prefix + '/VCR_for_WS/' + name)).to be true
    end
  end

  describe 'automatically picked cassette name is ok, when describing parent' do
    it 'and example child1' do
      VCR::WebSocket.record(example, self) do
        # nothing
      end
      prefix = VCR::WebSocket.configuration.cassette_library_dir
      name = 'automatically_picked_cassette_name_is_ok,_when_describing_parent_and_example_child1.json'
      expect(File.exist?(prefix + '/VCR_for_WS/' + name)).to be true
    end

    it 'and example child2' do
      VCR::WebSocket.record(example, self) do
        # nothing
      end
      prefix = VCR::WebSocket.configuration.cassette_library_dir
      name = 'automatically_picked_cassette_name_is_ok,_when_describing_parent_and_example_child2.json'
      expect(File.exist?(prefix + '/VCR_for_WS/' + name)).to be true
    end
  end

  describe '.configuration' do
    it 'has a default cassette location configured' do
      expect(VCR::WebSocket.configuration.cassette_library_dir).to eq('spec/fixtures/vcr_cassettes')
    end

    it 'has an empty list of hook ports by default' do
      expect(VCR::WebSocket.configuration.hook_uris).to eq([])
    end
  end

  describe '.configure' do
    it 'configures cassette location' do
      expect do
        VCR::WebSocket.configure { |c| c.cassette_library_dir = 'foo/bar' }
      end.to change { VCR::WebSocket.configuration.cassette_library_dir }
        .from('spec/fixtures/vcr_cassettes')
        .to('foo/bar')
    end

    it 'configures URIs to hook' do
      expect do
        VCR::WebSocket.configure { |c| c.hook_uris = ['127.0.0.1:1337'] }
      end.to change { VCR::WebSocket.configuration.hook_uris }.from([]).to(['127.0.0.1:1337'])
    end
  end
end
