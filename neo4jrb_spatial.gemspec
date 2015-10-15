# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'neo4jrb_spatial/version'

Gem::Specification.new do |spec|
  spec.name          = 'neo4jrb_spatial'
  spec.version       = Neo4jrbSpatial::VERSION
  spec.authors       = ['Chris Grigg']
  spec.email         = ['chris@subvertallmedia.com']

  spec.summary       = 'Provides basic support for Neo4j Spatial with Neo4j.rb.'
  spec.homepage      = 'https://github.com/neo4jrb/neo4jrb_spatial'

  spec.files         = Dir.glob('{bin,lib,config}/**/*') + %w(README.md CHANGELOG.md Gemfile neo4jrb_spatial.gemspec)
  spec.bindir        = 'exe'
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.9'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency('rubocop', '~> 0.29.1')
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'pry'

  spec.add_dependency 'neo4j', '>= 5.0.1'
  spec.add_dependency 'neo4j-core', '>= 5.0.1'
end
