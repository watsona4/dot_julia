# VaxData

[![Build Status](https://travis-ci.org/halleysfifthinc/VaxData.jl.svg?branch=master)](https://travis-ci.org/halleysfifthinc/VaxData.jl)
[![codecov.io](http://codecov.io/github/halleysfifthinc/VaxData.jl/coverage.svg?branch=master)](http://codecov.io/github/halleysfifthinc/VaxData.jl?branch=master)

VaxData.jl is a direct port to Julia from [libvaxdata](https://pubs.usgs.gov/of/2005/1424/) [^1]. See [this report](https://pubs.usgs.gov/of/2005/1424/of2005-1424_v1.2.pdf) for an in-depth review of the underlying structure and differences between VAX data types and IEEE types.

There are 5 Vax datatypes implemented by this package:

```julia
primitive type VaxInt16 <: VaxInt 16 end
primitive type VaxInt32 <: VaxInt 32 end

primitive type VaxFloatF <: VaxFloat 32 end
primitive type VaxFloatG <: VaxFloat 64 end
primitive type VaxFloatD <: VaxFloat 64 end
```

Conversion to and from each type is defined; Vax types are promoted to the next appropriately sized type supporting math operations:

```julia
promote_type(VaxFloatF, Float32)
Float32

promote_type(VaxFloatF, VaxFloatF)
Float32

promote_type(VaxFloatF, Float64)
Float64
```

[^1]: Baker, L.M., 2005, libvaxdata: VAX Data Format Conversion Routines: U.S. Geological Survey Open-File Report 2005-1424 (http://pubs.usgs.gov/of/2005/1424/).
