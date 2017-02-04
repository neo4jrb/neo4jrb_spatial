require 'net/http'

def system_or_fail(command)
  system(command) || exit(1)
end

namespace :neo4j_spatial do
  def match_version?(version, max_version)
    min_version = max_version.split('.')[0..-1].join('.')
    Gem::Version.new(version) <= Gem::Version.new(max_version) &&
      Gem::Version.new(version) >= Gem::Version.new(min_version)
  end

  def matching_version(version)
    uri = 'https://raw.githubusercontent.com/neo4j-contrib/m2/master/releases/org/neo4j/neo4j-spatial/maven-metadata.xml'
    versions = Net::HTTP.get_response(URI.parse(uri)).body
    versions = versions.scan(/<version>([a-z\-0-9\.]+)<\/version>/)
    versions.map! { |e| e.first.split('-neo4j-') }
    versions.select { |e| match_version?(version, e.last) }.last
  end

  desc 'install neo4j_spatial into /db/neo4j/[env]/plugins'
  task :install, :environment do |_, args|
    args.with_defaults(environment: 'development')
    puts "Install Neo4j Spatial (#{args[:environment]} environment)..."

    url = 'https://github.com/neo4j-contrib/m2/blob/master/releases/org/neo4j/neo4j-spatial'
    input_version = ENV['NEO4J_VERSION']
    fail ArgumentError, 'Missing NEO4J_VERSION' unless input_version
    spatial_version, neo4j_version = *matching_version(input_version)

    install_path = "db/neo4j/#{args[:environment]}/plugins"

    if neo4j_version[0].to_i < 3
      file_name = "neo4j-spatial-#{spatial_version}-neo4j-#{neo4j_version}-server-plugin.zip"
      system_or_fail("wget -O #{file_name} #{url}/#{spatial_version}-neo4j-#{neo4j_version}/#{file_name}?raw=true")
      system_or_fail("unzip #{file_name} -d #{install_path}")
    else
      file_name = "neo4j-spatial-#{spatial_version}-neo4j-#{neo4j_version}-server-plugin.jar"
      system_or_fail("wget -O #{file_name} #{url}/#{spatial_version}-neo4j-#{neo4j_version}/#{file_name}?raw=true")
      system_or_fail("mv #{file_name} #{install_path}")
    end
  end
end
