"""
    rH_to_VPD(0.5,20,"Allen_1998")

Conversion from relative humidity (rH) to vapor pressure deficit (VPD).

# Arguments
- `rH::Float64`: Relative humidity (-)
- `Tair::Float64`: Air temperature (°C)
- `formula::String`: (optional) Formula to be used for the calculation of esat and the slope of esat. One of "Sonntag_1990" (Default),
"Alduchov_1996", or "Allen_1998".

# Returns
VPD, the vapor pressure deficit (kPa)

# Examples
```julia
rH_to_VPD(0.5,20.0,"Allen_1998")
```

# Reference
This function is translated from the R package [bigleaf](https://bitbucket.org/juergenknauer/bigleaf/src/master/).
"""
function rH_to_VPD(rH::Float64, Tair::Float64, formula::String = "Sonntag_1990")::Float64
  if rH > 1.0
    error("Relative humidity (rH) has to be between 0 and 1")
  end
  Esat = esat(Tair,formula)
  Esat - rH * Esat
end


"""
    esat(20,"Allen_1998")

Computes the saturation vapor pressure (Esat)

# Arguments
- `Tair::Float64`: Air temperature (°C)
- `formula::String`: (optional) Formula to be used for the calculation of esat and the slope of esat. One of "Sonntag_1990" (Default),
"Alduchov_1996", or "Allen_1998".

# Returns
Esat, the saturation vapor pressure (kPa)

# Examples
```julia
esat(20.0,"Allen_1998")
```

# Reference
This function is translated from the R package [bigleaf](https://bitbucket.org/juergenknauer/bigleaf/src/master/).

"""
function esat(Tair::Float64, formula::String= "Sonntag_1990")::Float64

  if formula == "Sonntag_1990"
    a = 611.2
    b = 17.62
    c = 243.12
  elseif formula == "Alduchov_1996"
    a = 610.94
    b = 17.625
    c = 243.04
  elseif formula == "Allen_1998"
    a = 610.8
    b = 17.27
    c = 237.3
  else
    error("Wrong formula argument. The formula argument should take values of: " *
    "Sonntag_1990, Alduchov_1996 or Allen_1998")
  end

  a * exp((b * Tair)/(c + Tair))/ 1000.0
end


"""
    esat_slope(20,"Allen_1998")

Computes Δ, the slope of the saturation vapor pressure at given air temperature.

# Arguments
- `Tair::Float64`: Air temperature (°C)
- `formula::String`: (optional) Formula to be used for the calculation of esat and the slope of esat. One of "Sonntag_1990" (Default),
"Alduchov_1996", or "Allen_1998".

# Returns
Δ, the slope of the saturation vapor pressure curve at Tair (``kPa\\ K^{-1}``)

# Examples
```julia
esat_slope(20.0,"Allen_1998")
```
# Reference
This function is translated from the R package [bigleaf](https://bitbucket.org/juergenknauer/bigleaf/src/master/).
"""
function esat_slope(Tair::Float64, formula::String= "Sonntag_1990")::Float64

  if formula == "Sonntag_1990"
    a = 611.2
    b = 17.62
    c = 243.12
  elseif formula == "Alduchov_1996"
    a = 610.94
    b = 17.625
    c = 243.04
  elseif formula == "Allen_1998"
    a = 610.8
    b = 17.27
    c = 237.3
  else
    error("Wrong formula argument. The formula argument should take values of: " *
    "Sonntag_1990, Alduchov_1996 or Allen_1998")
  end

  derivative(Tair -> a * exp((b * Tair)/(c + Tair)), Tair) / 1000.0
end


"""
    dew_point(Tair::Float64, VPD::Float64, formula::String="Sonntag_1990")
Computes the dew point, *i.e.* the temperature to which air must be cooled to become saturated 

# Arguments  
- `Tair::Float64`: Air temperature (°C)
- `VPD::Float64`: Vapor pressure deficit (kPa)
- `formula::String`: (optional) Formula to be used for the calculation of esat. One of "Sonntag_1990" (Default),
"Alduchov_1996", or "Allen_1998".

# Returns
T_d, the dew point (°C)

# Examples
```julia
dew_point(20.0,1.0)
```

"""
function dew_point(Tair::Float64, VPD::Float64, formula::String="Sonntag_1990")::Float64
  ea= VPD_to_e(VPD, Tair, formula)
  minimizer(optimize(Td -> abs(ea - esat(Td, formula)), -50.0, 50.0))
  # optimize(f, lower, upper, method; kwargs...)
