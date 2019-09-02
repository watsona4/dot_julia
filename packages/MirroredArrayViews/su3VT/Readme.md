[![Build Status](https://travis-ci.com/slmcbane/MirroredArrayViews.jl.svg?branch=master)](https://travis-ci.com/slmcbane/MirroredArrayViews.jl)

MirroredArrayViews
==================

Does what it says on the box - mirror an array along a given axis. Entries on
that axis are reversed. This package does so without a copy of data, returning
a lightweight view object onto a parent array with the specified axis (axes)
reversed.

Usage
=====
`MirroredArrayView(A::AbstractArray, dims...)` returns a view of `A` mirrored
along each dimension in `dims`.

Example
=======
```
julia> A = [1 2
       3 4]
2×2 Array{Int64,2}:
 1  2
 3  4

julia> MirroredArrayView(A, 1)
2×2 MirroredArrayView{(1,),2,Int64,Array{Int64,2}}:
 3  4
 1  2

julia> MirroredArrayView(A, 2)
2×2 MirroredArrayView{(2,),2,Int64,Array{Int64,2}}:
 2  1
 4  3

julia> MirroredArrayView(A, 1, 2)
2×2 MirroredArrayView{(1, 2),2,Int64,Array{Int64,2}}:
 4  3
 2  1
```

Copyright
=========
This package is Copyright (C) 2018 Sean McBane under the terms of the MIT
License:

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

