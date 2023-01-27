# frozen_string_literal: true

require_relative 'lib/yabeda/shoryuken/version'

Gem::Specification.new do |spec|
  spec.name = 'yabeda-shoryuken'
  spec.version = Yabeda::Shoryuken::VERSION
  spec.authors = ['Roberto Scinocca']
  spec.email = ['roberto.scinocca@hey.com']

  spec.summary       = 'Yabeda extension for Shoryuken'
  spec.homepage      = 'https://github.com/retsef/yabeda-shoryuken'
  spec.license       = 'MIT'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/retsef/yabeda-shoryuken'
  spec.metadata['changelog_uri'] = 'https://github.com/retsef/yabeda-shoryuken/blob/master/CHANGELOG.md'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.3'

  spec.add_dependency 'anyway_config', '>= 1.3', '< 3'
  spec.add_dependency 'rack'
  spec.add_dependency 'shoryuken'
  spec.add_dependency 'yabeda', '~> 0.10'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
