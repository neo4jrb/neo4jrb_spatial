require 'bundler/gem_tasks'
require 'neo4j'
require 'neo4j/rake_tasks'
require 'neo4jrb_spatial/rake_tasks'
load 'neo4j/tasks/migration.rake'

task 'spec' do
  system_or_fail('rspec spec')
end

task default: ['spec']
