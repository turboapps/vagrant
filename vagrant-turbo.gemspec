lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant-turbo/version'

Gem::Specification.new do |s|
  s.name          = 'vagrant-turbo'
  s.version       = VagrantPlugins::Turbo::VERSION
  s.platform      = Gem::Platform::CURRENT
  s.authors       = 'Turbo.net'
  s.email         = 'support@turbo.net'
  s.summary       = 'Enables Vagrant to manage Turbo containers'
  s.description   = 'Enables Vagrant to manage Turbo containers'
  s.homepage      = 'https://github.com/turboapps/vagrant'
  s.license       = 'Apache License, Version 2.0'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = %w[lib]

  s.add_development_dependency 'bundler', '~> 1.10'
  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'rspec', '~> 3.3'
end
