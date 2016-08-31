$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rspec'
require 'json'
require 'neo4j-core'
require 'neo4j'
require 'neo4jrb_spatial'

def server_url
  ENV['NEO4J_URL'] || 'http://localhost:7474'
end

def create_server_session
  Neo4j::Session.open(:server_db, server_url)
end

def clear_model_memory_caches
  Neo4j::ActiveRel::Types::WRAPPED_CLASSES.clear
  Neo4j::ActiveNode::Labels::WRAPPED_CLASSES.clear
  Neo4j::ActiveNode::Labels.clear_wrapped_models
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

  c.after(:each) do
    clear_model_memory_caches
  end
end
