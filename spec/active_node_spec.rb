describe 'ActiveNode integration' do
  let(:node) { Restaurant.create(name: "Chris's Restaurant", lat: 60.1, lon: 15.2) }
  let(:outside_node) { Restaurant.create(name: 'Lily Thai', lat: 59.0, lon: 14.9) }
  before do
    stub_const('Restaurant', Class.new do
      include Neo4j::ActiveNode
      include Neo4j::ActiveNode::Spatial
      spatial_index 'restaurants'
      property :name
      property :lat
      property :lon
    end)

    Restaurant.delete_all
    [node, outside_node].each(&:add_to_spatial_index)
  end

  let(:match) { Restaurant.all.spatial_match(:r, 'withinDistance:[60.0,15.0,100.0]') }

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
