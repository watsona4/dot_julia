# SpiceData.jl

[![Build Status](https://travis-ci.org/ma-laforge/SpiceData.jl.svg?branch=master)](https://travis-ci.org/ma-laforge/SpiceData.jl)

## Description

The SpiceData.jl module provides a pure-Julia SPICE data file reader inspired by Michael H. Perrott's CppSim reader.

## Sample Usage

Examples on how to use the SpiceData.jl capabilities can be found under the [sample directory](sample/).

<a name="Installation"></a>
## Installation

		julia> Pkg.add("SpiceData")

## Resources/Acknowledgments

### CppSim and NGspice Data Modules for Python

The following are links to Michael H. Perrott's original tools:

 - **CppSim**: <http://www.cppsim.com/index.html>.
 - **Hspice Toolbox**: <http://www.cppsim.com/download_hspice_tools.html>.

## Known Limitations

### Supported file formats

SpiceData currently supports the following SPICE file formats:

 - 9601 (32-bit x-values & 32-bit y-values)
 - 9602 (CppSim-specific format? 64-bit x-values & 64-bit y-values?)
 - 2001 (64-bit x-values & 64-bit y-values)
 - 2013 (64-bit x-values & 32-bit y-values)

### Compatibility

Extensive compatibility testing of SpiceData.jl has not been performed.  The module has been tested using the following environment(s):

 - Linux / Julia-1.1.1 (64-bit)