end



"""
    virtual_temp(Tair::Float64, pressure::Float64, VPD::Float64; formula::String="Sonntag_1990",C_to_K::Float64=constants().Kelvin, epsi::Float64= constants().epsi)::Float64
Computes the virtual temperature, *i.e.* the temperature at which dry air would have the same density as moist air at its actual temperature.

# Arguments  
- `Tair::Float64`: Air temperature (°C)
- `pressure::Float64`: Atmospheric pressure (kPa)
- `VPD::Float64`: Vapor pressure deficit (kPa)
- `formula::String`: (optional) Formula to be used for the calculation of esat. One of "Sonntag_1990" (Default),
"Alduchov_1996", or "Allen_1998".
- `C_to_K::Float64`: Celsius degree to Kelvin (*e.g.* 273.15)
- `epsi::Float64`: Ratio of the molecular weight of water vapor to dry air 

# Note
`C_to_K` and `epsi` can be found using `constants()`

# Returns
T_v, the virtual temperature (°C)

# Examples
```julia
virtual_temp(25.0, 1010.0, 1.5, "Sonntag_1990")
```
"""
function virtual_temp(Tair::Float64, pressure::Float64, VPD::Float64; formula::String="Sonntag_1990",
   C_to_K::Float64=constants().Kelvin, epsi::Float64= constants().epsi)::Float64
  e = VPD_to_e(VPD, Tair, "Sonntag_1990")
  Tair = Tair + C_to_K
  Tv = Tair/(1 - (1 - epsi) * e/pressure)
  Tv - C_to_K
end


"""
    VPD_to_e(1.5, 25.0, "Sonntag_1990")

Computes the vapor pressure (e) from the vapor pressure deficit (VPD) and the air temperature (Tair)

# Arguments
- `VPD::Float64`: Vapor pressure deficit (kPa)
- `Tair::Float64`: Air temperature (°C)
- `formula::String`: (optional) Formula to be used for the calculation of esat. One of "Sonntag_1990" (Default),
"Alduchov_1996", or "Allen_1998".

# Returns
e, the vapor pressure (kPa)

# Examples
```julia
VPD_to_e(1.5, 25.0, "Sonntag_1990")
```

# Reference
This function is translated from the R package [bigleaf](https://bitbucket.org/juergenknauer/bigleaf/src/master/).

"""
function VPD_to_e(VPD::Float64, Tair::Float64, formula::String="Sonntag_1990")::Float64
  esat(Tair, formula) - VPD
end



"""
    GDD(25.,5.0,28.0)

Compute the daily growing degree days (GDD) directly from the daily mean
temperature.

# Arguments
- `Tmean::Float64`: Optional. Average daily temperature (Celsius degree).
- `MinTT::Float64`: Minimum temperature threshold, also called base temperature (Celsius degree), default to 5.
- `MaxTT::Float64`: Maximum temperature threshold (Celsius degree), optional, default to 30.0

# Return
GDD: Growing degree days (Celsius degree)

# Examples
```julia
GDD(25.0,5.0,28.0)
20.0
GDD(5.0,5.0,28.0)
0.0
```
"""
function GDD(Tmean::Float64,MinTT::Float64,MaxTT::Float64)::Float64
  DD= Tmean-MinTT
  if (DD < 0.0) || (DD > (MaxTT-MinTT))
    DD= 0.0
  end
  DD
end

"""
    GDD(30.0,27.0,5.0,27.0)

Compute the daily growing degree days (GDD) using the maximum and minimum daily temperature.

# Arguments
- `Tmax::Float64`: Maximum daily temperature (Celsius degree)
- `Tmin::Float64`: Minimum daily temperature (Celsius degree)
- `MinTT::Float64`: Minimum temperature threshold, also called base temperature (Celsius degree), default to 5.
- `MaxTT::Float64`: Maximum temperature threshold (Celsius degree), optional, default to 30.0

Please keep in mind that this function gives an approximation of the degree days.
GDD are normally computed as the integral of hourly (or less) values.

# Return
GDD: Growing degree days (Celsius degree)

# Examples
```julia
GDD(30.0,27.0,5.0,27.0)
0.0
```
"""
function GDD(Tmax::Float64,Tmin::Float64,MinTT::Float64,MaxTT::Float64)::Float64
 Tmean= (Tmax + Tmin) / 2.0
 GDD(Tmean,MinTT,MaxTT)
