# Filetimes

[![Build Status](https://travis-ci.org/EchoJulia/Filetimes.jl.svg?branch=master)](https://travis-ci.org/EchoJulia/Filetimes.jl)

[![Coverage Status](https://coveralls.io/repos/EchoJulia/Filetimes.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/EchoJulia/Filetimes.jl?branch=master)

[![codecov.io](http://codecov.io/github/EchoJulia/Filetimes.jl/coverage.svg?branch=master)](http://codecov.io/github/EchoJulia/Filetimes.jl?branch=master)


A trivial implementation of FILETIME style timestamps [1].

FILETIME was apparently introduced in the Windows NT operating system
and is now used in a variety of file formats and equipment, including
Simrad Echosounders.

A FILETIME is an "integer value stating the number of 100 nanosecond
intervals since January 1, 1601".

```
julia> d = DateTime(1969, 10, 8)
1969-10-08T00:00:00

julia> filetime(d)
116371296000000000

julia> datetime(ans)
1969-10-08T00:00:00

julia> filetime()
131546381807780000

julia> datetime(ans)
2017-11-08T18:09:40.778
```

## References

[1] FILETIME structure. MSDN documentation, http://bit.ly/2nYBBL2
