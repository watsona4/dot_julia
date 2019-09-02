# JuliaPetra

JuliaPetra is an implmentation of [Trilinos's Petra Object Model](https://trilinos.github.io/data_service.html#trilinos-packages) in Julia.
It is a basic framework for distributed sparse linear algebra.
Note that JuliaPetra uses Single Program Multiple Data parallelism instead of the master/worker parallelism often used in Julia.

# Organization
JuliaPetra is organized into a series of layers.
* The [Communications Layer](@ref) contains an interface for Single Program Multiple Data parallel systems
* The [Problem Distribution Layer](@ref) manages how the problem is distributed across the processes
* The [Linear Algebra Layer](@ref) provides the interfaces and implementations for linear algebra objects
