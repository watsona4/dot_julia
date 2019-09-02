# MDDatasets.jl: Multi-Dimensional Datasets
## [:heavy_exclamation_mark: Core of C-Data Analysis/Visualization Suite](https://github.com/ma-laforge/CData.jl)

[![Build Status](https://travis-ci.org/ma-laforge/MDDatasets.jl.svg?branch=master)](https://travis-ci.org/ma-laforge/MDDatasets.jl)

## Description

The MDDatasets.jl module provides tools to simplify manipulation of multi-dimensional datasets.  MDDatasets.jl implements the core algorithms of the [C-Data Analysis/Visualization Suite](https://github.com/ma-laforge/CData.jl)

| <img src="https://github.com/ma-laforge/FileRepo/blob/master/SignalProcessing/sampleplots/demo15.png" width="850"> |
| :---: |

### Important Features
- ***Single variable for (x,y) values:*** Stores both `(x,y)` values representing `y=f(x)` in a single, coherent structure.  This signficantly improves the simplicity & readability of your calculations.
- ***Automatic Interpolation:*** Calculations will automatically be interpolated over `x` as if `y=f(x)` data represented a ***continuous*** function of x.
- ***Automatic Broadcasting:*** Operations on multi-dimensional datasets will automatically be broadcasted (vectorized) over all subsets.  This significantly improves the readability of programs.

## Concrete Example
```
using MDDatasets
```

Create `(x,y)` container pair, and call it “x”:
```
x = DataF1(0:.1:20)
#NOTE: Both x & y coordinates of "x" object initialized as y = x = [supplied range]
```

“Extract” maximum x-value from data:
```
xmax = maximum(x)
```

Construct a normalized ramp dataset, `unity_ramp`:
```
unity_ramp = x/xmax
```

#### Observe `x` and `unity_ramp`
(Note how `unity_ramp` is normalized such that maximum value is 1)
<img src="https://github.com/ma-laforge/FileRepo/blob/master/MDDatasets/demo1/samplemdcalc_1.png">

Compute `cos(kx)` & `ksinkx = cos'(kx)`:
```
coskx = cos((2.5pi/10)*x)
ksinkx = deriv(coskx)
```

Compute ramps with different slopes using `unity_ramp` (previously computed):
```
#NOTE: for Inner-most sweep, we need to specify leaf element type (DataF1 here):
ramp = fill(DataRS{DataF1}, PSweep("slope", [0, 0.5, 1, 1.5, 2])) do slope
	return unity_ramp * slope
end
```

NOTE: the above expression constructs a multi-dimensional `DataRS` structure, and fills it with `(x,y)` values for each of the desired parameter values (the slope).

#### Observe `coskx`, `ksinkx` and `ramp`
<img src="https://github.com/ma-laforge/FileRepo/blob/master/MDDatasets/demo1/samplemdcalc_2.png">


Merge two datasets with different # of sweeps (`coskx` & `ramp`):
```
r_cos = coskx+ramp
```

#### Observe newly constructed `r_cos` dataset:
<img src="https://github.com/ma-laforge/FileRepo/blob/master/MDDatasets/demo1/samplemdcalc_3.png">

Shift all ramped cos(kx) waveforms to make them centered at their mid-points:
```
midval = (minimum(ramp) + maximum(ramp)) / 2
c_cos = r_cos - midval #Shift by midval (different for each swept slope of "ramp")
```

#### Observe newly constructed `c_cos` dataset:
<img src="https://github.com/ma-laforge/FileRepo/blob/master/MDDatasets/demo1/samplemdcalc_4.png">


## Core Architecture

### Functions Of 1 Argument (`DataF1`) & Interpolation

Type `DataF1` is used to represent *continuous* functions of 1 argument (`y = f(x)`).  `DataF1` stores samples of said functions in its `x` & `y` vectors.

Operations performed on two `DataF1` objects will result in the interpolation of the corresponding `{x, y}` coordinates.  Furthermore, operations beyond the x-range of a `DataF1` object "extrapolate" to 0.

By grouping `x` & `y` vectors together, `DataF1` objects can also lead to simpler/less error-prone interfaces:

	PlottingModule.plot(x, y, ...)

gets simplified to:

	PlottingModule.plot(data, ...)

NOTE: When dealing with complex algorithms, this simplification is rearkably quite significant.

### Multi-Dimensional Datasets (`DataRS`) & Broadcasting

In order to identify trends, or simply to verify the repeatability of a process, one often needs to perform the same operation on multiple "experiments".  This module provides the `DataRS` type to store/organize/access experiment data in a convenient fashion.

As a side-note, `DataRS` collects simpler data elements (like `DataF1` or simple scalar values) into a recursive data structure.  Each `DataRS` element is used to store the results on an "experiment" (or collection of experiments) where a control variable was varied (swept).  Due to the recursive nature of `DataRS`, each "sweep" can potentially represent a control variable that is *dependent* on a previous "sweep".

#### Broadcast Features

Operations performed on multi-dimensional data sets (`DataRS`) will automatically be broadcast to each element of the dataset ([see Known Limitations](#KnownLimitations)).

Explicit looping over `DataRS` structures is therefore typically not required.  Many algorithms can be used unmodified, even after changing the set of experimental points.

By default, reducing functions (like `maximum`, `minimum`, or `mean(::Vector) => Scalar`) will operate on `DataRS` structures by collapsing the inner-most dimension:

	#Assuming sig -> DataRS{sweeps={supply, temp, ctrlVoltage}} of DataF1{x=time}
	freqVctrl = mean(measfreq(sig)) #DataRS{sweeps={supply, temp, ctrlVoltage}}
	maxfVtemp = maximum(freqVctrl) #DataRS{sweeps={supply, temp}}
	maxfVsupply = maximum(maxfVtemp) #DataRS{sweeps={supply}}

As can be inferred from above, the sweep from the inner-most dimension can be thought as the x-coordinate of the data.  That is because subsequent operations will be applied along that dimension.

TODO: Provide a means to re-order dimensions.

## Principal Types

- **`DataInt, DataFloat, DataComplex`**: Useful aliases for largest practical data types on a platform (not yet platform dependent).
- **`DataMD`**: Abastract data type for multi-dimensional data.
- **`DataF1`**: Represents a function of 1 variable, y(x) using a x/y vector pair.
- **`DataHR{DataF1/DataInt/DataFloat/DataComplex}`**: ***DO NOT USE*** A hyper-rectangular organizaton of data.  Principally designed to collect massive datasets with *independent* control variables ([see examples](README_DataHR.md#SampleUsage_DataHR)).
- **`DataRS{DataF1/DataInt/DataFloat/DataComplex}`**: A recursive-sweep organization of data.  Principally designed to collect massive datasets with *dependent* control variables([see examples](#SampleUsage_DataRS)).
- **`PSweep`**: A parameter sweep (i.e. an independent control variable that generates experimental points in a `DataRS/DataHR` dataset).

### Function Listing

#### Imported From `Base`

- Single-argument functions:

  - `zeros, ones, abs, abs2, angle,`
<br>`imag, real, exponent,`
<br>`exp, exp2, exp10, expm1,`
<br>`log, log10, log1p, log2,`
<br>`ceil, floor,`
<br>`asin, asind, asinh, acos, acosd, acosh,`
<br>`atan, atand, atanh, acot, acotd, acoth,`
<br>`asec, asecd, asech, acsc, acscd, acsch,`
<br>`sin, sind, sinh, cos, cosd, cosh,`
<br>`tan, tand, tanh, cot, cotd, coth,`
<br>`sec, secd, sech, csc, cscd, csch,`
<br>`sinpi, cospi,`
<br>`sinc, cosc,`
<br>`deg2rad, rad2deg,`

- Two-argument functions:

  - `+, -, *, /, ^,`
<br>`max, min,`
<br>`atan, hypot,`
<br>`maximum, minimum,`
<br>`prod, sum,`
<br>`mean, median, middle,`

#### Differential/Integral Math

- **`deriv`**`(d::DataF1, shiftx=[Bool])`: Returns dataset with derivative of `d`
- **`integ`**`(d::DataF1, shiftx=[Bool])`: Returns definite integral of `d`
- **`iinteg`**`(d::DataF1, shiftx=[Bool])`: Returns dataset with indefinite integral of `d`

#### Basic Dataset Operations
- **`xval`**`(::DataF1)`: Returns a dataset with where y(x) = x.
- **`value`**`(y::DataF1, x=[Real])`: Returns `y(x)`
- **`clip`**`()`: Returns a dataset clipped within an x-range
  - `clip(::DataF1, xrng::Range)`
  - `clip(::DataF1, xmin=[Real], xmax=[Real])`
- **`sample`**`(::DataF1, xrng::Range)`: Returns dataset sampled @ each point in `xrng`
- **`xshift`**`(::DataF1, offset::Number)`: Returns dataset with all x-values shifted by `offset` (negative values "shift left")
- **`xscale`**`(::DataF1, fact::Number)`: Returns dataset with all x-values scaled by `fact`
- **`yvsx`**`(yv::DataF1, xv::DataF1)`: Returns dataset with `{xv(x), yv(x)}` (interpolating, when necessary)

#### Cross-Based Operations

Note: The `Event` object makes functions return x-vectors that represent the current event number.

- **`xcross`**`()`: Returns x-values of `d1` (up-to `nmax`) when `d1` crosses 0 (`nmax`=0: get all crossings):
  - `xcross([Event,] d1::DataF1, [nmax::Int,] xstart=[Real], allow=[CrossType])`
- **`ycross`**`()`: Returns y-values of `d2` (up-to `nmax`) when `d1` crosses `d2` (`nmax`=0: get all crossings):
  - `ycross([Event,] d1::DataF1, d2::DataF1, [nmax::Int,] xstart=[Real], allow=[CrossType])`
- **`xcross1`**`()`: Returns scalar x-value of `d1` on `n`-th zero-crossing:
  - `xcross1([Event,] d1::DataF1, n=[Int], xstart=[Real], allow=[CrossType])`
- **`ycross1`**`()`: Returns scalar y-value of `d1` on `n`-th crossing of `d1` & `d2`:
  - `ycross1([Event,] d1::DataF1, n=[Int], xstart=[Real], allow=[CrossType])`

##### Operations On Clock Signals
- **`measperiod`**`(d::DataF1, nmax=[Int], tstart=[Real], xing=[CrossType], shiftx=[Bool])`
- **`measfreq`**`(d::DataF1, nmax=[Int], tstart=[Real], xing=[CrossType], shiftx=[Bool])`

##### Operations On Binary Signals
- **`measdelay`**`(dref::DataF1, dmain::DataF1, nmax=[Int], tstart_ref=[Real], tstart_main=[Real], xing_ref=[CrossType], xing_main=[CrossType])`
- **`measck2q`**`(ck::DataF1, q::DataF1, delaymin=[Real], tstart_ck=[Real], tstart_q=[Real], xing_ck=[CrossType], xing_q=[CrossType])`

##### The `CrossType` Object

The `CrossType` object is used to filter out undersired events.

- `sing`: Include singularities (points that cross at a single point).
- `flat`: Include middle of crossings that are detected at multiple consecutive points.
- `thru`: Include crossings make it all the way through the crossing point.
- `rev`: Include crossings that hit the crossing point, then reverse back.
- `firstlast`: Include first/last crossing points (when data starts or ends @ crossing point itself).

Constructors:

- **`CrossType`**: Indicates which crossings are allowed in the result.
  - `CrossType(rise=[Bool], fall=[Bool], sing=[Bool], flat=[Bool], thru=[Bool], rev=[Bool], firstlast=[Bool])`
  - `CrossType(:rise)`: Preset to selecting rising edges
  - `CrossType(:fall)`: Preset to selecting falling edges
  - `CrossType(:risefall)`: Preset to selecting both rising & falling edges

<a name="SampleUsage"></a>
## Sample Usage

Examples of the MDDatasets.jl capabilities can be found under the [test directory](test/).

More advanced usage examples can be found in the [sample directory](https://github.com/ma-laforge/SignalProcessing.jl/tree/master/sample) of the [SignalProcessing.jl module](https://github.com/ma-laforge/SignalProcessing.jl).

<a name="SampleUsage_DataRS"></a>
## Usage: Constructing A Recursive-Sweep Dataset

Assuming input data can be generated using the following:

	t = DataF1((0:.01:10)*1e-9) #Time vector stored as a function of 1 argument

	#NOTE: get_ydata returns type "DataF1" (stores data as a function of 1 argument):
	get_ydata(t::DataF1, tbit, vdd, trise) = sin(2pi*t/tbit)*(trise/tbit)+vdd

One can create a relatively complex Recursive-Sweep (DataRS) dataset using the following pattern:

	datars = fill(DataRS, PSweep("tbit", [1, 3, 9] * 1e-9)) do tbit
		fill(DataRS, PSweep("VDD", 0.9 * [0.9, 1, 1.1])) do vdd

			#Inner-most sweep: need to specify element type (DataF1):
			#(Other (scalar) element types: DataInt/DataFloat/DataComplex)
			fill(DataRS{DataF1}, PSweep("trise", [0.1, 0.15, 0.2] * tbit)) do trise
				return get_ydata(t, tbit, vdd, trise)
			end
		end
	end

<a name="KnownLimitations"></a>
## Known Limitations

### Implementation

1. Support for broadcasting functions over `DataHR` & `DataRS` types is fairly extensive.
    - Nonetheless, the system is incomplete/imperfect, and unexpected failures will occur.

### Compatibility

Extensive compatibility testing of MDDatasets.jl has not been performed.  The module has been tested using the following environment(s):

- Linux / Julia-1.1.1 (64-bit)

## Disclaimer

The MDDatasets.jl module is not yet mature.  Expect significant changes.
