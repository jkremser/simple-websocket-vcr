# This needs to go before all requires to be able to record full coverage
require 'coveralls'
Coveralls.wear!

# https://stackoverflow.com/a/9095369/10513533
# Without this, exceptions coming from code run in threads won't fail tests.
# For example, WebSocketVCR::RecordableWebsocketClient uses threads.
Thread.abort_on_exception = true

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.order = 'random'
end
