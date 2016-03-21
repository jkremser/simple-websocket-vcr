# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vcr/version'

Gem::Specification.new do |gem|
  gem.name          = 'simple-websocket-vcr'
  gem.version       = VCR::WebSocket::VERSION
  gem.authors       = ['Jirka Kremser']
  gem.email         = ['jkremser@redhat.com']
  gem.description   = 'Websocket VCR add-on'
  gem.summary       = 'simple-websocket-vcr is VCR add-on for websockets.'
  gem.homepage      = 'https://github.com/Jiri-Kremser/simple-websocket-vcr'
  gem.license       = 'Apache-2.0'

  gem.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_development_dependency('rspec-rails', '~> 3.0')
  gem.add_development_dependency('rake', '< 11')
  gem.add_development_dependency('websocket-client-simple', '~> 0.3')
end
