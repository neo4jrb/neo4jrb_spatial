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

module ActiveNodeRelStubHelpers
  def stub_active_node_class(class_name, with_constraint = true, &block)
    stub_const class_name, active_node_class(class_name, with_constraint, &block)
  end

  def stub_active_rel_class(class_name, &block)
    stub_const class_name, active_rel_class(class_name, &block)
  end

  def stub_named_class(class_name, superclass = nil, &block)
    stub_const class_name, named_class(class_name, superclass, &block)
    Neo4j::ModelSchema.reload_models_data!
  end

  def active_node_class(class_name, with_constraint = true, &block)
    named_class(class_name) do
      include Neo4j::ActiveNode

      module_eval(&block) if block
    end.tap { |model| create_id_property_constraint(model, with_constraint) }
  end

  def create_id_property_constraint(model, with_constraint)
    return if model.id_property_info[:type][:constraint] == false || !with_constraint

    create_constraint(model.mapped_label_name, model.id_property_name, type: :unique)
  end

  def active_rel_class(class_name, &block)
    named_class(class_name) do
      include Neo4j::ActiveRel

      module_eval(&block) if block
    end
  end

  def named_class(class_name, superclass = nil, &block)
    Class.new(superclass || Object) do
      @class_name = class_name
      class << self
        attr_reader :class_name
        alias_method :name, :class_name
        def to_s
          name
        end
      end

      module_eval(&block) if block
    end
  end

  def id_property_value(o)
    o.send o.class.id_property_name
  end

  def create_constraint(label_name, property, options = {})
    Neo4j::ActiveBase.label_object(label_name).create_constraint(property, options)
    Neo4j::ModelSchema.reload_models_data!
  end

  def create_index(label_name, property, options = {})
    Neo4j::ActiveBase.label_object(label_name).create_index(property, options)
    Neo4j::ModelSchema.reload_models_data!
  end
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

  c.include ActiveNodeRelStubHelpers, type: :active_model
end
