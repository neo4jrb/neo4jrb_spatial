$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rspec'
require 'neo4j-core'
require 'neo4jrb_spatial'

def server_url
  ENV['NEO4J_URL'] || 'http://localhost:7474'
end

def create_server_session
  Neo4j::Session.open(:server_db, server_url)
end

RSpec.configure do |c|
  c.before(:suite) do
    create_server_session
    Neo4j::Session.current.query('MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n, r')
  end

  c.before do
    curr_session = Neo4j::Session.current
    curr_session.close if curr_session && !curr_session.is_a?(Neo4j::Server::CypherSession)
    Neo4j::Session.current || create_server_session
  end
end
