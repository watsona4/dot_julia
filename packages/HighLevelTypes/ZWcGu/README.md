
# HighLevelTypes

[![Build Status](https://travis-ci.org/ResourceMind/HighLevelTypes.jl.svg?branch=master)](https://travis-ci.org/ResourceMind/HighLevelTypes.jl)
[![codecov](https://codecov.io/gh/ResourceMind/HighLevelTypes.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/ResourceMind/HighLevelTypes.jl)
[![Join the chat at https://gitter.im/realopt/Scanner.jl](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/ResourceMind/HighLevelTypes.jl)

The goal of HighLevelTypes.jl is to relieve the user from having to answer the question that we often face. Should this be a concrete or abstract type? This question is important because both have their own limitations.

- **For concrete types:** Any behavior defined using concrete types can not be inherited.  Sometimes you even don't know whether you will have in the future a specialization of your type or not. Take for example the case of Diagonal matrices defined [here](https://github.com/JuliaLang/julia/blob/0d7248e2ff65bd6886ba3f003bf5aeab929edab5/base/linalg/diagonal.jl). Assume someone works with diagonal matrices such that all elements of a matrix are taking only 3 values. It is natural to create a new type that additionally stores those values. But since all the functions were defined for the concrete type `Diagonal`, it is not possible to reuse this behavior. And as you know, inheriting behavior is much more important than inheriting fields.

- **For abstract types:** If there is a field that would naturally fit in the abstract type, its definition needs to be delayed until the definition of the concrete types. This second issue is probably less important than the first one, although for some cases it makes the code really awkward.

As a high level language, Julia deserves a high level type. doesn't it? 

## What is a high level type ?

A high level type is an abstraction for two underlying types: one is abstract and one is concrete. The user only defines high level types. By default, the concrete type will be only used for instantiation.

```julia
@hl struct Person
    name::String
end
    
@hl struct Developer <: Person
    salary::Int32
end

@hl struct SepecializedDeveloper <: Developer
    language::String
end

function sumsalaries(first::Developer, second::Developer)
    return first.salary + second.salary
end

bob = Developer("Bob", 10000)
bob.name #returns "Bob" 
bob.salary #returns 10000

alice = SepecializedDeveloper("Alice", 15000, "Julia")    
alice.name # returns "Alice" 
alice.salary # returns 15000    
alice.language # returns "Julia"
    
sumsalaries(bob, alice) #returns 25000
```

## How about performance ?

This is not the best choice for performance-critical code. Using abstract types instead of concrete types may increase the running time. Therefore the package provides the macro `@concretify` which can be applied on a block to use only the concrete types for all high level types within that block.

```julia
vec1 = Vector{Developer}()
push!(vec, bob) # OK
push!(vec, alice) # OK

@concretify vec2 = Vector{Developer}()
push!(vec2, bob) # OK
push!(vec2, alice) # throws MethodError (wrong concrete type for alice)
````

In particular, `@concretify` can be used to create concrete types.

```julia
@hl struct Job
    nb_hours::Int
    assigned_dev::Developer
end

Job(10, bob) # OK 
Job(100, alice) # OK

@concretify @hl struct ConcreteJob
    nb_hours::Int
    assigned_dev::Developer
end

ConcreteJob(10, bob) # OK
ConcreteJob(100, alice) # throws MethodError (wrong concrete type for alice)
````

## Current limitations

- A high level type can not have a tuple as its field (will be fixed soon).

## Acknowledgment

This package was inspired by ConcreteAbstractions.jl
