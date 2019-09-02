# RunLengthArrays.jl

This small Julia package implements a new type, [`RunLengthArray{N,T}`](@ref),
that efficiently encodes an array containing long sequences of repeated values,
like the following example:

   6 6 6 6 4 4 4 4 4 4 4 10 10 10 10 10 10 …

The [`RunLengthArray{N,T}`](@ref) type uses a [run-length
encoding](https://en.wikipedia.org/wiki/Run-length_encoding) algorithm.

The following program shows its usage:

```julia
original = Int64[3, 3, 3, 7, 7, 7, 7];
compressed = CMBSim.RunLengthArray{Int,Int64}(original);

for elem in compressed:
    println(elem)
end

println("The sum of the elements is ", sum(compressed))
println("The 3rd element is ", compressed[3])

push!(compressed, 7)
```

The type `RunLengthArray` derives from `AbstractArray`.

## Creating an array

You can create an instance of [`RunLengthArray{N,T}`](@ref) using one of its
three constructors:

- You can call the constructor without parameters; in this case, the array will
  be empty. You can fill it later using `push!` and `append!`.
- You can pass an array, which will be compressed;
- You can pass two arrays, containing the length and value of each run respectively.

The types `N` and `T` encode the types of the counter and of the value, respectively.

The third constructor is the most interesting. Suppose that you want to store a
sequence containing four instances of the number 4.6, followed by five instances
of the number 5.7:

    4.6 4.6 4.6 4.6   5.7 5.7 5.7 5.7 5.7

You can achieve this result using one of the two following forms:

```julia
# Second constructor
x = RunLengthArray{Int,Float64}([4.6, 4.6, 4.6, 4.6, 5.7, 5.7, 5.7, 5.7, 5.7])

# Third constructor (preferred in this case)
y = RunLengthArray{Int,Float64}([4, 5], [4.6, 5.7])
```

## Operations on run-length arrays

The package defines specialized versions of a few functions in Julia's library,
in order to make them more efficient. Here is a list of them:

- `sum`
- `minimum`
- `maximum`
- `extrema`
- `sort`
- `sort!`

Calling this functions to run-length arrays can be significantly faster. Here is
an example:

```
julia> compr = RunLengthArray{Int, Float64}([100000, 200000], [1.1, 6.6]);

julia> uncompr = collect(compr);

julia> @benchmark minimum(compr)
BenchmarkTools.Trial: 
  memory estimate:  16 bytes
  allocs estimate:  1
  --------------
  minimum time:     37.372 ns (0.00% GC)
  median time:      39.660 ns (0.00% GC)
  mean time:        48.777 ns (14.87% GC)
  maximum time:     52.816 μs (99.91% GC)
  --------------
  samples:          10000
  evals/sample:     992

julia> @benchmark minimum(uncompr)
BenchmarkTools.Trial: 
  memory estimate:  16 bytes
  allocs estimate:  1
  --------------
  minimum time:     751.926 μs (0.00% GC)
  median time:      776.371 μs (0.00% GC)
  mean time:        788.463 μs (0.00% GC)
  maximum time:     1.094 ms (0.00% GC)
  --------------
  samples:          6326
  evals/sample:     1
```

## Modifying run-length arrays

There are only three operations that can modify a run-length array:

- `push!` (add an element or a run to the end of the array);
- `append!` (add a sequence to the end of the array);
- `sort!` (sort the array in-place).

The `push!` function can be used in two ways:

- Passing one value of type `T` will append it to the end of the array;
- Passing a tuple with type `Tuple{N,T}` will append a run to the end of the array.

Here is an example:

```julia
x = RunLengthArray{Int, Float64}()
push!(x, (4, 1.1))
push!(x, (6, 2.2))

# The above array is equal to the following:
y = RunLengthArray{Int, Float64}([4, 6], [1.1, 2.2])
```

## API documentation

```@autodocs
Modules = [RunLengthArrays]
```

### Index
```@index
```
