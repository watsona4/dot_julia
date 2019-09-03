# SimradRaw

[![Build Status](https://travis-ci.org/EchoJulia/SimradRaw.jl.svg?branch=master)](https://travis-ci.org/EchoJulia/SimradRaw.jl)

[![Coverage Status](https://coveralls.io/repos/EchoJulia/SimradRaw.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/EchoJulia/SimradRaw.jl?branch=master)

[![codecov.io](http://codecov.io/github/EchoJulia/SimradRaw.jl/coverage.svg?branch=master)](http://codecov.io/github/EchoJulia/SimradRaw.jl?branch=master)

Simrad echosounder RAW file format reader in
[Julia](http://julialang.org)


## Introduction

Simrad scientific echosounders such as EK60, EK80 and WBT save their
data in datagram oriented, RAW format files as described in the
reference manuals.

This Julia library reads RAW format files, returning their contents as
a series of Julia structs representing datagrams. It is intended to be
used by higher level libraries such as https://github.com/EchoJulia/SimradEK60.jl,
that interprete the data to provide matrices of volume backscatter
etc.

## Getting started

```
using SimradRaw
using SimradEK60TestData
filename = EK60_SAMPLE # or some other RAW file
datagrams = SimradRaw.load(filename)
```

Also see the example `scripts\rawcat.jl`, a command line program that
dumps out RAW files in a somewhat readable format.

## References

1. [Simrad EK60 Context sensitive on-line help](http://www.simrad.net/ek60_ref_english/default.htm)

2. [Simrad EK80 Wide band scientific echo sounder Reference Manual](http://www.simrad.net/ek80_ref_english/default.htm)