end


"""
    paliv_dis(Age_Max::Int64,P_Start::Float64,P_End::Float64,k::Float64)

Distributes the percentage of living tissue alonf the lifespan

# Arguments
- `Age_Max::Int64`: Maximum age of the organ (year)
- `P_Start::Float64`: Percentage of living tissue at first age (% of dry mass)
- `P_End::Float64`: Percentage of living tissue at last age (% of dry mass)
- `k::Float64`: Rate between P_Start and P_End

The percentage of living tissue is computed as follows:
``P_{End}+\\left((P_{Start}-P_{End})\\cdot e^{seq(0,-k,length.out=Age_{Max})}\\right)``

# Return
The living tissue at each age in % of organ dry mass in the form of a `DataFrame`

# Examples
```julia
paliv_dis(40,0.4,0.05,5.0)

40×2 DataFrame
│ Row │ Age   │ Palive          │
│     │ Int64 │ Float64         │
├─────┼───────┼─────────────────┤
│ 1   │ 1     │ 0.4             │
│ 2   │ 2     │ 0.357886        │
│ 3   │ 3     │ 0.320839        │
│ 4   │ 4     │ 0.288249        │
⋮
│ 36  │ 36    │ 0.0539383       │
│ 37  │ 37    │ 0.0534644       │
│ 38  │ 38    │ 0.0530476       │
│ 39  │ 39    │ 0.0526809       │
│ 40  │ 40    │ 0.0523583       │

```
"""
function paliv_dis(Age_Max::Int64,P_Start::Float64,P_End::Float64,k::Float64)::DataFrame
  DataFrame(Age= 1:Age_Max, Palive= P_End .+ ((P_Start .- P_End) .* exp.(collect(range(0, stop = -k, length = Age_Max)))))
end


"""
    PENMON(;Rn,Wind,Tair,ZHT,Z_top,Pressure,Gs,VPD,LAI,extwind=0,wleaf=0.068,Parameters= constants())
# Evapotranspiration

Compute the daily evaporation or transpiration of the surface using the Penman-Monteith equation.

# Arguments

- `Rn::Float64`:          Net radiation (MJ m-2 d-1)
- `Wind::Float64`:        Wind speed (m s-1)
- `Tair::Float64`:        Air temperature (Celsius degree)
- `ZHT::Float64`:         Wind measurement height (m)
- `Z_top::Float64`:       Canopy top height (m)
- `Pressure::Float64`:    Atmospheric pressure (hPa)
- `Gs::Float64`:          Stomatal conductance (mol m-2 s-1)
- `VPD::Float64`:         Vapor pressure deficit (kPa)
- `LAI::Float64`:         Leaf area index of the upper layer (m2 leaf m-2 soil)
- `extwind::Float64`:     Extinction coefficient. Default: `0`, no extinction.
- `wleaf::Float64`:       Average leaf width (m)
- `Parameters`:  Constant parameters, default to [`constants`](@ref), if different values are needed, simply make a named tuple with:
    + cp: specific heat of air for constant pressure (J K-1 kg-1)
    + Rgas: universal gas constant (J mol-1 K-1)
    + Kelvin: conversion degree Celsius to Kelvin
    + H2OMW: conversion from kg to mol for H2O (kg mol-1)

All arguments are named. 

# Details
The daily evapotranspiration is computed using the Penman-Monteith equation, and a set of conductances as :
```ET=\\frac{Δ\\cdot Rn\\cdot10^6+ρ\\cdot cp\\cdot\\frac{VPD}{10\\ }\\cdot GH}{\\ Δ +\\frac{\\gamma}{λ\\ }\\cdot(1+\\frac{GH}{GV})}\\ }```
where Δ is the slope of the saturation vapor pressure curve (kPa K-1), ρ is the air density (kg m-3), `GH` the canopy boundary
layer conductance (m s-1), γ the psychrometric constant (kPa K-1) and `GV` the boundary + stomatal conductance to water vapour
(m s-1). To simulate evaporation, the input stomatal conductance `Gs` can be set to nearly infinite (e.g. ```Gs= 1\\cdot e^9```).

@note If `wind=0`, it is replaced by a low value of `0.01`
# Return
**ET**, the daily (evapo|transpi)ration (mm d-1)

# References
Allen R.G., Pereira L.S., Raes D., Smith M., 1998: Crop evapotranspiration - Guidelines for computing crop water requirements - FAO
Irrigation and drainage paper 56.

# See also
[`bigleaf::potential.ET`](https://rdrr.io/cran/bigleaf/man/potential.ET.html) and the [MAESPA model](https://maespa.github.io/)

# Examples
```julia
# leaf evaporation of a forest :
PENMON(Rn= 12.0, Wind= 0.5, Tair= 16.0, ZHT= 26.0, Z_top= 25.0, Pressure= 900.0, Gs = 1E09, VPD= 2.41,
       LAI=3.0, extwind= 0.58, wleaf=0.068)
```
"""
function PENMON(;Rn,Wind,Tair,ZHT,Z_top,Pressure,Gs,VPD,LAI,extwind=0,wleaf=0.068,Parameters= constants())
  if Wind < 1E-9
    Wind= 0.01
  end
  CMOLAR = (Pressure * 100.0) / (Parameters.Rgas * (Tair + Parameters.Kelvin))

  GB = (1.0 / (1.0 / G_bulk(Wind= Wind, ZHT= ZHT, Z_top= Z_top, LAI= LAI, extwind= extwind)+
               1.0 / Gb_h(Wind= Wind, wleaf= wleaf,LAI_lay= LAI, LAI_abv= 0, ZHT= ZHT,Z_top= Z_top, extwind= extwind))) * CMOLAR
  # in mol m-2 s-1

  GH = GB

  GV = 1.0 / (1.0 / Gs + 1.0 / GB)

  gamma  = psychrometric_constant(Tair,Pressure/10.0)
  Delta  = esat_slope(Tair,"Allen_1998")
  rho    = air_density(Tair,Pressure / 10.0)

  LE_ref = (Delta * Rn * 10^6 + rho * Parameters.cp * (VPD / 10.0) * GH) / (Delta + gamma * (1.0 + GH / GV))
  ET_ref = LE_to_ET(LE_ref,Tair)
  
  return ET_ref
