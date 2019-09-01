# DimArrays.jl

This packages provides Julia arrays with named dimensions. 
Like the built-in Array type these are mutable objects, 
unlike [NamedArrays](https://github.com/davidavdav/NamedArrays.jl) and [AxisArrays](https://github.com/JuliaArrays/AxisArrays.jl) which are immutable. 

The idea was to have a convenient way to gather results of calculations in a script or notebook, rather than for anything high-performance. 
For example, here I have a matrix of results at each iteration, and `nest` these into a 3-tensor, whose axis order I need not remember:
```julia
using DimArrays

list = [];
for i=1:33
    slowcalc = sqrt(i) .* randn(3,13) .+ i
    push!(list, DimArray(slowcalc, :a, :b, :c ))  # add labels for 1st and 2nd dimensions  
end

list3 = nest(list, :iter)   # now i is the 3rd index, and named "iter"

using Statistics

mean(list3, dims=:iter)     # equivalent to dropdims(mean(list3, dims=3), dims=3)
```
For quick plots, dimension names are used for axes and series: 
```julia
using Plots

plot(selectdim(list3, :b, 1)' , legend=:bottomright)
```
Here `selectdim(list3, :b, 1) == list3[:,1,:]` in contents, but retains the labels.

Besides each dimension's name (which is a Symbol, strings will be converted) it can also store a function, which is used in plotting to scale the axes etc. 
(But only the output, `getindex` uses original integer indices).
You can pass a number by which to scale the index, or a dictionary, instead of a function.

For example, this plots data saved every 4 iterations correctly over the above example:
```julia
saveevery = 4
list4 = DimArray([], :iter, saveevery);     # equivalent to function  i->4i
for i=1:33
    slowcalc = sqrt(i) .* randn(3,23) .+ i
    slownice = DimArray(slowcalc, [:a, :b], [Dict(1=>"one", 2=>"two", 3=>"three")], :stuff )
                                            # equivalent to  i->Dict(...)[i]
    rem(i,saveevery)==0 && push!(list4, slownice)
end
nest(list4)

plot!(mean(nest(list4), dims=:b)', s=:dash)
```

If you do not provide a name for a dimension (or give an empty string "") 
then you can still refer to it by default names like `size(x, :row) == size(x,1)` or `maximum(y, :col)` etc. 
However these defaults are not stored, and not manipulated by `transpose(x)` or `kron(x,y)`.

For now, the list of functions supported is:

* `DimArray`, `DimVector`, `DimMatrix` create one, taking names and functions for dimensions in the order given.
* `dictvector` defines a DimVector whose function is a Dict. 
* `nest` converts arrays of arrays, and `squeeze` drops dimensions of size 1. 

and these built-in functions:

* `selectdim, size` understand a dimension's name.
* `sum, maximum, minimum, dropdims` and `Statistics.mean, std`: all can be called with a dimension's name, in which case by default `squeeze=true` on that dimension, like `mean(..., dims=:b)` above.
    They can also be called with a list of dimensions: `sum(x, dims=[1,:c])` etc.
* `push!, append!, hcat, vcat, transpose, ctranspose, permutedims`.
* Matrix multiplication `*` will warn (once) if you multiply along directions with mismatched names... which may be a terrible idea.
    And `kron`ecker products produce new names like `:a_b`.  
* `collect`, implicitly used by comprehensions like `[ sqrt(n) for n in DimVector(1:10, "int")' ]` which thus inherit the names of the array being iterated over.

Since `DimArray <: AbstractArray` anything else will fall back on their methods, and forget the dimension labels. 

See also:
* [NamedArrays](https://github.com/davidavdav/NamedArrays.jl)
* [AxisArrays](https://github.com/JuliaArrays/AxisArrays.jl)
* [RecursiveArrayTools](https://github.com/JuliaDiffEq/RecursiveArrayTools.jl)
* [JuliennedArrays](https://github.com/bramtayl/JuliennedArrays.jl)

ToDo:
* Make things like `x[:, 1:10:end]` and `hcat(a,b)` update the functions correctly.
* Figure out Julia 0.7's new broadcasting machinery.

Michael Abbott,
January 2018, mostly (as I had a grant to write).


[![Build Status](https://travis-ci.org/mcabbott/DimArrays.jl.svg?branch=master)](https://travis-ci.org/mcabbott/DimArrays.jl)

<!--
[![Coverage Status](https://coveralls.io/repos/mcabbott/DimArrays.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/mcabbott/DimArrays.jl?branch=master)
[![codecov.io](http://codecov.io/github/mcabbott/DimArrays.jl/coverage.svg?branch=master)](http://codecov.io/github/mcabbott/DimArrays.jl?branch=master)
--> 

<!--
Note to self:
pandoc -o README.html README.md
-->
