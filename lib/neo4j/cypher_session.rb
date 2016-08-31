module Neo4j
  module Core
    module Spatial
      module CypherSession
        %w(
          spatial?
          spatial_plugin
          add_point_layer
          add_editable_layer
          get_layer
          add_geometry_to_layer
          edit_geometry_from_layer
          add_node_to_layer
          find_geometries_in_bbox
          find_geometries_within_distance
          create_spatial_index
          add_node_to_spatial_index
        ).each do |method, &_block|
          define_method(method) do |*args, &block|
            @adaptor.send(method, *args, &block)
          end
        end
      end
    end
  end
end

Neo4j::Core::CypherSession.__send__(:include, Neo4j::Core::Spatial::CypherSession)
