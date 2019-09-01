# Dubins.jl Documentation

```@meta
CurrentModule = Dubins
```
## Overview
Dubins.jl is a Julia package for computing the shortest path between two configurations for the Dubins' vehicle (see [Dubins, 1957](http://www.jstor.org/stable/2372560?seq=1#page_scan_tab_contents)). The shortest path algorithm, implemented in this package, uses the algebraic solution approach in the paper "[Classification of the Dubins set](https://www.sciencedirect.com/science/article/pii/S0921889000001275)" by Andrei M. Shkel and Vladimir Lumelsky.

## Installation
The latest release of Dubins can be installed using the Julia package manager with
```julia
Pkg.add("Dubins")
```
Test that the package works by running 
```julia
Pkg.test("Dubins")
```
