# Dubins.jl

Release: [![](https://img.shields.io/badge/docs-stable-blue.svg)](https://kaarthiksundar.github.io/Dubins.jl/stable/)

Dev: [![Build Status](https://travis-ci.org/kaarthiksundar/Dubins.jl.svg?branch=master)](https://travis-ci.org/kaarthiksundar/Dubins.jl)
[![codecov](https://codecov.io/gh/kaarthiksundar/Dubins.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/kaarthiksundar/Dubins.jl)
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://kaarthiksundar.github.io/Dubins.jl/latest/)

Dubins.jl is a Julia package for computing the shortest path between two configurations for the Dubins' vehicle (see [Dubins, 1957](http://www.jstor.org/stable/2372560?seq=1#page_scan_tab_contents)). The shortest path algorithm, implemented in this package, uses the algebraic solution approach in the paper "[Classification of the Dubins set](https://www.sciencedirect.com/science/article/pii/S0921889000001275)" by Andrei M. Shkel and Vladimir Lumelsky.

All the unit tests and the data structures in this Julia implementation is borrowed from the [C implementation](https://github.com/AndrewWalker/Dubins-Curves) and its corresponding [python wrapper](https://github.com/AndrewWalker/pydubins).

## Bugs and support
Please report any issues or feature requests via the Github [issue tracker].

[issue tracker]: https://github.com/kaarthiksundar/Dubins.jl/issues

## Documentation
The detailed API documentation with examples can be found [here](https://kaarthiksundar.github.io/Dubins.jl/latest/).

## License
MIT License. See LICENSE file for details.
