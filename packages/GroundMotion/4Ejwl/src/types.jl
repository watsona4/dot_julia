## LICENSE
##   Copyright (c) 2018 GEOPHYSTECH LLC
##
##   Licensed under the Apache License, Version 2.0 (the "License");
##   you may not use this file except in compliance with the License.
##   You may obtain a copy of the License at
##
##       http://www.apache.org/licenses/LICENSE-2.0
##
##   Unless required by applicable law or agreed to in writing, software
##   distributed under the License is distributed on an "AS IS" BASIS,
##   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
##   See the License for the specific language governing permissions and
##   limitations under the License.

## initial release by Andrey Stepnov, email: a.stepnov@geophsytech.ru

## VS30 data point
"""
Mutable type for fill vs30 grid (Array).

  `Point_vs30(lon,lat,vs30)`

Latitude and longitude assumes degrees for WGS84 ellipsoid. `vs30` in meters per second. All fields are ::Float64.
"""
mutable struct Point_vs30
  lon::Float64
  lat::Float64
  vs30::Float64
end
"""
Mutable type for fill vs30 grid (Array) with `Dl` data. `Dl` is the top depth to the layer whose S-wave velocity is `l` (in `[m/s]`) at the site. See Morikawa Fujiwara 2013 for further reading.

  `Point_vs30(lon,lat,vs30,dl)`

Latitude and longitude assumes degrees for WGS84 ellipsoid. `vs30` in meters per second. `dl` in kilometers. All fields are ::Float64.
"""
mutable struct Point_vs30_dl
  lon::Float64
  lat::Float64
  vs30::Float64
  dl::Float64
end
## Output PGA data point
"""
Mutable type for output PGA data from GMPE modeling funtions

  Fields:
```
  lon   :: Float64 
  lat   :: Float64 
  pga   :: Float64 
```
Latitude and longitude assumes degrees for WGS84 ellipsoid. `pga` is Acceleration of gravity in percent (%g) rounded to ggg.gg.
"""
mutable struct Point_pga_out
  lon::Float64
  lat::Float64
  pga::Float64 #Acceleration of gravity  in percent (%g) rounded to ggg.gg
end
## Output PGV data point
"""
Mutable type for output PGV data from GMPE modeling funtions

  Fields:
```
  lon   :: Float64 
  lat   :: Float64 
  pgv   :: Float64 
```
Latitude and longitude assumes degrees for WGS84 ellipsoid. `pgv` is [cm/s].
"""
mutable struct Point_pgv_out
  lon::Float64
  lat::Float64
  pgv::Float64 #Acceleration of gravity in percent rounded to ggg.gg
end
## Output PSA data point
"""
Mutable type for output PSA data

  Fields:
```
  lon   :: Float64 
  lat   :: Float64 
  psa   :: Float64 
```
Latitude and longitude assumes degrees for WGS84 ellipsoid. `psa` is damped pseudo-spectral acceleration (%g) in percent rounded to ggg.gg.
"""
mutable struct Point_psa_out
  lon::Float64
  lat::Float64
  psa::Float64 # damped pseudo-spectral acceleration of gravity in percent rounded to ggg.gg (%g)
end
## earthquake location data
"""
Mutable type for earthquake location data.

  Earthquake(lat,lon,depth,local_mag,moment_mag)

Latitude and longitude assumes degrees for WGS84 ellipsoid. Depth in km.
Mw=0 in case of moment magnitude is not specified. 
All fields are ::Float64.
"""
mutable struct Earthquake
  lon::Float64 
  lat::Float64
  depth::Float64
  local_mag::Float64
  moment_mag::Float64
end
Earthquake(x,y,z,k) = Earthquake(x,y,z,k,0) # Mw usually not ready right after earthquake 
## AS2008 GMPE parameters
mutable struct Params_as2008
  a1::Float64
  a2::Float64
  a3::Float64
  a4::Float64
  a5::Float64
  a8::Float64
  a10::Float64
  a18::Float64
  b::Float64
  c::Float64
  c1::Float64
  c4::Float64
  n::Float64
  vlin::Float64
  v1::Float64
  vs30_1100::Float64
  ground_motion_type::String
end
## Si-Midorikawa 1999 GMPE parameters
mutable struct Params_simidorikawa1999
  a::Float64
  h::Float64
  d1::Float64
  d2::Float64
  d3::Float64
  e_::Float64
  k::Float64
  S1::Float64
  S2::Float64
  S3::Float64
  ground_motion_type::String
end
## Morikawa-Fujiwara 2013 GMPE parameters
mutable struct Params_mf2013
  Mw0::Float64
  a::Float64
  b::Float64
  c::Float64
  d::Float64
  e::Float64
  sigma::Float64
  pd::Float64
  Dlmin::Float64
  D0::Float64
  ps::Float64
  Vsmax::Float64
  V0::Float64
  gamma::Float64
  ASID::Bool # Anomalous Seismic Intensity Distribution
  ground_motion_type::String
end

