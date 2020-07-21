# frozen_string_literal: true

require_relative 'lib/evp_bytes_to_key/version'

Gem::Specification.new do |spec|
  spec.name          = 'evp_bytes_to_key'
  spec.version       = EvpBytesToKey::VERSION
  spec.authors       = ['anothermh']
  spec.summary       = "A pure Ruby implementation of OpenSSL's EVP_BytesToKey() function"
  spec.description   = 'The purpose of this gem is to make it easier to encrypt or decrypt data that has been encrypted by openssl'
  spec.homepage      = 'https://github.com/anothermh/evp_bytes_to_key'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.0.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/master/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'pry', '~> 0.13.1'
  spec.add_development_dependency 'rspec', '~> 3.9.0'
  spec.add_development_dependency 'rubocop', '~> 0.88.0'
  spec.add_development_dependency 'yard', '~> 0.9.25'
end
