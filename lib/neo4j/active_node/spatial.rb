module Neo4j
  module ActiveNode
    module Spatial
      def self.included(other)
        other.extend(ClassMethods)
      end

      def add_to_spatial_index(index_name = nil)
        index = index_name || self.class.spatial_index_name
        fail 'index name not found' unless index
        Neo4j::ActiveBase.current_session.add_node_to_spatial_index(index, self)
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

    # TODO: here!!!!
    # Fix the thing to parse the params_string (on the right) and make it
    # work for one of the procedures (withinDistance, bbox, etc.)
    module Query
      class QueryProxy
        # def spatial_match_retro(var, params_string, spatial_index = nil)
        #   Neo4j::Session.current.query
        #     .start("#{var} = node:#{index}({spatial_params})")
        #     .proxy_as(model, var)
        #     .params(spatial_params: params_string)
        #
        # end

        def spatial_match(var, params, spatial_index = nil)
          index = model.spatial_index_name || spatial_index
          fail 'Cannot query without index. Set index in model or as third argument.' unless index

          if params.is_a?(String)
            # TODO: deprecation warning
            params = parse_retro_params(params)
          end

          # spatial.bbox
          # spatial.closest
          # spatial.intersects
          # spatial.withinDistance
        end

        def parse_retro_params(params)

        end

        def within_distance(lat, lon, distance, layer_name = nil)
          layer = model.spatial_index_name || layer_name

          Neo4j::ActiveBase.current_session
            .within_distance(layer, lon, lat, distance, execute: false)
            .proxy_as(model, :node)
        end
      end
    end
  end
end
