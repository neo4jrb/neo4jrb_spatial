require 'spec_helper'

describe Neo4j::ActiveNode::Spatial do
  let(:neo) { current_session }
  let(:node) { Restaurant.create(name: "Chris's Restauarant", lat: 60.1, lon: 15.2) }
  let(:outside_node) { Restaurant.create(name: 'Lily Thai', lat: 59.0, lon: 14.9) }

  class Restaurant
    include Neo4j::ActiveNode
    include Neo4j::ActiveNode::Spatial

    spatial_layer 'restaurants' # , type: 'SimplePoint', config: 'lon:lat'
    property :name
    property :lat
    property :lon
  end

  before do
    Restaurant.delete_all
    Restaurant.create_layer
    [node, outside_node].each(&:add_to_spatial_layer)
  end

  after do
    Restaurant.remove_layer
  end

  # let(:match) { Restaurant.all.spatial_match(:r, 'withinDistance:[60.0,15.0,100.0]') }
  describe '#within_distance' do
    let(:match) { Restaurant.all.within_distance({lat: 60.0, lon: 15.0}, 100.0) }

    it 'is a QueryProxy' do
      expect(match).to respond_to(:to_cypher)
    end

    it 'returns nodes within the given distance of the point' do
      expect(match.first).to eq node
    end

    it 'only returns expected nodes' do
      expect(match.to_a).not_to include(outside_node)
    end
  end

  describe '#bbox' do
    let(:min) { {lat: 59.9, lon: 14.9} }
    let(:max) { {lat: 60.2, lon: 15.3} }
    let(:match) { Restaurant.all.bbox(min, max) }

    it 'returns nodes that are inside the given bbox' do
      nodes = match.to_a
      expect(nodes.count).to eq(1)
      expect(nodes.first).to eq(node)
    end

    it 'is chainable' do
      new_match = match.within_distance({lat: 60.0, lon: 15.0}, 100.0)

      expect(new_match).to respond_to(:to_cypher)
      expect(new_match.first).to eq(node)
    end
  end

  # describe '#closest' do
  #   # this point is closer to outside_node
  #   # let(:coordinate) { {lat: 59.1, lon: 15.0} }
  #   # let(:coordinate) { {lat: 60.0, lon: 15.1} }
  #   let(:match) { Restaurant.all.closest(coordinate) }
  #
  #   it 'returns the closest node first' do
  #     puts match.to_a
  #     # expect(match.count).to eq(1)
  #     expect(match.first).to eq(outside_node)
  #   end
  # end

  describe '#intersects' do
    let(:geom) { 'POLYGON ((15.3 60.1, 15.3 58.9, 14.8 58.9, 14.8 60.1, 15.3 60.1))' }
    let(:match) { Restaurant.all.intersects(geom) }

    it 'returns node that intersect the given geometry' do
      expect(match.count).to eq(2)

      expect(match).to include(node)
      expect(match).to include(outside_node)
    end
  end
end
