# PriorityChannels

[![Build Status](https://travis-ci.org/baggepinnen/PriorityChannels.jl.svg?branch=master)](https://travis-ci.org/baggepinnen/PriorityChannels.jl)

This package provides the type `PriorityChannel` (the only exported name) that mimics [`Base.Channel`](https://docs.julialang.org/en/v1/base/parallel/#Base.Channel), but where each element is associated with a priority. [`take!`](https://docs.julialang.org/en/v1/base/parallel/#Base.take!-Tuple{Channel}) always returns the highest priority element. Internally, a [heap](https://en.wikipedia.org/wiki/Heap_(data_structure)) is used to keep track of priorities. Example usage:
```julia
using PriorityChannels, Test
c  = Channel(50)
pc = PriorityChannel(50)
for i = 1:50
    e = rand(1:500)
    put!(c,e)
    put!(pc,e,e) # Assign same priority as element for testing purposes
end
elems = [take!(c) for i = 1:50]
pelems = [take!(pc) for i = 1:50]
@test !issorted(elems) # A regular Channel does not return ordered elements
@test issorted(pelems) # A PriorityChannel returns elements in priority order
```

## Difference between `Channel` and `PriorityChannel`
- `put!(pc, element, priority::Real)` **lower** number indicates a higher priority (default = 0).
- `PriorityChannel` can not be unbuffered (of length 0) and must have a positive length.
- [`take!(pc)`](https://docs.julialang.org/en/v1/base/parallel/#Base.take!-Tuple{Channel}) returns the highest priority item, `PriorityChannel` thus acts like a  [priority queue](https://en.wikipedia.org/wiki/Priority_queue) instead of a FIFO queue like `Channel` does
- Pretty much all other functionality should be the same, including all constructors.

## Performance
To get maximum performance, initialize a concretely typed `PriorityChannel`. The constructor `PriorityChannel(N)` creates a channel of length `N` that holds type `Any` and have integer priorities. These types can be specified with the constructor `PriorityChannel{ElemType,PrioType}(N)`, e.g., `PriorityChannel{Int,Int}(N)`. There is a rather striking difference in performance between these two:
```julia
using PriorityChannels
N = 1_000_000
r = rand(1:1000, N);
const c1 = PriorityChannel(N)
const c2 = PriorityChannel{Int,Int}(N)

@time map(ri->put!(c1,ri,ri), r);
@time map(ri->put!(c2,ri,ri), r);

@time map(i->take!(c1), 1:N);
@time map(i->take!(c2), 1:N);

# Output after pre-compilation
julia> @time map(ri->put!(c1,ri,ri), r);
  0.663640 seconds (4.33 M allocations: 150.086 MiB, 55.92% gc time)

julia> @time map(ri->put!(c2,ri,ri), r);
  0.103298 seconds (60.23 k allocations: 12.643 MiB)

julia> @time map(i->take!(c1), 1:N);
  3.282501 seconds (20.02 M allocations: 612.583 MiB, 27.25% gc time)

julia> @time map(i->take!(c2), 1:N);
  0.313285 seconds (63.44 k allocations: 10.791 MiB, 4.67% gc time)
```
