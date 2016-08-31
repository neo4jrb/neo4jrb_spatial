module Neo4j
  module ActiveNode
    module Spatial
      def self.included(other)
        other.extend(ClassMethods)
      end

      def add_to_spatial_index(index_name = nil)
        index = index_name || self.class.spatial_index_name
        fail 'index name not found' unless index
        ActiveBase.current_session.add_node_to_spatial_index(index, self)
      end

      module ClassMethods
        attr_reader :spatial_index_name
        def spatial_index(index_name = nil)
          return spatial_index_name unless index_name
          # create_index_callback(index_name)
          @spatial_index_name = index_name
        end

        # This will not work for now. Neo4j Spatial's REST API doesn't seem to work within transactions.
        # def create_index_callback(index_name)
        #   after_create(proc { |node| Neo4j::Session.current.add_node_to_spatial_index(index_name, node) })
        # end

        # private :create_index_callback
      end
    end

    module Query
      class QueryProxy
        def spatial_match(var, params_string, spatial_index = nil)
          index = model.spatial_index_name || spatial_index
          fail 'Cannot query without index. Set index in model or as third argument.' unless index
          Neo4j::ActiveBase.new_query
            .start("#{var} = node:#{index}({spatial_params})")
            .proxy_as(model, var)
            .params(spatial_params: params_string)
        end
      end
    end
  end
end
