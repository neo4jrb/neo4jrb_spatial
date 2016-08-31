$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rspec'
require 'json'
require 'neo4j'
require 'neo4j-core'
require 'neo4jrb_spatial'

def server_url
  ENV['NEO4J_URL'] || 'http://localhost:7474'
end

def clear_model_memory_caches
  Neo4j::ActiveRel::Types::WRAPPED_CLASSES.clear
  Neo4j::ActiveNode::Labels::WRAPPED_CLASSES.clear
  Neo4j::ActiveNode::Labels.clear_wrapped_models
end

TEST_SESSION_MODE = RUBY_PLATFORM == 'java' ? :embedded : :http

session_adaptor = case TEST_SESSION_MODE
                  when :embedded
                    Neo4j::Core::CypherSession::Adaptors::Embedded.new(EMBEDDED_DB_PATH, impermanent: true, auto_commit: true, wrap_level: :proc)
                  when :http
                    server_url = ENV['NEO4J_URL'] || 'http://localhost:7474'
                    server_username = ENV['NEO4J_USERNAME'] || 'neo4j'
                    server_password = ENV['NEO4J_PASSWORD'] || 'neo4jrb rules, ok?'

                    basic_auth_hash = {username: server_username, password: server_password}

                    case URI(server_url).scheme
                    when 'http'
                      Neo4j::Core::CypherSession::Adaptors::HTTP.new(server_url, basic_auth: basic_auth_hash, wrap_level: :proc)
                    when 'bolt'
                      Neo4j::Core::CypherSession::Adaptors::Bolt.new(server_url, wrap_level: :proc) # , logger_level: Logger::DEBUG)
                    else
                      fail "Invalid scheme for NEO4J_URL: #{scheme} (expected `http` or `bolt`)"
                    end
                  end

Neo4j::ActiveBase.current_adaptor = session_adaptor

RSpec.configure do |c|
  c.before(:suite) do
    Neo4j::ActiveBase.current_session.query('MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n, r')
  end

  c.after(:each) do
    clear_model_memory_caches
  end
end
