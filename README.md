# Neo4jrbSpatial

Provides support for Neo4j Spatial to Neo4j.rb 5+.

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


## Require it

```
# neo4j-core only?
require 'neo4j/spatial'

# neo4j gem/ActiveNode can omit the line above, just include the module in your model
include Neo4j::ActiveNode::Spatial
```

## Basics - Neo4j-core

**NOTE**
At the moment, this gem might not work without the Neo4j gem also included. Will be fixed soon.

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

## Basics - Neo4j gem

 Neo4j.rb does not support legacy indexes, so a helper method is provided to add nodes. As with normal properties, your lat and lon
 should be explicitly declared.
 
### Automatic index addition

At the moment, automatic index addition is not implemented.

### Manual index addition

All of the Neo4j-core spatial methods accept ActiveNode-including nodes, so you can use them as arguments for all defined methods as you would
Neo4j::Server::CypherNode instances.

Additionally, you can call the `add_to_spatial_index` instance method on any node to add it to its model's defined index.

### Spatial queries

No helpers are provided to query against the REST API -- you'll need to use the ones provided for Neo4j-core; however, a class method is provided 
to make Cypher queries easier: `spatial_match`.

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
 
 Alternatively, if you did no define `spatial_index` on your model, you can feed a third argument: the index to use for the query.

## Additional Resources

Check out the specs and the code for help, it's rather straightforward.

[Max's blog post](http://maxdemarzi.com/2014/01/31/neo4j-spatial-part-1/) on using Neography with Spatial
mostly works for an idea of the basics, just replace Neography-specific commands with their Neo4j-core versions.

## Contributions

Pull requests and maintanence help would be swell. In addition to being fully tested, please ensure rubocop passes by running `rubocop` from the CLI. 
