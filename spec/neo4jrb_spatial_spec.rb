require 'spec_helper'

describe Neo4j::Core::Spatial do
  let(:neo) { current_session }

  describe 'find the spatial plugin' do
    it 'can get a list of the spatial plugin procedures' do
      expect(neo.spatial?).to eq(true)

      procedures = neo.spatial_procedures
      expect(procedures).not_to be_nil
      expect(procedures).to include('spatial.addWKTLayer')
    end
  end

  describe 'adding a layer (and removing)' do
    describe '#add_layer' do
      it 'works when passed SimplePoint type' do
        layer = neo.add_layer('simple_layer', 'SimplePoint').first

        expect(layer.props[:layer]).to eq('simple_layer')
        expect(layer.props[:layer_class]).to match('SimplePointLayer')
        expect(layer.props[:geomencoder]).to match('SimplePointEncoder')
        expect(layer.props[:geomencoder_config]).to eq('lon:lat')

        neo.remove_layer('simple_layer')
      end

      it 'works when passed different lat and lon configs' do
        layer = neo.add_layer('simple_layer_config', 'SimplePoint', 'attitude', 'fortitude').first

        expect(layer.props[:layer]).to eq('simple_layer_config')
        expect(layer.props[:layer_class]).to match('SimplePointLayer')
        expect(layer.props[:geomencoder]).to match('SimplePointEncoder')
        expect(layer.props[:geomencoder_config]).to eq('fortitude:attitude')

        neo.remove_layer('simple_layer_config')
      end

      it 'works when passed WKT type' do
        layer = neo.add_layer('wkt_layer', 'WKT').first

        expect(layer.props[:layer]).to eq('wkt_layer')
        expect(layer.props[:layer_class]).to match('EditableLayerImpl')
        expect(layer.props[:geomencoder]).to match('WKTGeometryEncoder')
        expect(layer.props[:geomencoder_config]).to eq('lon:lat')

        neo.remove_layer('wkt_layer')
      end

      it 'works when passed WKB type' do
        layer = neo.add_layer('wkb_layer', 'WKB').first

        expect(layer.props[:layer]).to eq('wkb_layer')
        expect(layer.props[:layer_class]).to match('EditableLayerImpl')
        expect(layer.props[:geomencoder]).to match('WKBGeometryEncoder')
        expect(layer.props[:geomencoder_config]).to eq('lon:lat')

        neo.remove_layer('wkb_layer')
      end
    end

    describe '#add_point_layer' do
      it 'can add a simple point layer' do
        response = neo.add_point_layer('restaurants').first

        expect(response.props[:layer]).to eq('restaurants')
        neo.remove_layer('restaurants')
      end
    end

    describe '#add_wkt_layer' do
      it 'can add a wkt layer' do
        response = neo.add_wkt_layer('zipcodes', 'zone_area')
        el = response.first

        expect(el).not_to be_nil
        expect(el.props[:layer]).to eq('zipcodes')
        expect(el.props[:geomencoder_config]).to eq('zone_area')

        neo.remove_layer('zipcodes')
      end
    end
  end


  describe 'get a spatial layer' do
    it 'can get a layer' do
      neo.add_point_layer('restaurants')

      layer = neo.get_layer('restaurants').first
      expect(layer).not_to be_nil

      expect(layer.props[:layer]).to eq('restaurants')

      neo.remove_layer('restaurants')
    end
  end

  describe 'add geometry to spatial layer' do
    it 'can add a geometry' do
      neo.add_wkt_layer('zipcodes')

      geometry = 'LINESTRING (15.2 60.1, 15.3 60.1)'
      geo = neo.add_wkt('zipcodes', geometry)
      expect(geo).not_to be_nil
      expect(geo.first.props[:wkt]).to eq(geometry)

      neo.remove_layer('zipcodes')
    end
  end

  describe 'update geometry from spatial layer' do
    it 'can update a geometry' do
      neo.add_wkt_layer('zipcodes')

      geometry = 'LINESTRING (15.2 60.1, 15.3 60.1)'
      geo = neo.add_wkt('zipcodes', geometry)
      expect(geo).not_to be_nil
      expect(geo.first.props[:wkt]).to eq(geometry)
      geometry = 'LINESTRING (14.7 60.1, 15.3 60.1)'
      existing_geo = neo.update_from_wkt('zipcodes', geometry, geo)
      expect(existing_geo.first.props[:wkt]).to eq(geometry)
      expect(existing_geo.first.neo_id.to_i).to eq(geo.first.neo_id.to_i)
    end
  end

  describe '#add_node_to_layer' do
    it 'works' do
      neo.add_layer('restaurants')
      properties = {name: "Max's Restaurant", lat: 41.8819, lon: 87.6278}
      node_query = Neo4j::Core::Query.new(session: neo).create(n: {Restaurant: properties}).return(:n)
      node = neo.query(node_query).first.n

      expect(node).not_to be_nil
      added = neo.add_node_to_layer('restaurants', node)
      expect(added.first.props[:lat]).to eq(properties[:lat])
      expect(added.first.props[:lon]).to eq(properties[:lon])

      neo.remove_layer('restaurants')
    end
  end

  describe 'spatial matching queries' do
    let(:properties) { {name: "Max's Restaurant", lat: 41.8819, lon: 87.6278} }
    let(:node_query) { Neo4j::Core::Query.new(session: neo).create(n: {Restaurant: properties}).return(:n) }

    before do
      neo.add_layer('restaurants')
      node = neo.query(node_query).first.n
      neo.add_node_to_layer('restaurants', node)
    end

    after do
      neo.remove_layer('restaurants')
    end

    describe '#bbox (#find_geometries_in_bbox)' do
      it 'can find a geometry in a bounding box' do
        min = {lon: 87.5, lat: 41.7}
        max = {lon: 87.7, lat: 41.9}

        nodes = neo.find_geometries_in_bbox('restaurants', min, max)
        expect(nodes).not_to be_empty

        result = nodes.find { |n| n.props[:name] == "Max's Restaurant" }
        expect(result.props[:lat]).to eq(properties[:lat])
        expect(result.props[:lon]).to eq(properties[:lon])
      end
    end

    describe '#within_distance (#find_geometries_within_distance)' do
      it 'can find a geometry within distance' do
        nodes = neo.find_geometries_within_distance('restaurants', {lon: 87.627, lat: 41.881}, 10)
        expect(nodes).not_to be_empty

        result = nodes.find { |n| n.props[:name] == "Max's Restaurant" }
        expect(result.props[:lat]).to eq(properties[:lat])
        expect(result.props[:lon]).to eq(properties[:lon])
      end
    end

    describe '#intersects' do
      it 'returns nodes that intersect the given geometry' do
        geom = 'POLYGON ((87.5 41.7, 87.5 41.9, 87.7 41.9, 87.7 41.7, 87.5 41.7))'
        nodes = neo.intersects('restaurants', geom)
        expect(nodes.count).to eq(1)

        expect(nodes.first.props[:name]).to eq("Max's Restaurant")
      end
    end

    describe '#closest' do
      # TODO: poor test
      it 'returns the closest node to the given coordinate' do
        other_properties = {name: "Min's Restaurant", lat: 41.87, lon: 87.6}
        other_node_query = Neo4j::Core::Query.new(session: neo).create(n: {Restaurant: other_properties}).return(:n)
        neo.query(other_node_query).first.n

        coordinate = {lat: 41.89, lon: 87.63}

        closest = neo.closest('restaurants', coordinate).first
        expect(closest.props[:name]).to eq(properties[:name])
      end
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
end
