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
    raise ArgumentError, 'Missing NEO4J_VERSION or NEO4J_SPATIAL_VERSION' unless neo4j_version || spatial_version
    if neo4j_version[0].to_i < 3
      file_name = "neo4j-spatial-#{spatial_version}-neo4j-#{neo4j_version}-server-plugin.zip"
      system_or_fail("wget #{url}/#{spatial_version}-neo4j-#{neo4j_version}/#{file_name}?raw=true #{file_name}")
      system_or_fail("unzip #{file_name} -d ./db/neo4j/development/plugins")
    else
      file_name = "neo4j-spatial-#{spatial_version}-neo4j-#{neo4j_version}-server-plugin.jar"
      system_or_fail("wget #{url}/#{spatial_version}-neo4j-#{neo4j_version}/#{file_name}?raw=true #{file_name}")
      system_or_fail("mv #{file_name} ./db/neo4j/development/plugins")
    end
  end
end

task default: ['spec']
