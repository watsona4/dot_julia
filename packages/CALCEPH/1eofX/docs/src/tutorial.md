# Tutorial

This tutorial will walk you through the features and functionality of [CALCEPH.jl](https://github.com/JuliaAstro/CALCEPH.jl)

## Ephemerides sources

The supported sources of ephemerides are:
- JPL DExxx binary ephemerides files: [https://ssd.jpl.nasa.gov/?planet_eph_export](https://ssd.jpl.nasa.gov/?planet_eph_export)
- IMCCE INPOP ephemerides files: [https://www.imcce.fr/inpop/](https://www.imcce.fr/inpop/)
- some NAIF SPICE kernels: [https://naif.jpl.nasa.gov/naif/data.html](https://naif.jpl.nasa.gov/naif/data.html)

Example:
```julia
download("https://naif.jpl.nasa.gov/pub/naif/generic_kernels/spk/planets/de435.bsp","planets.dat")
# WARNING this next file is huge (Jupiter Moons ephemerides)
download("https://naif.jpl.nasa.gov/pub/naif/generic_kernels/spk/satellites/jup310.bsp","jupiter_system.bsp")
```

## Ephemerides context

The user first need to load the ephemerides files into an ephemerides context object that will be used later to retrieve position and velocities of celestial objects.

A context can be made from one or several files:

```julia
using CALCEPH

# load a single file in context eph1
eph1 = Ephem("planets.dat")
# load multiple files in context eph2
eph2 = Ephem(["planets.dat","jupiter_system.bsp"])
```

You must specify the relative or absolute path(s) of the file(s) to load.

You can prefetch the ephemerides data into main memory for faster access:
```julia
prefetch(eph2)
```

## Epoch arguments

CALCEPH function takes the epoch as the sum of two double precision floating arguments jd1 and jd2.
The sum jd1 + jd2 is interpreted as the julian date in the timescale of the ephemerides context (usually TDB or sometimes TCB).

For maximum accuracy, it is recommended to set jd2 to the fractional part of the julian date and jd1 to the difference: jd2 magnitude should be less than one while jd1 should have an integer value.

If a high accuracy in timetag is not needed, jd1 can be set to the full julian date and jd2 to zero.

## Options

Many CALCEPH function takes an integer argument to store options. The value of this argument is the sum of the option to enable (each option actually corresponds to a single bit of that integer). Each option to enable can appear only once in the sum!

The following options are available:

- unitAU = 1: set distance units it to Astronomical Unit.
- unitKM = 2: set distance units to kilometers.
- unitDay = 4: set time units to days.
- unitSec = 8: set time units to seconds.
- unitRad = 16: set angle units to radians.
- useNaifId = 32: set the body identification scheme to NAIF body identification scheme.
- outputEulerAngles = 64: when using body orientation ephemerides, this allows to choose Euler angle output.
- outputNutationAngles = 128: when using body orientation ephemerides, this allows to choose nutation angle output (if available).

The useNaifId option controls the identification scheme for the input arguments: target and center.

The units options controls the units of the outputs. It is compulsory to set the output units if the routine has the input argument options.

For example to compute the position and velocity in kilometers and kilometers per second of body target (given as its NAIF identification number) with respect to center (given as its NAIF identification number), the options argument should be set as such:

```julia
options = unitKM + unitSec + useNaifId
```

## Body identification scheme

CALCEPH has the following identification scheme for bodies:
- 1 : Mercury Barycenter
- 2 : Venus Barycenter
- 3 : Earth
- 4 : Mars Barycenter
- 5 : Jupiter Barycenter
- 6 : Saturn Barycenter
- 7 : Uranus Barycenter
- 8 : Neptune Barycenter
- 9 : Pluto Barycenter
- 10 : Moon
- 11 : Sun
- 12 : Solar Sytem barycenter
- 13 : Earth-moon barycenter
- 14 : Nutation angles
- 15 : Librations
- 16 : difference TT-TDB
- 17 : difference TCG-TCB
- asteroid number + 2000000 : asteroid

If target is 14, 15, 16 or 17 (nutation, libration, TT-TDB or TCG-TCB), center must be 0.

The more complete NAIF identification scheme can be used if the value useNaifId is added to the options argument.

## NAIF body identification scheme

See [https://naif.jpl.nasa.gov/pub/naif/toolkit_docs/C/req/naif_ids.html](https://naif.jpl.nasa.gov/pub/naif/toolkit_docs/C/req/naif_ids.html)

CALCEPH uses this identification scheme only when the value useNaifId is added to the options argument.

The CALCEPH julia wrapper comes with the naifId object which contains the mapping between NAIF identification numbers and names:

```julia
julia> naifId.id[:sun]
10

julia> naifId.id[:mars]
499

julia> naifId.names[0]
Set(Symbol[:ssb, :solar_system_barycenter])

```

naifId also stores the following identifiers:
- :timecenter (1000000000): the center argument when requesting a value from a time ephemeris.
- :ttmtdb (1000000001): the target argument when requesting a value from the difference TT-TDB time ephemeris.
- :tcgmtcb (1000000002): the target argument when requesting a value from the difference TCG-TCB time ephemeris.


naifId is actually an instance of mutable struct BodyId. The user can also create its own identification scheme for its SPICE kernels:
```julia
const MyUniverseIds = CALCEPH.BodyId()
CALCEPH.add!(MyUniverseIds,:tatooine,1000001)
CALCEPH.add!(MyUniverseIds,:dagobah,1000002)
CALCEPH.add!(MyUniverseIds,:endor,1000003)
CALCEPH.add!(MyUniverseIds,:deathstar,1000004)
CALCEPH.add!(MyUniverseIds,:endor_deathstar_system_barycenter,1000005)
CALCEPH.add!(MyUniverseIds,:edsb,1000005)
```

You can also load identification data from an external file:
```julia
CALCEPH.loadData!(MyUniverseIds, "MyUniverseIds.txt")
```
See example: [https://github.com/JuliaAstro/CALCEPH.jl/blob/master/data/NaifIds.txt](https://github.com/JuliaAstro/CALCEPH.jl/blob/master/data/NaifIds.txt)

Names from the file are converted to lower case and have spaces replaced by underscores before being converted to symbols/interned strings.

## Computing positions and velocities:

The following methods are available to compute position and velocity with CALCEPH:

```julia
compute(eph,jd1,jd2,target,center)
compute(eph,jd1,jd2,target,center,options)
compute(eph,jd1,jd2,target,center,options,order)
```

Those methods compute the position and its time derivatives of target with respect to center.

- The first argument eph is the ephemerides context.
- The second and third arguments jd1 and jd2 are the epoch.
- The third argument target is the body for which position is to be computed with respect to origin.
- The fourth argument center is the origin.
- The options argument shall specify the units. It can also be used to switch target and center numbering scheme to the NAIF identification scheme.
- The order argument can be set to:
  - 0: compute position only
  - 1: compute position and velocity
  - 2: compute position, velocity and acceleration
  - 3: compute position, velocity, acceleration and jerk.


When order is not specified, position and velocity are computed.

#### Example:
Computing position only of Jupiter system barycenter with respect to the Earth Moon center in kilometers at JD=2456293.5 (Ephemeris Time).
```julia
options = useNaifId + unitKM + unitSec
jd1 = 2456293.0
jd2 = 0.5
center = naifId.id[:moon]
target = naifId.id[:jupiter_barycenter]
pos = compute(eph2, jd1, jd2, target, center, options,0)
```  

## Computing orientation:

The following methods are available to compute orientation angles with CALCEPH:

```julia
orient(eph,jd1,jd2,target,options)
orient(eph,jd1,jd2,target,options,order)
```

Those methods compute the Euler angles of target and their time derivatives.

- The first argument eph is the ephemerides context.
- The second and third arguments jd1 and jd2 are the epoch.
- The fourth argument target is the body for which the Euler angles are to be computed.
- The options argument shall specify the units. It can also be used to switch target and center numbering scheme to the NAIF identification scheme and to switch between Euler angles and nutation angles.
- The order argument can be set to:
  - 0: only the angles are computed.
  - 1: only the angles and first derivatives are computed.
  - 2: only the angles, the first and second derivatives are computed.
  - 3: the angles, the first, second and third derivatives are computed.

#### Example:
JPL DE405 binary ephemerides contain Chebychev polynomials for the IAU 1980 nutation theory. Interpolating those is much faster than computing the IAU 1980 nutation series.    
Computing Earth nutation angles in radians at JD=2456293.5 (Ephemeris Time).
```julia
download("ftp://ssd.jpl.nasa.gov/pub/eph/planets/Linux/de405/lnxp1600p2200.405","DE405")
eph1 = Ephem("DE405")
options = useNaifId + unitRad + unitSec + outputNutationAngles
jd1 = 2456293.0
jd2 = 0.5
target = naifId.id[:earth]
angles = orient(eph1, jd1, jd2, target, options,0)
```
Note that the returned value is a vector of 3 even though there are only 2 nutation angles. The last value is zero and meaningless.

## Computing angular momentum:

The following methods are available to compute body angular momentum with CALCEPH:

```julia
rotAngMom(eph,jd1,jd2,target,options)
rotAngMom(eph,jd1,jd2,target,options,order)
```

Those methods compute the angular momentum of target and their time derivatives.

- The first argument eph is the ephemerides context.
- The second and third arguments jd1 and jd2 are the epoch.
- The fourth argument target is the body for which the angular momentum are to be computed.
- The options argument shall specify the units. It can also be used to switch target numbering scheme to the NAIF identification scheme.
- The order argument can be set to:
  - 0: only the angular momentum vector are computed.
  - 1: only the angular momentum vector and first derivative are computed.
  - 2: only the angular momentum vector, the first and second derivatives are computed.
  - 3: the angular momentum, the first, second and third derivatives are computed.

## Time ephemeris

The time ephemeris TT-TDB or TCG-TCB at the geocenter can be evaluated with a suitable source.

INPOP and some JPL DE ephemerides includes a numerically integrated time ephemeris for the geocenter which is usually more accurate than the analytical series: Moreover it is much faster to interpolate those ephemerides than to evaluate the analytical series. This is only for the geocenter but a simple correction can also be added for the location of the observer (and its velocity in case the observer is on a highly elliptical orbit).

Files that can be used to obtain the difference between TT and TDB are, e.g.:
- [ftp://ftp.imcce.fr/pub/ephem/planets/inpop17a/inpop17a_TDB_m100_p100_tt.dat](ftp://ftp.imcce.fr/pub/ephem/planets/inpop17a/inpop17a_TDB_m100_p100_tt.dat)
- [ftp://ssd.jpl.nasa.gov/pub/eph/planets/bsp/de432t.bsp](ftp://ssd.jpl.nasa.gov/pub/eph/planets/bsp/de432t.bsp)

#### Example:  
Computing TT-TDB at geocenter in seconds at JD=2456293.5 (Ephemeris Time).
```julia
download("ftp://ftp.imcce.fr/pub/ephem/planets/inpop17a/inpop17a_TDB_m100_p100_tt.dat","INPOP17a")
eph1 = Ephem("INPOP17a")
options = useNaifId + unitSec
jd1 = 2456293.0
jd2 = 0.5
target = naifId.id[:ttmtdb]
center = naifId.id[:timecenter]
ttmtdb = compute(eph1, jd1, jd2, target, center, options,0)
```

Note that the returned value is a vector of 3 even though there is only one meaningful value. The last 2 values are zero and meaningless.

## In place methods

In place versions of the methods described above are also available. Those are:

```julia
unsafe_compute!(result,eph,jd1,jd2,target,center)
unsafe_compute!(result,eph,jd1,jd2,target,center,options)
unsafe_compute!(result,eph,jd1,jd2,target,center,options,order)
unsafe_orient!(result,eph,jd1,jd2,target,options)
unsafe_orient!(result,eph,jd1,jd2,target,options,order)
unsafe_rotAngMom!(result,eph,jd1,jd2,target,options)
unsafe_rotAngMom!(result,eph,jd1,jd2,target,options,order)
```

Those methods do not perform any checks on their inputs. In particular, result must be a contiguous vector of double precision floating point number of dimension at least 6 when order is not specified or at least 3*(order+1) otherwise.

## Constants

Ephemerides files may contain related constants. Those can be obtained by the **constants** method which returns a dictionary:

```julia  
download("ftp://ftp.imcce.fr/pub/ephem/planets/inpop17a/inpop17a_TDB_m100_p100_tt.dat","INPOP17a")
eph1 = Ephem("INPOP17a")
# retrieve constants from ephemeris as a dictionary
con = constants(eph1)
# list the constants
keys(con)
# get the sun J2
J2sun = con[:J2SUN]
```

## Introspection

#### Time scale
```julia
timeScale(eph)
```
returns the Ephemeris Time identifier:
- 1 for TDB
- 2 for TCB

#### Time span
```julia
timespan(eph)
```
returns the triplet:
- julian date of first entry in ephemerides context.
- julian date of last entry in ephemerides context.
- information about the availability of the quantities over the time span:
  - 1 if the quantities of all bodies are available for any time between the first and last time.
  - 2 if the quantities of some bodies are available on discontinuous time intervals between the first and last time.
  - 3 if the quantities of each body are available on a continuous time interval between the first and last time, but not available for any time between the first and last time.

#### Position records

```julia
positionRecords(eph)
```
retrieve position records metadata in ephemeris associated to handler eph.
This is a vector of metadata about the ephemerides records ordered by priority. The compute methods use the highest priority ephemerides records when there are multiple records that could satisfy the target and epoch.

Each record metadata contains the following information:
- target: NAIF identifier of target.
- center: NAIF identifier of center.
- startEpoch: julian date of record start.
- stopEpoch: julian date of record end.
- frame : 1 for ICRF.

#### Orientation records

```julia
orientationRecords(eph)
```
retrieve orientation records metadata in ephemeris associated to handler eph.
This is a vector of metadata about the ephemerides records ordered by priority. The orient methods use the highest priority ephemerides records when there are multiple records that could satisfy the target and epoch.

Each record metadata contains the following information:
- target: NAIF identifier of target.
- startEpoch: julian date of record start.
- stopEpoch: julian date of record end.
- frame : 1 for ICRF.

## Cleaning up

Because, Julia's garbage collector is lazy, you may want to free the memory managed by the context before you get rid of the reference to the context with eg:

```julia
finalize(eph1)
eph1 = Nothing
```
or after with
```julia
eph1 = Nothing
GC.gc()
```
## Error handling

By default, the CALCEPH C library prints error messages directly to the standard output but this can be modified.

The Julia wrapper provides the following interface for this purpose:
```julia
CALCEPH.setCustomHandler(f)
```
where f should be a user function taking a single argument of type String which will contain the CALCEPH error message. f should return Nothing.

To disable CALCEPH error messages printout to the console:

```julia
CALCEPH.setCustomHandler(s->Nothing)
```

To get back the default behavior:
```julia
CALCEPH.disableCustomHandler()
```