end

"""
# Psychrometric constant (γ)

# Arguments
- `Tair::Float64`: Air temperature (deg C)
- `pressure::Float64`: Atmospheric pressure (kPa)
- `Parameters`:  Constant parameters, default to [`constants`](@ref), if different values are needed, simply make a named tuple with:
    + cp: specific heat of air for constant pressure (J K-1 kg-1) 
    + epsi: ratio of the molecular weight of water vapor to dry air (-)

# Details
The psychrometric constant (γ) is given as: γ = cp * pressure / (epsi * λ)
where λ is the latent heat of vaporization (J kg-1), as calculated from [`latent_heat_vaporization`](@ref).

# Return
γ -	the psychrometric constant (kPa K-1)

# References

This function is adapted from the code of [`bigleaf::psychrometric.constant`](https://rdrr.io/cran/bigleaf/man/psychrometric.constant.html)

- Monteith J.L., Unsworth M.H., 2008: Principles of Environmental Physics. 3rd Edition. Academic Press, London.

# Examples
```julia
psychrometric_constant(20.0, 100.0)  
```
"""
function psychrometric_constant(Tair::Float64, pressure::Float64, Parameters = constants())::Float64
  λ= latent_heat_vaporization(Tair)
  (Parameters.cp * pressure)/(Parameters.epsi * λ)
end

"""
# Latent Heat of Vaporization

Computes the latent heat of vaporization as a function of air temperature.

# Arguments

- `Tair::Float64`: Air temperature (deg C)

# Details
The following formula is used: λ = (2.501 - 0.00237*Tair) * 10^6

# Return 
λ -	The latent heat of vaporization (J kg-1)

# References
This function is adapted from the code of [`bigleaf::latent.heat.vaporization`](https://rdrr.io/cran/bigleaf/man/latent.heat.vaporization.html)
- Stull, B., 1988: An Introduction to Boundary Layer Meteorology (p.641) Kluwer Academic Publishers, Dordrecht, Netherlands
- Foken, T, 2008: Micrometeorology. Springer, Berlin, Germany.

# Examples
```julia
latent_heat_vaporization(20.0)  
```
"""
function latent_heat_vaporization(Tair::Float64, k1::Float64= 2.501, k2::Float64= 0.00237)::Float64
  (k1 - k2 * Tair) * 1e+06
