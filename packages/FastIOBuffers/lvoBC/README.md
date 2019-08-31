# FastIOBuffers

[![Build Status](https://travis-ci.org/tkoolen/FastIOBuffers.jl.svg?branch=master)](https://travis-ci.org/tkoolen/FastIOBuffers.jl)
[![codecov.io](http://codecov.io/github/tkoolen/FastIOBuffers.jl/coverage.svg?branch=master)](http://codecov.io/github/tkoolen/FastIOBuffers.jl?branch=master)

FastIOBuffers aims to provide faster alternatives to `Base.IOBuffer`, which as of time of writing allocates memory even when e.g. a `Float64` is written to or read from it.


### FastWriteBuffer

`FastWriteBuffer` solves the allocation problem for the write use case. On 1.1.0, using `IOBuffer`:

```julia
using BenchmarkTools
const N = 1000
@btime write(buf, x) evals = N setup = begin
    x = rand(Float64)
    buf = IOBuffer(Vector{UInt8}(undef, N * Core.sizeof(x)), read=false, write=true)
end
```

results in `15.582 ns (1 allocation: 16 bytes)`, while

```julia
using BenchmarkTools
using FastIOBuffers
const N = 1000
@btime write(buf, x) evals = N setup = begin
    x = rand(Float64)
    buf = FastWriteBuffer(Vector{UInt8}(undef, N * Core.sizeof(x)))
end
```

results in `10.759 ns (0 allocations: 0 bytes)`

### FastReadBuffer

Similarly, `FastReadBuffer` can be used in place of `IOBuffer` for reading. On 1.1.0, using `IOBuffer`:

```julia
using BenchmarkTools, Random
const N = 1000
@btime read(buf, Float64) evals = N setup = begin
    rng = MersenneTwister(1)
    writebuf = IOBuffer()
    map(1 : N) do _
        write(writebuf, rand(rng, Float64))
    end
    buf = IOBuffer(take!(writebuf))
end
```

results in `3.368 ns (0 allocations: 0 bytes)`, while replacing `IOBuffer` with `FastReadBuffer` results in `1.344 ns (0 allocations: 0 bytes)`.
