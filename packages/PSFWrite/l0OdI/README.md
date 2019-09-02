# PSFWrite.jl

[![Build Status](https://travis-ci.org/ma-laforge/PSFWrite.jl.svg?branch=master)](https://travis-ci.org/ma-laforge/PSFWrite.jl)

## Description

The PSFWrite.jl module provides a pure-Julia .psf writer.


## Sample Usage

Let us consider the case of writing time-domain data to a file.  The following lines be used to generate results of a "simulation" performed at a frequency of `freq = 1e9`:

	t = collect(0:.01e-9:10e-9) #collect(): API does not yet work with Julia ranges.
	y1 = sin.(t*(2pi*freq))
	y2 = cos.(t*(2pi*freq))


One would then assemble this data into a `PSFWrite.dataset` structure, after which everything can be written to file:

```
using PSFWrite

#Collect data in a special "dataset" structure:
data = PSFWrite.dataset(t, "time") #Init with "x-axis" data (independent variable)
push!(data, y1, "y1") #Add "simulation" results
push!(data, y2, "y2") #Add more "simulation" results

#Write out data to file:
PSFWrite._open("outputfile.psf") do writer
	write(writer, data)
end
```

Please note that the `_open-do` syntax shown above will automatically call the `close()` function for the `PSFWriter` object named `writer`.

<a name="Installation"></a>
## Installation

	julia> Pkg.add("PSFWrite")

## Known Limitations

PSFWrite.jl was mostly validated against [LibPSF.jl](https://github.com/ma-laforge/LibPSF.jl): the pure-Julia implementation of Henrik Johansson's [libpsf](https://github.com/henjo/libpsf) library.  It might not be fully compliant with the PSF format.

### Missing Features

PSFWrite.jl does not currently support all .psf file capabilities.

 - Only supports writing swept data in a windowed format.

### Compatibility

Extensive compatibility testing of PSFWrite.jl has not been performed.  The module has been tested using the following environment(s):

 - Linux / Julia-1.1.1 (64-bit) / Ubuntu
