GEM_NAME = 'pakyow-realtime'

version = File.read(
  File.join(
    File.expand_path('../../VERSION', __FILE__)
  )
).strip

gem_path = File.exist?(GEM_NAME) ? GEM_NAME : '.'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = GEM_NAME
  s.version     = version
  s.summary     = 'Pakyow Realtime'
  s.description = 'WebSockets and realtime channels for Pakyow apps'
  s.required_ruby_version = '>= 2.0.0'
  s.license = 'MIT'

  s.authors           = ['Bryan Powell']
  s.email             = 'bryan@metabahn.com'
  s.homepage          = 'http://pakyow.com'

  s.files        = Dir[
                        File.join(gem_path, 'CHANGES'),
                        File.join(gem_path, 'README.md'),
                        File.join(gem_path, 'LICENSE'),
                        File.join(gem_path, 'lib', '**', '*')
                      ]

  s.require_path = File.join(gem_path, 'lib')

  s.add_dependency('websocket_parser', '~> 1.0')
  s.add_dependency('redis', '~> 3.2')
  s.add_dependency('concurrent-ruby')
end