end

"""
# Air Density (ρ)

Computes the air density of moist air from air temperature and pressure.

# Arguments

- `Tair::Float64`: Air temperature (deg C)
- `pressure::Float64`: Atmospheric pressure (kPa)
- `Parameters`:  Constant parameters, default to [`constants`](@ref), if different values are needed, simply make a named tuple with:
    + Kelvin: conversion degC to Kelvin 
    + Rd: gas constant of dry air (J kg-1 K-1) 

# Details
Air density (ρ) is calculated as: ρ = pressure / (Rd * Tair)

# Return
ρ: the air density (kg m-3)

# References
This function is adapted from the code of [`bigleaf::air.density`](https://rdrr.io/cran/bigleaf/man/air.density.html)
- Foken, T, 2008: Micrometeorology. Springer, Berlin, Germany.

# Examples
```julia
# air density at 25degC and standard pressure (101.325kPa)
air_density(25.0,101.325)
```
"""
function air_density(Tair::Float64, pressure::Float64, Parameters = constants())::Float64
    Tair_K= Tair + Parameters.Kelvin
    pressure_Pa= pressure * 1000
    pressure_Pa/(Parameters.Rd * Tair_K)
end


"""
Conversion between Latent Heat Flux and Evapotranspiration

# Description
Converts evaporative water flux from mass (ET, evapotranspiration) to energy (LE, latent heat flux) units, or vice versa.

# Arguments

- `LE::Float64`: Latent heat flux (W m-2)
- `ET::Float64`: Evapotranspiration (kg m-2 s-1)
- `Tair::Float64`: Air temperature (deg C)

# Details
The conversions are given by:
- ET = LE/λ
- LE = λ ⋅ ET
where λ is the latent heat of vaporization (J kg-1) as calculated by [`latent_heat_vaporization`](@ref).

# References
These functions are adapted from the code of [`bigleaf::LE.to.ET`](https://rdrr.io/cran/bigleaf/man/LE.to.ET.html)

# Examples
```julia
# LE of 200 Wm-2 and air temperature of 25degC
LE_to_ET(200.0,25.0)
```
"""
LE_to_ET, ET_to_LE

function LE_to_ET(LE::Float64, Tair::Float64)::Float64
  LE / latent_heat_vaporization(Tair)
end


function ET_to_LE(ET::Float64, Tair::Float64)::Float64
  ET * latent_heat_vaporization(Tair)
end



"""
Temperature-dependent correction coefficient for nodes (CN)

Computes the temperature-dependent correction coefficient for green nodes in the coffee plant according to Drinnan and Menzel (1995).

# Arguments 
- `Tair::Float64` The average air temperature during the vegetative growing period

# Return
The correction coefficient to compute the number of green nodes in the coffee (see Eq. 26 from Vezy et al. (in prep.))

# References
- Drinnan, J. and C. Menzel, Temperature affects vegetative growth and flowering of coffee (Coffea arabica L.). 
Journal of Horticultural Science, 1995. 70(1): p. 25-34.

# Examples
```julia
CN(25.0)
```
"""
function CN(Tair)
  (0.4194773 + 0.2631364*Tair - 0.0226364*Tair^2 + 0.0005455*Tair^3)
end


"""
Fruit sucrose accumulation

Computes a the sucrose accumulation into coffee fruits through time following a logistic curve

# Arguments 

- `x::Float64`:  Cumulated degree days
- `a::Float64`:  Parameter
- `b::Float64`:  Parameter
- `x0::Float64`: Mid-maturation (logistic function inflexion point)
- `y0::Float64`: Sucrose content at the beginning (in %, 1-100)

# Return
The sucrose content, in % of fruit total dry mass.

# References
Pezzopane, J., et al., Agrometeorological parameters for prediction of the maturation period of Arabica coffee cultivars. 
International Journal of Biometeorology, 2012. 56(5): p. 843-851.

# Examples
```julia
Sucrose_cont_perc(1:10,5.3207,-28.5561,191,3.5)
```
"""
function Sucrose_cont_perc(x,a,b,x0,y0)
  (y0 + a / (1.0 + (x / x0)^b)) / 100
end