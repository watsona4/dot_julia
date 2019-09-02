module RunLengthArrays

export RunLengthArray, runs, values

import Base

@doc raw"""
An array of objects of type `T` encoded using run-length compression.

This works like an array, but it is designed to be extremely efficient when the
array is long and consists of long repetitions («runs») of the same elements.
The length of each run is held using type `N`; this type should be chosen
according to the expected maximum length of a run.

Once a `RunLengthArray` has been created, new elements can be added only at the
end of it, using `push!` (add one element) or `append!` (add a sequence of
elements).

```julia
arr = RunLengthArray{Int, Int8}(Int8[3, 3, 3, 7, 7, 7, 7, 7, 7, 4])

longarr = collect(arr)

@assert length(arr) == 10
@assert sum(arr) == 30
@assert arr[1] == 3
@assert arr[2] == 3

println("$(sizeof(arr))")  # Prints 16 (bytes)
println("$(sizeof(longarr))")  # Prints 56 (bytes)
```

"""
mutable struct RunLengthArray{N <: Number,T} <: AbstractArray{T,1}
    runs::Array{N}
    values::Array{T}

    RunLengthArray{N,T}() where {N <: Number,T} = new(N[], T[])
    RunLengthArray{N,T}(runs, values) where {N <: Number,T} = new(collect(runs), collect(values))
end

@doc raw"""
    runs(arr::RunLengthArray{N,T})

Returns a `Array{N,1}` type containing the length of each run in the run-length
array.

```julia
x = RunLengthArray{Int,String}(["X", "X", "X", "O", "O"])
@assert runs(x) == Int[3, 2]
```

To get a list of the values, use `values`.
"""
runs(arr::RunLengthArray{N,T}) where {N,T} = arr.runs

Base.values(arr::RunLengthArray{N,T}) where {N,T} = arr.values

################################################################################

function RunLengthArray{N,T}(arr) where {N,T}
    isempty(arr) && return RunLengthArray{N,T}()

    runs = N[]
    values = T[]

    curval = arr[1]
    curcount = 1
    for idx = 2:length(arr)
        if arr[idx] == curval
            curcount += 1
        else
            push!(runs, curcount)
            push!(values, curval)
            curval = arr[idx]
            curcount = 1
        end
    end

    push!(runs, curcount)
    push!(values, curval)

    RunLengthArray{N,T}(runs, values)
end

################################################################################

function Base.show(io::IO, arr::RunLengthArray{N,T}) where {N,T}
    print(io, "RunLengthArray{$N,$T}([")
    for elem in eachindex(arr.runs)
        print(io, "$(arr.values[elem])×$(arr.runs[elem])")
        if elem < length(arr.runs)
            print(io, ", ")
        end
    end
    println(io, "])")
end

################################################################################

Base.length(arr::RunLengthArray{N,T}) where {N,T} = sum(arr.runs)
Base.size(arr::RunLengthArray{N,T}) where {N,T} = (length(arr),)
Base.IndexStyle(arr::RunLengthArray{N,T}) where {N,T} = IndexLinear()
Base.firstindex(arr::RunLengthArray{N,T}) where {N,T} = 1
Base.lastindex(arr::RunLengthArray{N,T}) where {N,T} = length(arr)

################################################################################

function Base.iterate(iter::RunLengthArray{N,T}) where {N,T}
    isempty(iter.runs) && return nothing

    (iter.values[1], (iter.runs[1] - 1, 1))
end

function Base.iterate(iter::RunLengthArray{N,T}, state) where {N,T}
    runsleft, curidx = state

    if runsleft > 0
        runsleft -= 1
        return (iter.values[curidx], (runsleft, curidx))
    else
        curidx == length(iter.runs) && return nothing

        curidx += 1
        runsleft = iter.runs[curidx] - 1
        return (iter.values[curidx], (runsleft, curidx))
    end
end

################################################################################

function Base.getindex(arr::RunLengthArray{N,T}, target_idx::Number) where {N,T}
    1 <= target_idx <= length(arr) || throw(BoundsError(arr, target_idx))

    runidx = 1
    elements_left = target_idx
    while elements_left > 0
        elements_left <= arr.runs[runidx] && return arr.values[runidx]
        elements_left -= arr.runs[runidx]
        runidx += 1
    end

    return arr.values[end]
end

################################################################################

function Base.sum(arr::RunLengthArray{N,T}) where {N,T}
    result = zero(T)

    for idx in eachindex(arr.runs)
        result += arr.runs[idx] * arr.values[idx]
    end

    result
end

################################################################################

Base.minimum(arr::RunLengthArray{N,T}) where {N,T} = minimum(arr.values)
Base.maximum(arr::RunLengthArray{N,T}) where {N,T} = maximum(arr.values)
Base.extrema(arr::RunLengthArray{N,T}) where {N,T} = extrema(arr.values)

################################################################################

function Base.sort!(arr::RunLengthArray{N,T}; kwargs...) where {N,T}
    perm = sortperm(arr.values, kwargs...)

    arr.runs = arr.runs[perm]
    arr.values = arr.values[perm]
end

################################################################################

function Base.sort(arr::RunLengthArray{N,T}; kwargs...) where {N,T}
    perm = sortperm(arr.values, kwargs...)

    RunLengthArray{N,T}(arr.runs[perm], arr.values[perm])
end

################################################################################

function Base.push!(arr::RunLengthArray{N,T}, newval::T) where {N,T}
    if newval == arr.values[end]
        arr.runs[end] += 1
    else
        push!(arr.runs, 1)
        push!(arr.values, newval)
    end
end

function Base.push!(arr::RunLengthArray{N,T}, newrun::Tuple{N,T}) where {N,T}
    push!(arr.runs, newrun[1])
    push!(arr.values, newrun[2])
end

@doc raw"""
    push!(arr::RunLengthArray{N,T}, newval::T) where {N <: Number,T}
    push!(arr::RunLengthArray{N,T}, newrun::Tuple{N,T}) where {N <: Number,T}

Append a element or a run of elements to the end of a `RunLengthArray`. In the
second case, the parameter `newrun` must be a tuple containing the number of
repetitions `n` and the value `v`: `(n, v)`.

```julia
arr = RunLengthArray{Int, Float64}([3, 2], [1.1, 6.5])
@assert length(arr) == 5

# Add 6 instances of the number "1.4" at the end of the array
push!(arr, (6, 1.4))

@assert length(arr) == 11
Base.push!
```

`"""
push!

################################################################################

@doc raw"""
    append!(arr::RunLengthArray{N,T}, otherarray)

Append an array to a `RunLengthArray`, modifying it in place.

"""
function Base.append!(arr::RunLengthArray{N,T}, otherarray) where {N,T}
    for elem in otherarray
        push!(arr, T(elem))
    end
end

end # module
