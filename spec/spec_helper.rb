$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rspec'
require 'pry'
require 'json'
require 'neo4j-core'
require 'neo4j'
require 'neo4jrb_spatial'
require 'neo4j/core/cypher_session/adaptors/http'

def server_url
  ENV['NEO4J_URL'] || 'http://localhost:7474'
end

def current_session
  @current_session ||= begin
    neo4j_adaptor = Neo4j::Core::CypherSession::Adaptors::HTTP.new(server_url)
    session = Neo4j::Core::CypherSession.new(neo4j_adaptor)
    Neo4j::ActiveBase.current_session = session
  end
end

def create_db_constraint
  Neo4j::ActiveBase.label_object(:Restaurant).create_constraint(:uuid, type: :unique)
end

RSpec.configure do |c|
  c.before(:suite) do
    current_session.query('MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n, r')
    create_db_constraint
  end

  c.before do
  end

  c.after(:each) do
  end
end
