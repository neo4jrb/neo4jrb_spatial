require 'bundler/gem_tasks'
require 'neo4j/rake_tasks'

def system_or_fail(command)
  system(command) || exit(1)
end

task 'spec' do
  system_or_fail('rspec spec')
end

namespace :neo4j_spatial do
  task 'install' do
    url = 'https://github.com/neo4j-contrib/m2/blob/master/releases/org/neo4j/neo4j-spatial'
    neo4j_version = ENV['NEO4J_VERSION']
    spatial_version = ENV['NEO4J_SPATIAL_VERSION']
    raise ArgumentError, 'Missing neo4j_version or spatial_version' unless neo4j_version || spatial_version
    if neo4j_version[0].to_i < 3
      system_or_fail("wget #{url}/#{spatial_version}-neo4j-#{neo4j_version}/neo4j-spatial-#{spatial_version}-neo4j-#{neo4j_version}-server-plugin.zip?raw=true")
      system_or_fail("unzip neo4j-spatial-#{spatial_version}-neo4j-#{neo4j_version}-server-plugin.zip -d ./db/neo4j/development/plugins")
    else
      system_or_fail("wget #{url}/#{spatial_version}-neo4j-#{neo4j_version}/neo4j-spatial-#{spatial_version}-neo4j-#{neo4j_version}-server-plugin.jar?raw=true")
      system_or_fail("mv neo4j-spatial-#{spatial_version}-neo4j-#{neo4j_version}-server-plugin.jar ./db/neo4j/development/plugins")
    end
  end
end

task default: ['spec']
