module Neo4j
  module Core
    module Spatial
      def spatial?
        spatial_procedures
        true
      rescue Neo4j::Core::CypherSession::CypherError
        false
      end

      def spatial_procedures
        query('CALL spatial.procedures() YIELD name').map(&:name)
      end

      def add_layer(name, type = nil, lat = nil, lon = nil)
        # supported names for type are: 'SimplePoint', 'WKT', 'WKB'
        type ||= 'SimplePoint'

        options = {
          name: name,
          type: type || 'point',
          encoderConfig: "#{lon || 'lon'}:#{lat || 'lat'}"
        }
        wrap_spatial_procedure('addLayer', options)
      end

      def remove_layer(name)
        options = {name: name}
        wrap_spatial_procedure('removeLayer', options, node: false)
      end

      def add_point_layer(layer)
        options = {layer: layer}

        wrap_spatial_procedure('addPointLayer', options)
      end

      def add_wkt_layer(layer, node_property_name = 'wkt')
        options = {
          layer: layer,
          node_property_name: node_property_name
        }

        wrap_spatial_procedure('addWKTLayer', options)
      end

      def get_layer(layer, execute: true)
        options = {layer: layer}
        wrap_spatial_procedure('layer', options, execute: execute)
      end

      def add_wkt(layer, geometry, execute: true)
        options = {
          layer: layer,
          geometry: geometry
        }
        wrap_spatial_procedure('addWKT', options, execute: execute)
      end

      def update_from_wkt(layer, geometry, node, execute: true)
        options = {
          layer: layer,
          geometry: geometry,
          geometryNodeId: get_id(node)
        }
        wrap_spatial_procedure('updateFromWKT', options, execute: execute)
      end

      # Hmmm this one has trouble, because we actually need to MATCH the node itself...
      # Wish this could be cleaner but for now it works...
      def add_node_to_layer(layer, node, execute: true)
        query_ = Query.new(session: self)
        procedure = query_.match(:n)
                    .where('id(n) = {node_id}')
                    .with(:n).call('spatial.addNode({layer}, n) YIELD node')
                    .return('node')
                    .params(layer: layer, node_id: node.neo_id)

        procedure = execute_and_format_response(procedure) if execute
        procedure
      end

      def bbox(layer, min, max, execute: true)
        options = {layer: layer, min: min, max: max}

        wrap_spatial_procedure('bbox', options, execute: execute)
      end
      alias_method :find_geometries_in_bbox, :bbox

      def within_distance(layer, coordinate, distance, execute: true)
        options = {
          layer: layer,
          coordinate: coordinate,
          distanceInKm: distance
        }

        wrap_spatial_procedure('withinDistance', options, execute: execute)
      end
      alias_method :find_geometries_within_distance, :within_distance

      def intersects(layer, geometry, execute: true)
        options = {layer: layer, geometry: geometry}

        wrap_spatial_procedure('intersects', options, execute: execute)
      end

      # TODO: figure out what closest is supposed to do...
      def closest(layer, coordinate, distance = 100, execute: true)
        options = {
          layer: layer,
          coordinate: coordinate,
          distanceInKm: distance
        }

        wrap_spatial_procedure('closest', options, execute: execute)
      end

      def import_shapefile_to_layer(layer, file_uri, execute: true)
        options = {layer: layer, file_uri: file_uri}
        execution_args = {execute: execute, node: false}

        wrap_spatial_procedure('importShapefileToLayer', options, execution_args)
      end

      protected

      def spatial_procedure(procedure_name, procedure_args, with_node = true)
        call_params = procedure_args.keys.map { |key| "{#{key}}" }.join(', ')
        call_query = "spatial.#{procedure_name}(#{call_params})"
        call_query += ' YIELD node' if with_node

        query_ = Query.new(session: self)
        query_.call(call_query).params(procedure_args)
      end

      def wrap_spatial_procedure(procedure_name, procedure_args, execution_args = {})
        execute = execution_args.fetch(:execute, true)
        node = execution_args.fetch(:node, true)

        procedure = spatial_procedure(procedure_name, procedure_args, node)

        procedure = execute_and_format_response(procedure) if execute
        procedure
      end

      def execute_and_format_response(procedure)
        procedure.response.map do |res|
          res.respond_to?(:node) ? res.node : res
        end
      end

      def get_id(id)
        return get_id(id.first) if id.is_a?(Array)
        id.neo_id
      end
    end

    class CypherSession
      include Spatial
    end
  end
end
