# Change Log
All notable changes to this project will be documented in this file.
This file should follow the standards specified on [http://keepachangelog.com/]
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased][unreleased]

## [2.0.0] - 2017-06-23

### Changed

- Support for Neo4j 3.x, version 8.0 of the `neo4j` gem, and version 7.x of the `neo4j-core` gem (see #18 / thanks @TyGuy)
- NOTE: This version may be incompatible with version of the `neo4j` gem below 8.x and versions of the `neo4j-core` gem below 7.x

## [1.2.0] - 2016-09-26

### Fixed

- Compatibility with `neo4j-core ~> 6.1.4` (see #13)
- Some module nesting issues (see #10)
- Travis setup (see #13)

## [1.1.0] - 2015-10-15

### Fixed

- Problems with gem config were preventing installation. Relaxed versioning requirements.
- Rake tasks were moved out of Neo4j-core, so added the `neo4j-rake_tasks` gem to keep this ship sailing.

## [1.0.0] - 2015-06-TBD

### Added
- Everything. It's all new.
