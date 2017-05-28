# Neo4jrbSpatial

Provides support for Neo4j Spatial to Neo4j.rb 5+.

## Code Status

[![Build Status](https://secure.travis-ci.org/neo4jrb/neo4jrb_spatial.png?branch=master)](http://travis-ci.org/neo4jrb/neo4jrb_spatial)

## Introduction

It is more or less a Neo4j.rb-flavored implementation of [Max De Marzi](https://github.com/maxdemarzi)'s
[code](https://github.com/maxdemarzi/neography/blob/46be2bb3c66aea14e707b1e6f82937e65f686ccc/lib/neography/rest/spatial.rb) from
[Neography](https://github.com/maxdemarzi/neography).

For support, open an issue or say hello through [Gitter](https://gitter.im/neo4jrb/neo4j).

## What it provides

* Basic index and layer management
* Basic node-to-index management
* Hooks for Neo4j::ActiveNode::Query::QueryProxy models if you are using them

It is powered by an implementation of [Neography's](https://github.com/maxdemarzi/neography) [spatial module](https://github.com/maxdemarzi/neography/blob/46be2bb3c66aea14e707b1e6f82937e65f686ccc/lib/neography/rest/spatial.rb).
Clearly, a huge debt is owed to [Max De Marzi](https://github.com/maxdemarzi) for doing all the hard work.

## Requirements

* Neo4j-core 5.0.1+
* Neo4j Server 2.2.2+ (earlier versions will likely work but are not tested)
* Ruby MRI 2.2.2+
* Compatible version of [Neo4j Spatial](https://github.com/neo4j-contrib/spatial)

Optionally:

* v5.0.1+ of the [Neo4j gem](https://github.com/neo4jrb/neo4j)

# Usage

## Add it

```
gem 'neo4jrb_spatial', '~> 1.0.0'
```

## Require it

```
# neo4j-core only?
require 'neo4j/spatial'

# neo4j gem/ActiveNode can omit the line above, just include the module in your model
include Neo4j::ActiveNode::Spatial
```

## Use it with Neo4j-core

```ruby
# Create an index
Neo4j::Session.current.create_spatial_index('restaurants')

# Create a node
node = Neo4j::Node.create({:name => "Indie Cafe", :lat => 41.990326, :lon => -87.672907 }, :Restaurant)

# Add a node to the index
Neo4j::Session.current.add_node_to_spatial_index('restaurants', node)

# Query around the index
Neo4j::Session.current.query.start('n = node:restaurants({location})').params(location: 'withinDistance:[41.99,-87.67,10.0]').pluck(:n)
# => CypherNode 90126 (70333884677220)
```

## Use it with the Neo4j gem

 Neo4j.rb does not support legacy indexes, so adding nodes to spatial indexes needs to happen separately from node creation. This is complicated by the fact that Neo4j.rb creates all nodes in transactions, so `after_create` callbacks won't work; instead, add your node to the index once you've confirmed it has been created.

 Start by adding `lat` and `lon` properties to your model. You can also add a `spatial_index` to save yourself some time later.

 ```
 class Restaurant
   include Neo4j::ActiveNode
   include Neo4j::ActiveNode::Spatial

   # This is optional but might make things easier for you later
   spatial_index 'restaurants'

   property :name
   property :lat
   property :lon
 end

 # Create it
 pizza_hut = Restaurant.create(name: 'Pizza Hut', lat: 60.1, lon: 15.1)

 # When called without an argument, it will use the value set through `spatial_index` in the model
 pizza_hut.add_to_spatial_index

 # Alternatively, to add it to a different index, just give it that name
 pizza_hut.add_to_spatial_index('fake_pizza_places')
 ```

### Manual index addition

All of the Neo4j-core spatial methods accept ActiveNode-including nodes, so you can use them as arguments for all defined methods as you would Neo4j::Server::CypherNode instances.

```ruby
Neo4j::Session.current.add_node_to_spatial_index('fake_pizza_places', pizza_hut)
```

### Spatial queries

No helpers are provided to query against the REST API -- you'll need to use the ones provided for Neo4j-core; however, a class method is provided to make Cypher queries easier: `spatial_match`.

```
# Use the index defined on the model as demonstrated above
Restaurant.all.spatial_match(:r, params_string)
# Generates:
# => "START r = node:restaurants({params_string})"
```

It then drops you back into a QueryProxy in the context of the class. If you had an `employees` association defined in your model:

 ```
 # Find all restaurants within the specified distance, then find their employees who are age 30
 Restauarant.all.spatial_match(:r, 'withinDistance:[41.99,-87.67,10.0]').employees.where(age: 30)
 ```

If you did no define `spatial_index` on your model or what to query against something other than the model's default, you can feed a third argument: the index to use for the query.

## Rake tasks:
#### `neo4j_spatial:install`

usage: `NEO4J_VERSION='3.0.4' rake neo4j_spatial:install[<env>]`
If no `env` argument is provided, this defaults to 'development'

## Additional Resources

Check out the specs and the code for help, it's rather straightforward.

[Max's blog post](http://maxdemarzi.com/2014/01/31/neo4j-spatial-part-1/) on using Neography with Spatial
mostly works for an idea of the basics, just replace Neography-specific commands with their Neo4j-core versions.

## Contributions

Pull requests and maintanence help would be swell. In addition to being fully tested, please ensure rubocop passes by running `rubocop` from the CLI.

### Running Tests:
`bundle exec rake spec` or `bundle exec rspec spec`

NOTE that if your NEO4J_URL is not the default, you will have to prefix while running migrate: `NEO4J_URL='http://localhost:7123' bundle exec rake spec`
