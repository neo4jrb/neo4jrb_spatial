module Neo4j
  module Core
    module Spatial
      def spatial?
        spatial_plugin
        true
      rescue Neo4j::Server::CypherResponse::ResponseError
        false
      end

      def spatial_plugin
        call_query = 'CALL spatial.procedures() YIELD name'

        query(call_query, {}).map(&:name)
      end

      def add_point_layer(layer, lat = nil, lon = nil, execute: true)
        options = {
          layer: layer,
          lon: lon || 'lon',
          lat: lat || 'lat'
        }

        wrap_spatial_procedure('addPointLayerXY', options, execute)
      end

      def spatial_procedure(procedure_name, procedure_args)
        call_params = procedure_args.keys.map { |key| "{#{key}}" }.join(', ')
        call_query = "spatial.#{procedure_name}(#{call_params}) YIELD node"

        query_ = Query.new(session: self)
        query_.call(call_query).params(procedure_args)
      end

      def wrap_spatial_procedure(procedure_name, procedure_args, execute = true)
        procedure = spatial_procedure(procedure_name, procedure_args)
        procedure = execute_and_format_response(procedure) if execute
        procedure
      end

      def execute_and_format_response(procedure)
        procedure.response.map(&:node)
      end

      def add_editable_layer(layer, format = 'WKT', node_property_name = 'wkt', execute: true)
        # UGH don't know how to handle non-WKT things. Is this necessary? Maybe...
        # TODO: remove old version that uses spatial_post
        if format == 'WKT'
          options = {
            layer: layer,
            node_property_name: node_property_name
          }

          wrap_spatial_procedure('addWKTLayer', options, execute)
        else
          options = {
            layer: layer,
            format: format,
            nodePropertyName: node_property_name
          }

          spatial_post('/ext/SpatialPlugin/graphdb/addEditableLayer', options)
        end
      end

      def get_layer(layer, execute: true)
        options = {layer: layer}
        wrap_spatial_procedure('layer', options, execute)
      end

      def add_geometry_to_layer(layer, geometry, execute: true)
        options = {
          layer: layer,
          geometry: geometry
        }
        wrap_spatial_procedure('addWKT', options, execute)
      end

      def edit_geometry_from_layer(layer, geometry, node, execute: true)
        options = {
          layer: layer,
          geometry: geometry,
          geometryNodeId: get_id(node)
        }
        wrap_spatial_procedure('updateFromWKT', options, execute)
      end

      # Hmmm this one has trouble, because we actually need to MATCH the node itself...
      # Wish this could be cleaner but for now it works...
      def add_node_to_layer(layer, node, execute: true)
        options = {
          layer: layer,
          node_id: node.neo_id
        }

        query_ = Query.new(session: self)
        procedure = query_.match(:n)
          .where('id(n) = {node_id}')
          .with(:n).call('spatial.addNode({layer}, n) YIELD node')
          .return('node')
          .params(options)

        procedure = execute_and_format_response(procedure) if execute
        procedure
      end

      def find_geometries_in_bbox(layer, minx, maxx, miny, maxy, execute: true)
        options = {
          layer: layer,
          min: {lon: minx, lat: miny},
          max: {lon: maxx, lat: maxy}
        }

        wrap_spatial_procedure('bbox', options, execute)
      end

      def find_geometries_within_distance(layer, pointx, pointy, distance, execute: true)
        warn_deprecated(name: __method__, preferred: 'within_distance')
        within_distance(layer, pointx, pointy, distance, execute: execute)
      end

      def within_distance(layer, pointx, pointy, distance, execute: true)
        options = {
          layer: layer,
          coordinate: {lon: pointx, lat: pointy},
          distanceInKm: distance
        }

        wrap_spatial_procedure('withinDistance', options, execute)
      end

      def add_layer(name, type = nil, lat = nil, lon = nil, execute: true)
        # supported names for type are: 'SimplePoint', 'WKT', 'WKB'
        type ||= 'SimplePoint'

        # Hmm should keep this or let it break?
        type = 'SimplePoint' if type == 'point'

        options = {
          name: name,
          type: type || 'point',
          encoderConfig: "#{lon || 'lon'}:#{lat || 'lat'}"
        }
        wrap_spatial_procedure('addLayer', options, execute)
      end

      def create_spatial_index(name, type = nil, lat = nil, lon = nil)
        warn_deprecated(name: __method__, preferred: 'add_layer')
        add_layer(name, type, lat, lon)
      end

      def add_node_to_spatial_index(index, node)
        warn_deprecated(name: __method__, preferred: 'add_node_to_layer')
        add_node_to_layer(index, node)
      end

      def import_shapefile_to_layer(layer, file_uri)
        options = {layer: layer, file_uri: file_uri}

        spatial_procedure('importShapefileToLayer', options)
      end

      private

      def warn_deprecated(name:, preferred:)
        puts "WARNING: method '#{name}' is deprecated. Please use #{preferred}, which does the same thing."
      end

      def spatial_post(path, options)
        parse_response! Neo4j::Session.current.connection.post("/db/data/#{path}", options).body
      end

      def parse_response!(response)
        request_error!(response[:exception], response[:message], response[:stack_trace]) if response.is_a?(Hash) && response[:exception]
        response
      end

      def request_error!(code, message, stack_trace)
        fail Neo4jrbSpatial::RequestError, <<-ERROR
          #{ANSI::CYAN}#{code}#{ANSI::CLEAR}: #{message}
          #{stack_trace}
        ERROR
      end

      def get_id(id)
        return id.neo_id if id.respond_to?(:neo_id)
        case id
        when Array
          get_id(id.first)
        when Hash
          id[:id]
        when String
          id.split('/').last
        else
          id
        end
      end
    end

    class CypherSession
      include Spatial
    end
  end
end
