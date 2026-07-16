# frozen_string_literal: true

require_relative 'lib/block_repeater/version'

Gem::Specification.new do |spec|
  spec.name          = 'block_repeater'
  spec.version       = BlockRepeater::VERSION
  spec.authors       = ['William Bray']
  spec.email         = ['wbray11@hotmail.com']

  spec.summary       = 'Conditionally repeat a block of code'
  spec.description   = 'Attempt a piece of code a set number of times or until a condition is met'
  spec.homepage      = 'https://github.com/dvla/block-repeater'
  spec.required_ruby_version = Gem::Requirement.new('>= 3.0.0')
  spec.license = 'MIT'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/dvla/block-repeater'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bump', '~> 0.6'
  spec.add_development_dependency 'bundler', '>= 2.4'
  spec.add_development_dependency 'ostruct'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.8'
  spec.add_development_dependency 'rubocop'
end
