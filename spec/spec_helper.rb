# This needs to go before all requires to be able to record full coverage
require 'coveralls'
Coveralls.wear!

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.order = 'random'
end
