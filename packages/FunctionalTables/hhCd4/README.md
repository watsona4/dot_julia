# FunctionalTables

![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)<!--
![Lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-stable-green.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-retired-orange.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-archived-red.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-dormant-blue.svg) -->
[![Build Status](https://travis-ci.org/tpapp/FunctionalTables.jl.svg?branch=master)](https://travis-ci.org/tpapp/FunctionalTables.jl)
[![codecov.io](http://codecov.io/github/tpapp/FunctionalTables.jl/coverage.svg?branch=master)](http://codecov.io/github/tpapp/FunctionalTables.jl?branch=master)

Julia package for working with (potentially large) columns of data.

# Design

A *table* is a collection of *columns*, indexed by `Symbol`s.

Columns are *immutable*, which allows compression and type narrowing when applicable. Columns do not support random access, just `iterate`.

Columns are created by collecting elements into *sinks*, which are then finalized. While being collected into, sinks can change representation, eg decide whether to use RLE or other compression schemes, `mmap` to disk for large data, etc --- these can be configured and ideally ignored by the user.

`NamedTuple`s are used pervasively throughout the interface.

# Status

Heavily experimental, API changes radically without warnings or deprecations. This primarily an experiment, the package will be registered if it works out.
