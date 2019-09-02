# PhysicalCommunications.jl

[![Build Status](https://travis-ci.org/ma-laforge/PhysicalCommunications.jl.svg?branch=master)](https://travis-ci.org/ma-laforge/PhysicalCommunications.jl)

## Description

PhysicalCommunications.jl provides tools for the development & test of the physical communication layer (typically implemented in the "PHY" chip).

### Eye Diagrams

| <img src="https://github.com/ma-laforge/FileRepo/blob/master/SignalProcessing/sampleplots/demo7.png" width="850"> |
| :---: |

- **`buildeye()`**: Builds an eye diagram by folding `x` values of provided `(x,y)` into multiple windows of `teye` that start (are "triggered") every `tbit`:
  - `buildeye(x::Vector, y::Vector, tbit::Number, teye::Number; tstart::Number=0)`

Example plotting with Plots.jl:
```
#Assumption: (x, y) data generated here.
tbit = 1e-9 #Assume data bit period is 1ns.

#Build eye & use tstart to center data.
eye = buildeye(x, y, tbit, 2.0*tbit, tstart=0.2*tbit)

plot(eye.vx, eye.vy)
```

### Test Patterns
The PhysicalCommunications.jl module provides the means to create pseudo-random bit sequences to test/validate channel performance:

Example creation of PRBS pattern using maximum-length Linear-Feedback Shift Register (LFSR):
```
pattern = collect(sequence(MaxLFSR(31), seed=11, len=1000, output=Bool)).
```

Example validation of maximum-length LFSR sequence:
```
_errors = sequence_detecterrors(MaxLFSR(31), pattern)
```

#### Test Patterns: Supported Sequence Generators (Types)
- **`SequenceGenerator`** (abstract type): Defines algorithm used by sequence() to create a bit sequence.
- **`PRBSGenerator <: SequenceGenerator`** (abstract type): Specifically a pseudo-random bit sequence.
- **`MaxLFSR{LEN} <: PRBSGenerator`**: Identifies a "Maximum-Length LFSR" algorithm.
  - Reference: Alfke, Efficient Shift Registers, LFSR Counters, and Long Pseudo-Random Sequence Generators, Xilinx, XAPP 052, v1.1, 1996.
- **`MaxLFSR_Iter{LEN,TRESULT}`: "Iterator" object for MaxLFSR sequence generator.
  - Must `collect(::MaxLFSR_Iter)` to obtain sequence values.

#### Test Patterns: Iterable API
- **`sequence()`**: Create an iterable object that defines a bit sequence of length `len`..
  - `sequence(t::SequenceGenerator; seed::Integer=11, len::Int=-1, output::DataType=Int)`
  - Must use `collect(sequence([...]))` to obtain actual sequence values.

## Compatibility

Extensive compatibility testing of PhysicalCommunications.jl has not been performed.  The module has been tested using the following environment(s):

- Linux / Julia-1.1.1

## Disclaimer

The PhysicalCommunications.jl module is not yet mature.  Expect significant changes.
