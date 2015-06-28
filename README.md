# Neo4jrbSpatial

Provides support for Neo4j Spatial to Neo4j.rb 5+.

It is more or less a Neo4j.rb-flavored implementation of [Max De Marzi](https://github.com/maxdemarzi)'s
[code](https://github.com/maxdemarzi/neography/blob/46be2bb3c66aea14e707b1e6f82937e65f686ccc/lib/neography/rest/spatial.rb) from
[Neography](https://github.com/maxdemarzi/neography).

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

# neo4j gem/ActiveNode can omit the line above, just do
require 'neo4j/active_node/spatial'
```

## Basics - Neo4j-core

```
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

## Additional Resources

Check out the specs and the code for help, it's rather straightforward.

[Max's blog post](http://maxdemarzi.com/2014/01/31/neo4j-spatial-part-1/) on using Neography with Spatial
mostly works for an idea of the basics, just replace Neography-specific commands with their Neo4j-core versions.
