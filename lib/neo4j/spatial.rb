module Neo4j::Server
  module Spatial
    def spatial?
      Neo4j::Session.current.connection.get('/db/data/ext/SpatialPlugin').status == 200
    end

    def spatial_plugin
      Neo4j::Session.current.connection.get('/db/data/ext/SpatialPlugin').body
    end

    def add_point_layer(layer, lat = nil, lon = nil)
      options = {
        layer: layer,
        lat: lat || 'lat',
        lon: lon || 'lon'
      }

      spatial_post('/ext/SpatialPlugin/graphdb/addSimplePointLayer', options)
    end

    def add_editable_layer(layer, format = 'WKT', node_property_name = 'wkt')
      options = {
        layer: layer,
        format: format,
        nodePropertyName: node_property_name
      }

      spatial_post('/ext/SpatialPlugin/graphdb/addEditableLayer', options)
    end

    def get_layer(layer)
      options = {
        layer: layer
      }
      spatial_post('/ext/SpatialPlugin/graphdb/getLayer', options)
    end

    def add_geometry_to_layer(layer, geometry)
      options = {
        layer: layer,
        geometry: geometry
      }
      spatial_post('/ext/SpatialPlugin/graphdb/addGeometryWKTToLayer', options)
    end

    def edit_geometry_from_layer(layer, geometry, node)
      options = {
        layer: layer,
        geometry: geometry,
        geometryNodeId: get_id(node)
      }
      spatial_post('/ext/SpatialPlugin/graphdb/updateGeometryFromWKT', options)
    end

    def add_node_to_layer(layer, node)
      options = {
        layer: layer,
        node: "#{resource_url}node/#{node.neo_id}"
      }
      spatial_post('/ext/SpatialPlugin/graphdb/addNodeToLayer', options)
    end

    def find_geometries_in_bbox(layer, minx, maxx, miny, maxy)
      options = {
        layer: layer,
        minx: minx,
        maxx: maxx,
        miny: miny,
        maxy: maxy
      }
      spatial_post('/ext/SpatialPlugin/graphdb/findGeometriesInBBox', options)
    end

    def find_geometries_within_distance(layer, pointx, pointy, distance)
      options = {
        layer: layer,
        pointX: pointx,
        pointY: pointy,
        distanceInKm: distance
      }
      spatial_post('/ext/SpatialPlugin/graphdb/findGeometriesWithinDistance', options)
    end

    def create_spatial_index(name, type = nil, lat = nil, lon = nil)
      options = {
        name: name,
        config: {
          provider: 'spatial',
          geometry_type: type || 'point',
          lat: lat || 'lat',
          lon: lon || 'lon'
        }
      }
      spatial_post('/index/node', options)
    end

    def add_node_to_spatial_index(index, node)
      options = {
        uri: "/#{get_id(node)}",
        key: 'k',
        value: 'v'
      }
      spatial_post("/index/node/#{index}", options)
    end

    private

    def spatial_post(path, options)
      Neo4j::Session.current.connection.post("/db/data/#{path}", options).body
    end

    def get_id(id)
      case id
      when Neo4j::Server::CypherNode
        id.neo_id
      when Array
        get_id(id.first)
      when Hash
        id[:self].split('/').last
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
