# TimeToLive

[![Build Status](https://travis-ci.com/christopher-dG/TimeToLive.jl.svg?branch=master)](https://travis-ci.com/christopher-dG/TimeToLive.jl)

A [TTL](https://en.wikipedia.org/wiki/Time_to_live) cache.

```julia
julia> using Dates, TimeToLive

julia> ttl = TTL{Int, String}(Second(1))
TTL(1 second){Int64,String}()

julia> ttl[0] = "foo"
"foo"

julia> ttl[0]
"foo"

julia> sleep(2)

julia> get(ttl, 0, "bar")
"bar"
```
