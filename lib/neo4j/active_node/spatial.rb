module Neo4j
  module ActiveNode
    module Spatial
      extend ActiveSupport::Concern

      SpatialLayer = Struct.new(:name, :type, :config)

      included do
        def add_to_spatial_layer(layer_name = nil)
          layer = layer_name || self.class.spatial_layer.name
          fail 'layer name not found' unless layer

          Neo4j::ActiveBase.current_session.add_node_to_layer(layer, self)
        end

        class << self
          attr_reader :spatial_layer

          def spatial_layer(layer_name = nil, options = {})
            @spatial_layer ||= SpatialLayer.new(layer_name, options.fetch(:type, 'SimplePoint'), options.fetch(:config, 'lon:lat'))
          end

          def create_layer
            fail 'layer not found' unless spatial_layer.name

            lon_name, lat_name = spatial_layer.config.split(':')

            Neo4j::ActiveBase.current_session.add_layer(spatial_layer.name, spatial_layer.type, lat_name, lon_name)
          end

          def remove_layer
            fail 'layer not found' unless spatial_layer.name

            Neo4j::ActiveBase.current_session.remove_layer(spatial_layer.name)
          end
        end

        scope :within_distance, ->(coordinate, distance, layer_name = nil) do
          layer = model.spatial_layer.name || layer_name

          Neo4j::ActiveBase.current_session
            .within_distance(layer, coordinate, distance, execute: false)
            .proxy_as(model, :node)
        end

        scope :bbox, ->(min, max, layer_name = nil) do
          layer = model.spatial_layer.name || layer_name

          Neo4j::ActiveBase.current_session
            .bbox(layer, min, max, execute: false)
            .proxy_as(model, :node)
        end

        scope :closest, ->(coordinate, distance = 100, layer_name = nil) do
          layer = model.spatial_layer.name || layer_name

          Neo4j::ActiveBase.current_session
            .closest(layer, coordinate, distance, execute: false)
            .proxy_as(model, :node)
        end

        scope :intersects, ->(geometry, layer_name = nil) do
          layer = model.spatial_layer.name || layer_name

          Neo4j::ActiveBase.current_session
            .intersects(layer, geometry, execute: false)
            .proxy_as(model, :node)
        end
      end
    end
  end
end
