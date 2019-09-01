module DiscreteFunctions

using SimpleTools, Permutations

import Base: length, show, getindex, setindex!, *, ==, hash, ^, inv, +
import Permutations: fixed_points

export DiscreteFunction, IdentityFunction, RandomFunction, has_inv
export fixed_points, image, is_permutation

"""
`DiscreteFunction` is a function from `{1,2,...,n}` to itself.
It can be created by `DiscreteFunction(list)` where `list`
is a one-dimensional array of positive integers. Alternatively,
it can be created using positive integer arguments.

The following are equivalent:
```
DiscreteFunction([1,4,2,3])
DiscreteFunction(1,4,2,3)
```
"""
struct DiscreteFunction
    data::Vector{Int}
    function DiscreteFunction(a::Vector{Int})
        if minimum(a)<1
            error("All function values must be positive")
        end
        n = max(length(a), maximum(a))
        data_ = ones(Int,n)
        for j=1:length(a)
            data_[j] = a[j]
        end
        new(data_)
    end
end

function DiscreteFunction(a::Int, args...)
    n = length(args)+1
    data = zeros(Int,n)
    data[1] = a
    for j=1:n-1
        data[j+1] = args[j]
    end
    return DiscreteFunction(data)
end

DiscreteFunction(p::Permutation) = DiscreteFunction(p.data)

"""
`IdentityFunction(n)` creates the identity `DiscreteFunction` on
the set `{1,2,...,n}`.
"""
function IdentityFunction(n::Int)::DiscreteFunction
    @assert n>0 "Argument must be positive"
    data = collect(1:n)
    return DiscreteFunction(data)
end

"""
`RandomFunction(n)` creates a random `DiscreteFunction`
on `{1,2,...,n}`.
"""
function RandomFunction(n::Int)
    @assert n>0 "Argument must be positive"
    data = rand(1:n,n)
    return DiscreteFunction(data)
end

length(f::DiscreteFunction) = length(f.data)

(f::DiscreteFunction)(x::Int) = f.data[x]
getindex(f::DiscreteFunction, x::Int) = f.data[x]

function setindex!(f::DiscreteFunction, val::Int, x::Int)
    n = length(f)
    if val < 1 || val > n
        error("Invalid value $val for x=$x; must be between 1 and $n")
    end
    f.data[x] = val
end

(==)(f::DiscreteFunction,g::DiscreteFunction) = f.data == g.data

function show(io::IO, f::DiscreteFunction)
    n = length(f)
    print(io,"DiscreteFunction on [$n]\n")
    w = 4  # window size for printing; shame to hard code this
    for i=1:n
        print(io,flush_print(i,w))
    end
    print(io,"\n")
    for i=1:n
        print(io,flush_print(f(i),w))
    end
    print(io,"\n")
end

function (*)(f::DiscreteFunction, g::DiscreteFunction)::DiscreteFunction
    n1 = length(f)
    n2 = length(g)
    if n1 != n2
        error("Cannot compose `DiscreteFunction`s of different lengths")
    end
    data = zeros(Int,n1)
    for j=1:n1
        data[j] = f(g(j))
    end
    return DiscreteFunction(data)
end

hash(f::DiscreteFunction,h::UInt64) = hash(f.data, h)
hash(f::DiscreteFunction) = hash(f.data)

"""
`has_inv(f::DiscreteFunction)` tests if `f` is invertible.
"""
function has_inv(f::DiscreteFunction)::Bool
    n = length(f)
    return collect(1:n) == sort(f.data)
end


function inv(f::DiscreteFunction)::DiscreteFunction
    @assert has_inv(f) "This function is not invertible"
    n = length(f)
    data = zeros(Int,n)
    for j=1:n
        data[f(j)] = j
    end
    return DiscreteFunction(data)
end

function (^)(f::DiscreteFunction, t::Integer)
    if t<0
        return inv(f)^t
    end
    if t==0
        return IdentityFunction(length(f))
    end
    if t==1
        return f
    end
    half_t = Int(floor(t/2))
    g = f^half_t
    if t%2 == 0
        return g*g
    end
    return f*g*g
end

"""
If `f` and `g` are of type `DiscreteFunction`, then `f+g`
is their *disjoint sum*.
"""
function (+)(f::DiscreteFunction, g::DiscreteFunction)::DiscreteFunction
    n1 = length(f)
    d1 = f.data
    d2 = g.data .+ n1
    d = vcat(d1,d2)
    return DiscreteFunction(d)
end


"""
`fixed_points(f::DiscreteFunction)` returns a list of fixed points of
the function, i.e., those values `x` such that `f(x)==x`.
"""
fixed_points(f::DiscreteFunction) = [ i for i in 1:length(f) if f(i)==i ]


"""
`image("f::DiscreteFunction")` returns a `Set` containing all the output
values of `f`.
"""
image(f::DiscreteFunction)::Set{Int} = Set{Int}(f.data)

"""
`is_permutation(f::DiscreteFunction)` returns `true` if `f` is a
bijection on its domain.
"""
is_permutation(f::DiscreteFunction)::Bool = has_inv(f)


include("all_functions.jl")

end  # end of module
