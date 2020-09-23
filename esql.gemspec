require_relative 'lib/esql/version'

Gem::Specification.new do |spec|
  spec.name          = 'esql'
  spec.version       = Esql::VERSION
  spec.authors       = ['Paul Holden']
  spec.email         = ['paul@codelunker.com']

  spec.summary       = 'A library for ActiveRecord scoping using simple expressions.'
  spec.description   = 'A library for ActiveRecord scoping using simple expressions.'
  spec.homepage      = 'https://github.com/paulholden2/esql'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/paulholden2/esql'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord'
  spec.add_dependency 'babel_bridge', '~> 0.5'

  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'factory_bot'
  spec.add_development_dependency 'simplecov', ['~> 0.17']
end
