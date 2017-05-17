module Neo4j
  module ActiveNode
    module Spatial
      def self.included(other)
        other.extend(ClassMethods)
      end

      def add_to_spatial_layer(layer_name = nil)
        layer = layer_name || self.class.spatial_layer_name
        fail 'layer name not found' unless layer
        Neo4j::ActiveBase.current_session.add_node_to_layer(layer, self)
      end

      module ClassMethods
        attr_reader :spatial_layer_name
        attr_reader :spatial_layer_type
        attr_reader :spatial_layer_config

        def spatial_layer(layer_name = nil, options = {})
          return spatial_layer_name unless layer_name

          @spatial_layer_name = layer_name
          @spatial_layer_type = options.fetch(:type, 'SimplePoint')
          @spatial_layer_config = options.fetch(:config, 'lon:lat')

          spatial_layer_name
        end

        def create_layer
          fail 'layer name not found' unless spatial_layer_name

          lon_name, lat_name = spatial_layer_config.split(':')

          Neo4j::ActiveBase.current_session.add_layer(spatial_layer_name, spatial_layer_type, lat_name, lon_name)
        end

        def remove_layer
          fail 'layer name not found' unless spatial_layer_name

          Neo4j::ActiveBase.current_session.remove_layer(spatial_layer_name)
        end
      end
    end

    module Query
      class QueryProxy
        def within_distance(coordinate, distance, layer_name = nil)
          layer = model.spatial_layer_name || layer_name

          Neo4j::ActiveBase.current_session
            .within_distance(layer, coordinate, distance, execute: false)
            .proxy_as(model, :node)
        end

        def bbox(min, max, layer_name = nil)
          layer = model.spatial_layer_name || layer_name

          Neo4j::ActiveBase.current_session
            .bbox(layer, min, max, execute: false)
            .proxy_as(model, :node)
        end

        def closest(coordinate, distance = 100, layer_name = nil)
          layer = model.spatial_layer_name || layer_name

          Neo4j::ActiveBase.current_session
            .closest(layer, coordinate, distance, execute: false)
            .proxy_as(model, :node)
        end

        def intersects(geometry, layer_name = nil)
          layer = model.spatial_layer_name || layer_name

          Neo4j::ActiveBase.current_session
            .intersects(layer, geometry, execute: false)
            .proxy_as(model, :node)
        end
      end
    end
  end
end
