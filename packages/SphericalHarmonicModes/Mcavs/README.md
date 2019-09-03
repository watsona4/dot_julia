# SphericalHarmonicModes.jl

[![Build Status](https://travis-ci.com/jishnub/SphericalHarmonicModes.jl.svg?branch=master)](https://travis-ci.com/jishnub/SphericalHarmonicModes.jl)

This package provides two iterators that are relevant in the context of spherical harmonics. 
1. An iterator to loop over spherical harmonic modes, typically denoted by `(l,m)`. We use the notation `(s,t)` in this package.
2. An iterator to loop over pairs of spherical harmonic degrees `s` and `s′`, where `|s-Δs|<=s′<=s+Δs`. The iterator generates pairs of `(s′,s)` for a specified range of `s` and all `Δs` that satisfy `0 ⩽ Δs ⩽ Δs_max` for a specified `Δs_max`. 

## Getting Started

### Installing

```julia
] add "https://github.com/jishnub/SphericalHarmonicModes.jl.git"

julia> using SphericalHarmonicModes
```
## Usage

### Creating a spherical harmonic iterator

There are two different orderings possible to iterate over spherical harmonic modes, with either `s` or `t` increasing faster than the other. They are denoted by `st` and `ts`, where --- going by the Julia convention of column-major arrays --- the first index increases faster than the second. Irrespective of which ordering is chosen, the modes are always returned as `(s,t)`.

Both the iterators are created using the general syntax `m(smin,smax,tmin,tmax)` where `m` can be `st` or `ts`. To create an iterator with `t` increasing faster than `s`:

```julia
julia> m=ts(0,1,-1,1)
Spherical harmonic modes with t increasing faster than s
smin = 0, smax = 1, tmin = -1, tmax = 1

julia> collect(m)
4-element Array{Tuple{Int64,Int64},1}:
 (0, 0) 
 (1, -1)
 (1, 0) 
 (1, 1)
```

To create an iterator with `s` increasing faster than `t`:

```julia
julia> m=st(0,1,-1,1)
Spherical harmonic modes with s increasing faster than t
smin = 0, smax = 1, tmin = -1, tmax = 1

julia> collect(m)
4-element Array{Tuple{Int64,Int64},1}:
 (1, -1)
 (0, 0) 
 (1, 0) 
 (1, 1)
 ```

 Special constructors to include all `t`s are available for convenience.

```julia
julia> st(2)
Spherical harmonic modes with s increasing faster than t
smin = 2, smax = 2, tmin = -2, tmax = 2

julia> st(2,4)
Spherical harmonic modes with s increasing faster than t
smin = 2, smax = 4, tmin = -4, tmax = 4

julia> st(2:4)
Spherical harmonic modes with s increasing faster than t
smin = 2, smax = 4, tmin = -4, tmax = 4
```

 You can also choose a range of `t`s.
```julia
julia> st(2:4,0:2)
Spherical harmonic modes with s increasing faster than t
smin = 2, smax = 4, tmin = 0, tmax = 2
```

### Creating an (s',s) iterator

This iterator can be created as `s′s(smin,smax,Δs_max,s′min,s′max)`, for example

```julia
julia> m=s′s(1,2,2,1,1)
Spherical harmonic modes (s′,s) where |s-Δs| ⩽ s′ ⩽ s+Δs for 0 ⩽ Δs ⩽ Δs_max, and s′min ⩽ s′ ⩽ s′max
1 ⩽ s ⩽ 2, Δs_max = 2, and 1 ⩽ s′ ⩽ 1

julia> collect(m)
2-element Array{Tuple{Int64,Int64},1}:
 (1, 1)
 (1, 2)
```

The ranges of `s` and `s′` will be clipped to the maximal valid subset based on `Δs_max`. Several convenience constructors are available, such as 

```julia
julia> m=s′s(1,2,2)
Spherical harmonic modes (s′,s) where |s-Δs| ⩽ s′ ⩽ s+Δs for 0 ⩽ Δs ⩽ Δs_max, and s′min ⩽ s′ ⩽ s′max
1 ⩽ s ⩽ 2, Δs_max = 2, and 0 ⩽ s′ ⩽ 4

julia> s′s(1:2,2) == s′s(1,2,2)
true

julia> m=s′s(1:2,2,2)
Spherical harmonic modes (s′,s) where |s-Δs| ⩽ s′ ⩽ s+Δs for 0 ⩽ Δs ⩽ Δs_max, and s′min ⩽ s′ ⩽ s′max
1 ⩽ s ⩽ 2, Δs_max = 2, and 2 ⩽ s′ ⩽ 4

julia> m=s′s(1:2,2,2,2)
Spherical harmonic modes (s′,s) where |s-Δs| ⩽ s′ ⩽ s+Δs for 0 ⩽ Δs ⩽ Δs_max, and s′min ⩽ s′ ⩽ s′max
1 ⩽ s ⩽ 2, Δs_max = 2, and 2 ⩽ s′ ⩽ 2

julia> s′s(1:2,2,2:2) == s′s(1:2,2,2,2)
true
```

### Using the iterators

 The length of an iterator can be computed in `O(1)` time.
 
```julia
julia> m=st(0,20000000,-1000000,2000)
Spherical harmonic modes with s increasing faster than t
smin = 0, smax = 20000000, tmin = -1000000, tmax = 2000

julia> @btime length(m)
  20.630 ns (1 allocation: 16 bytes)
19540018501001
```

However this can be evaluated faster by using the function `number_of_modes` that comes with this package. This avoids the time spent on multiple dispatch.

```julia
julia> m=st(0,20000000,-1000000,2000);

julia> @btime number_of_modes(m)
  7.264 ns (0 allocations: 0 bytes)
19540018501001

julia> @btime length(m)
  19.349 ns (1 allocation: 16 bytes)
19540018501001
```

It is easy to check whether a mode is present in the iterator. This can also be checked in `O(1)` time.

```julia
julia> m=st(0,20000000,-1000000,2000)
Spherical harmonic modes with s increasing faster than t
smin = 0, smax = 20000000, tmin = -1000000, tmax = 2000

julia> @btime (1000,1000) in m
  12.876 ns (0 allocations: 0 bytes)
true
```

To avoid the dispatch time, one can use the internal `_in` function.

```julia
julia> m=st(0,20000000,-1000000,2000);

julia> @btime (1000,1000) in m
  13.636 ns (0 allocations: 0 bytes)
true

julia> @btime SphericalHarmonicModes._in((1000,1000),m)
  3.649 ns (0 allocations: 0 bytes)
true
```

The index at which a mode is present can be checked using `modeindex`. For example
```julia
julia> m=ts(0,2,-1,2);

julia> collect(m)
8-element Array{Tuple{Int64,Int64},1}:
 (0, 0) 
 (1, -1)
 (1, 0) 
 (1, 1) 
 (2, -1)
 (2, 0) 
 (2, 1) 
 (2, 2) 

julia> modeindex(m,(1,0))
3

julia> modeindex(m,(2,2))
8
```

This is also evaluated in `O(1)` time.

```julia
julia> m=ts(0,20000);

julia> @btime modeindex(m,(20000,20000))
  25.370 ns (1 allocation: 16 bytes)
400040001

julia> m=s′s(1:100,100);

julia> @btime modeindex(m,(100,100))
  26.867 ns (1 allocation: 16 bytes)
15050
```

Indexing is not supported at the moment, but the last element can be obtained easily.

```julia
julia> m=ts(0,2,-1,2);

julia> collect(m)
8-element Array{Tuple{Int64,Int64},1}:
 (0, 0) 
 (1, -1)
 (1, 0) 
 (1, 1) 
 (2, -1)
 (2, 0) 
 (2, 1) 
 (2, 2) 

julia> last(m)
(2, 2)

julia> m=ts(0,20000);

julia> @btime last(m)
  16.645 ns (1 allocation: 32 bytes)
(20000, 20000)
```

The times were measured on an Intel® Core™ i7-8650U machine.

## License

This project is licensed under the MIT License - see the [LICENSE.md](https://github.com/jishnub/SphericalHarmonicModes.jl/blob/master/LICENSE) file for details.
