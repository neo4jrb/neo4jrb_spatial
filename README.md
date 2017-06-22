# Neo4jrbSpatial

Provides support for Neo4j Spatial to Neo4j.rb 5+.

## Code Status

[![Build Status](https://secure.travis-ci.org/neo4jrb/neo4jrb_spatial.png?branch=master)](http://travis-ci.org/neo4jrb/neo4jrb_spatial)

## Introduction

It was originally more or less a Neo4j.rb-flavored implementation of [Max De Marzi](https://github.com/maxdemarzi)'s
[code](https://github.com/maxdemarzi/neography/blob/46be2bb3c66aea14e707b1e6f82937e65f686ccc/lib/neography/rest/spatial.rb) from
[Neography](https://github.com/maxdemarzi/neography).

Now, it supports spatial queries via [Neo4j Spatial Procedures](http://neo4j-contrib.github.io/spatial/#spatial-procedures).

For support, open an issue or say hello through [Gitter](https://gitter.im/neo4jrb/neo4j).

## What it provides

* Basic layer management
* Basic node-to-layer management
* Hooks for Neo4j::ActiveNode::Query::QueryProxy models if you are using them

Clearly, a huge debt is owed to [Max De Marzi](https://github.com/maxdemarzi) for doing all the hard work.

## Requirements

* Neo4j-core 7.0+
* Neo4j Server 3.0+ (earlier versions WILL NOT WORK)
* Ruby MRI 2.2.2+
* Compatible version of [Neo4j Spatial](https://github.com/neo4j-contrib/spatial)

Optionally:

* v8.0.6+ of the [Neo4j gem](https://github.com/neo4jrb/neo4j)

# Usage

## Add it

```
gem 'neo4jrb_spatial', '~> 1.0.0'
```

You can also install neo4j_spatial via a rake task, assuming you already have neo4j installed (see [Rake Tasks](## Rake tasks:) below).

## Require it

```
# neo4j-core only?
require 'neo4j/spatial'

# neo4j gem/ActiveNode can omit the line above, just include the module in your model
include Neo4j::ActiveNode::Spatial
```

## Use it with Neo4j-core

```ruby
# Create a session object
require 'neo4j/core/cypher_session/adaptors/http'

neo4j_adaptor = Neo4j::Core::CypherSession::Adaptors::HTTP.new('http://localhost:7474')
session = Neo4j::Core::CypherSession.new(neo4j_adaptor)

# Create a spatial layer
session.add_layer('restaurants')

# Create a node
properties = {name: "Indie Cafe", lat: 41.990326, lon: -87.672907}
node_query = Neo4j::Core::Query.new(session: session).create(n: {Restaurant: properties}).return(:n)
node = session.query(node_query).first.n

# Add a node to the layer
session.add_node_to_layer('restaurants', node)

# Look for nodes within distance:
session.within_distance('restaurants', {lat: 41.99022, lon: -87.6720}, 30).map do |node|
  node.props[:name] # node is an instance of Neo4j::Core::Node
end # => ['Indie Cafe']

# Spatial queries also supported: #bbox, #intersects, #closest.
# See spec/neo4jrb_spatial_spec.rb for examples.
```

## Use it with the Neo4j gem

 Neo4j.rb does not support legacy indexes, so adding nodes to spatial indexes needs to happen separately from node creation. This is complicated by the fact that Neo4j.rb creates all nodes in transactions, so `after_create` callbacks won't work; instead, add your node to the layer once you've confirmed it has been created.

 Start by adding `lat` and `lon` properties to your model. You can also add a `spatial_layer` to save yourself some time later.

 ```ruby
 class Restaurant
   include Neo4j::ActiveNode
   include Neo4j::ActiveNode::Spatial

   # This is optional but might make things easier for you later
   spatial_layer 'restaurants'

   property :name
   property :lat
   property :lon
 end

 # Create the layer
 Restaurant.create_layer

 # Create it
 pizza_hut = Restaurant.create(name: 'Pizza Hut', lat: 60.1, lon: 15.1)

 # When called without an argument, it will use the value set through `spatial_index` in the model
 pizza_hut.add_to_spatial_layer

 # Alternatively, to add it to a different index, just give it that name
 pizza_hut.add_to_spatial_layer('fake_pizza_places')
 ```

### Spatial queries

Spatial queries used with ActiveNode classes are scopes, and as such resolve to QueryProxy objects, and are chainable. For example, if you had an `employees` association defined in your model:

```ruby
# Find all restaurants within the specified distance, then find their employees who are age 30
Restauarant.within_distance({lat: 60.08, lon: 15.09}, 10).employees.where(age: 30)
```

If you did not define `spatial_layer` on your model, or want to query against something other than the model's default, you can feed a third argument: the layer name to use for the query.

#### `#bbox`

```ruby
# find all restaurants within the bounding box created by the given points:
min = { lat: 59.9, lon: 14.9 }
max = { lat: 60.2, lon: 15.3 }
Restaurant.bbox(min, max)
```

#### `#within_distance`

```ruby
# find all restaurants within 10km of the given point:
Restauarant.within_distance({lat: 60.08, lon: 15.09}, 10)
```

#### `intersects`

```ruby
# find all restaurants that intersect the given geometry:
geom = 'POLYGON ((15.3 60.1, 15.3 58.9, 14.8 58.9, 14.8 60.1, 15.3 60.1))'
Restauarant.intersects(geom)
```

## Rake tasks:

#### `bundle exec rake neo4j_spatial:install`

usage: `NEO4J_VERSION='3.0.4' bundle exec rake neo4j_spatial:install[<env>]`
If no `env` argument is provided, this defaults to 'development'

## Additional Resources

Check out the specs and the code for help, it's rather straightforward.

[Max's blog post](http://maxdemarzi.com/2014/01/31/neo4j-spatial-part-1/) on using Neography with Spatial
mostly works for an idea of the basics, just replace Neography-specific commands with their Neo4j-core versions.

## Contributions

Pull requests and maintanence help would be swell. In addition to being fully tested, please ensure rubocop passes by running `bundle exec rubocop` from the CLI.

### Running Tests:

Make sure your neo4j server is running (and catch it like a fridge!):
`bundle exec rake neo4j:start`

run the test suite:
`bundle exec rake spec` or `bundle exec rspec spec`

NOTE that if your NEO4J_URL is not the default, you will have to prefix while running migrate: `NEO4J_URL='http://localhost:7123' bundle exec rake spec`
