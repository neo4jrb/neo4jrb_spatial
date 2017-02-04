require 'spec_helper'

describe Neo4j::Core::Spatial do
  let(:neo) { current_session }

  describe 'find the spatial plugin' do
    it 'can get a description of the spatial plugin' do
      expect(neo.spatial?).to eq(true)

      procedures = neo.spatial_plugin
      expect(procedures).not_to be_nil
      expect(procedures).to include('spatial.addWKTLayer')
    end
  end

  describe 'add a point layer' do
    it 'can add a simple point layer' do
      response = neo.add_point_layer('restaurants')
      pl = response.first

      expect(pl.props[:layer]).to eq('restaurants')
      expect(pl.props[:geomencoder_config]).to eq('lon:lat')
    end

    it 'can add a simple point layer with lat and long' do
      response = neo.add_point_layer('coffee_shops', 'latitude', 'longitude')
      pl = response.first

      expect(pl.props[:layer]).to eq('coffee_shops')
      expect(pl.props[:geomencoder_config]).to eq('longitude:latitude')
    end
  end

  describe 'add an editable layer' do
    it 'can add an editable layer' do
      response = neo.add_editable_layer('zipcodes', 'WKT', 'wkt')
      el = response.first
      expect(el).not_to be_nil
      expect(el.props[:layer]).to eq('zipcodes')
      expect(el.props[:geomencoder_config]).to eq('wkt')
    end
  end

  describe 'get a spatial layer' do
    it 'can get a layer' do
      # TODO: should this just return one node instead of array?
      sl = neo.get_layer('restaurants').first
      expect(sl).not_to be_nil
      expect(sl.props[:layer]).to eq('restaurants')
    end
  end

  describe 'add_layer' do
    it 'works when passed WKT type' do
      layer = neo.add_layer('testaurants', 'WKT').first

      expect(layer.props[:layer]).to eq('testaurants')
      expect(layer.props[:layer_class]).to match('EditableLayerImpl')
      expect(layer.props[:geomencoder]).to match('WKTGeometryEncoder')
      expect(layer.props[:geomencoder_config]).to eq('lon:lat')
    end

    it 'works when passed WKB type' do
      layer = neo.add_layer('bestaurants', 'WKB').first

      expect(layer.props[:layer]).to eq('bestaurants')
      expect(layer.props[:layer_class]).to match('EditableLayerImpl')
      expect(layer.props[:geomencoder]).to match('WKBGeometryEncoder')
      expect(layer.props[:geomencoder_config]).to eq('lon:lat')
    end
  end

  describe 'create a spatial index' do
    it 'can create a spatial index' do
      layer = neo.create_spatial_index('layer_pretending_to_be_index').first
      expect(layer.props[:geomencoder_config]).to eq('lon:lat')
      expect(layer.props[:layer_class]).to match('SimplePointLayer')
      expect(layer.props[:layer]).to eq('layer_pretending_to_be_index')
    end
  end

  describe 'add geometry to spatial layer' do
    it 'can add a geometry' do
      geometry = 'LINESTRING (15.2 60.1, 15.3 60.1)'
      geo = neo.add_geometry_to_layer('zipcodes', geometry)
      expect(geo).not_to be_nil
      expect(geo.first.props[:wkt]).to eq(geometry)
    end
  end

  describe 'update geometry from spatial layer' do
    it 'can update a geometry' do
      geometry = 'LINESTRING (15.2 60.1, 15.3 60.1)'
      geo = neo.add_geometry_to_layer('zipcodes', geometry)
      expect(geo).not_to be_nil
      expect(geo.first.props[:wkt]).to eq(geometry)
      geometry = 'LINESTRING (14.7 60.1, 15.3 60.1)'
      existing_geo = neo.edit_geometry_from_layer('zipcodes', geometry, geo)
      expect(existing_geo.first.props[:wkt]).to eq(geometry)
      expect(existing_geo.first.neo_id.to_i).to eq(geo.first.neo_id.to_i)
    end
  end

  describe 'add a node to a layer' do
    it 'can add a node to a simple point layer' do
      properties = {name: "Max's Restaurant", lat: 41.8819, lon: 87.6278}
      node_query = Neo4j::Core::Query.new(session: neo).create(n: {Restaurant: properties}).return(:n)
      node = neo.query(node_query).first.n

      expect(node).not_to be_nil
      added = neo.add_node_to_layer('restaurants', node)
      expect(added.first.props[:lat]).to eq(properties[:lat])
      expect(added.first.props[:lon]).to eq(properties[:lon])
    end
  end

  describe 'find geometries in a bounding box' do
    it 'can find a geometry in a bounding box' do
      properties = {name: "Max's Restaurant", lat: 41.8819, lon: 87.6278}
      nodes = neo.find_geometries_in_bbox('restaurants', 87.5, 87.7, 41.7, 41.9)
      expect(nodes).not_to be_empty
      result = nodes.find { |node| node.props[:name] == "Max's Restaurant" }
      expect(result.props[:lat]).to eq(properties[:lat])
      expect(result.props[:lon]).to eq(properties[:lon])
    end
  end

  describe 'find geometries within distance' do
    it 'can find a geometry within distance' do
      properties = {name: "Max's Restaurant", lat: 41.8819, lon: 87.6278}
      nodes = neo.find_geometries_within_distance('restaurants', 87.627, 41.881, 10)
      expect(nodes).not_to be_empty
      result = nodes.find { |node| node.props[:name] == "Max's Restaurant" }
      expect(result.props[:lat]).to eq(properties[:lat])
      expect(result.props[:lon]).to eq(properties[:lon])
    end
  end

  # TODO: find small shapefile to do this with.
  # describe 'importing shapefile' do
  #   it 'works' do
  #     layer = neo.add_editable_layer('cities', 'WKT', 'wkt')
  #     filepath = "#{File.dirname(__FILE__)}/../cities/Cities2015.shp"
  #
  #     abc = neo.import_shapefile_to_layer('cities', filepath)
  #     binding.pry
  #   end
  # end

  describe 'ActiveNode integration' do
    let(:node) { Restaurant.create(name: "Chris's Restauarant", lat: 60.1, lon: 15.2) }
    let(:outside_node) { Restaurant.create(name: 'Lily Thai', lat: 59.0, lon: 14.9) }

    class Restaurant
      include Neo4j::ActiveNode
      include Neo4j::ActiveNode::Spatial

      spatial_index 'restaurants'
      property :name
      property :lat
      property :lon
    end

    before do
      Restaurant.delete_all
      [node, outside_node].each(&:add_to_spatial_index)
    end

    # let(:match) { Restaurant.all.spatial_match(:r, 'withinDistance:[60.0,15.0,100.0]') }
    let(:match) { Restaurant.all.within_distance(60.0, 15.0, 100.0) }

    it 'is a QueryProxy' do
      expect(match).to respond_to(:to_cypher)
    end

    it 'matches to the node in the spatial index' do
      expect(match.first).to eq node
    end

    it 'only returns expected nodes' do
      expect(match.to_a).not_to include(outside_node)
    end
  end
end
