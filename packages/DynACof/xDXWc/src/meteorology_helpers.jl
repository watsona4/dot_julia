"""
    pressure_from_elevation(1000.0, 25.0, 1.5)

Computes the virtual temperature, *i.e.* the temperature at which dry air would have the same density as moist air at its actual temperature.

# Arguments  
- `Tair::Float64`: Air temperature (°C)
- `pressure::Float64`: Atmospheric pressure (kPa)
- `VPD::Float64`: Vapor pressure deficit (kPa)
- `formula::String`: (optional) Formula to be used for the calculation of esat. One of "Sonntag_1990" (Default),
"Alduchov_1996", or "Allen_1998".
- `C_to_K::Float64`: Celsius degree to Kelvin (*e.g.* 273.15)
- `pressure0::Float64`: reference atmospheric pressure at sea level (kPa)
- `Rd::Float64`: gas constant of dry air (``J\\ kg^{-1}\\ K^{-1}``), source : Foken p. 245
- `g::Float64`: gravitational acceleration (``m\\ s^{-2}``)

# Note
`C_to_K` and `epsi` can be found using `constants()`

# Returns
The atmospheric pressure (kPa)

# Examples
```julia
pressure_from_elevation(600.0, 25.0, 1.5)
```

"""
function pressure_from_elevation(elev::Float64, Tair::Float64, VPD::Float64; formula::String="Sonntag_1990",
  C_to_K::Float64= constants().Kelvin, pressure0::Float64= constants().pressure0, 
  Rd::Float64= constants().Rd, g::Float64= constants().g)::Float64

  pressure1= pressure0 / exp(g * elev / (Rd * (Tair + C_to_K)))
  Tv_K= virtual_temp(Tair, pressure1, VPD, formula = formula) + C_to_K
  pressure0 / exp(g * elev / (Rd * Tv_K))
end


"""
    diffuse_fraction(DOY::Int64, RAD::Float64, Latitude::Float64; formula::String="Spitters",Gsc::Float64=constants().Gsc)

Computes the daily diffuse fraction from the total daily incident radiation

# Arguments  
- `DOY::Int64`: Day Of Year from 1st January (day)
- `RAD::Float64`: Incident total radiation (MJ m-2 d-1)
- `Latitude::Float64`: Latitude (deg)
- `formula::String`: (Optionnal) Model type, one of `Spitters`, `Page` or `Gopinathan`
- `Gsc::Float64`: (Optionnal) The solar constant (W m-2), default to `constants().Gsc` (= 1367).

# Details 
The daily extra-terrestrial radiation at a plane parallel to the earth surface (`S0` or `H0` depending on the source) is computed following
Khorasanizadeh and Mohammadi (2016).
The daily diffuse fraction is computed following DB models from :

* Spitters et al. (1986): used in de Bilt in Netherlands, stated that their model is 
valid for a wide range of climate conditions  
* Page (1967) using the data from 10 widely-spread sites in the 40N to 40S latitude belt  
* Gopinathan and Soler (1995) from 40 widely distributed locations in the latitude range of 36S to 60N.  

# Note
`C_to_K` and `epsi` can be found using `constants()`

# Returns
``Hd/H``: the daily diffuse fraction of light (%)

# References
* Duffie, J.A. and W.A. Beckman, Solar engineering of thermal processes. 2013: John Wiley & Sons.
Gopinathan, K. and A. Soler, Diffuse radiation models and monthly-average, daily, diffuse data for
a wide latitude range. Energy, 1995. 20(7): p. 657-667.  
* Kalogirou, S.A., Solar energy engineering: processes and systems. 2013: Academic Press.
Khorasanizadeh, H. and K. Mohammadi, Diffuse solar radiation on a horizontal surface:
Reviewing and categorizing the empirical models. Renewable and Sustainable Energy Reviews,
2016. 53: p. 338-362.  
* Liu, B.Y.H. and R.C. Jordan, The interrelationship and characteristic distribution of direct,
diffuse and total solar radiation. Solar Energy, 1960. 4(3): p. 1-19.  
* Page, J. The estimation of monthly mean values of daily total short wave radiation on vertical
and inclined surfaces from sunshine records 40S-40N. in Proceedings of the United Nations
Conference on New Sources of Energy: Solar Energy, Wind Power and Geothermal Energy, Rome, Italy. 1967.  
* Spitters, C.J.T., H.A.J.M. Toussaint, and J. Goudriaan, Separating the diffuse and direct
component of global radiation and its implications for modeling canopy photosynthesis Part I.
Components of incoming radiation. Agricultural and Forest Meteorology, 1986. 38(1): p. 217-229.  

# Examples
```julia
# Daily diffuse fraction of january 1st at latitude 35 N, with a RAD of 25 MJ m-2 day-1 :
diffuse_fraction(1,25.0,35.0)
```

"""
function diffuse_fraction(DOY::Int64, RAD::Float64, Latitude::Float64, formula::String="Spitters";
    Gsc::Float64=constants().Gsc)::Float64

  S0= Rad_ext(DOY,Latitude,Gsc)

  if S0<=0
    TRANS= 0.0
  else
    TRANS = RAD/S0
  end 

  if formula=="Spitters"
    if TRANS < 0.07
        FDIF= 1.0
    elseif 0.07 <= TRANS < 0.35
        FDIF= 1.0 - 2.3 * (TRANS-0.07)^2.0
    elseif 0.35 <= TRANS <0.75
        FDIF= 1.33 - 1.46 * TRANS
    else
        FDIF= 0.23
    end
    return FDIF
  elseif formula=="Page"
    return 1.0 - 1.13 * TRANS
  elseif formula=="Gopinathan"
    return 0.91138 - 0.96225 * TRANS
  else
    error("Wrong value for formula argument. It should be one of Spitters, Page or Gopinathan.")
  end
end


"""
    Rad_ext(1000.0, 25.0, 1.5)

Computes the virtual temperature, *i.e.* the temperature at which dry air would have the same density as moist air at its actual temperature.

# Arguments  
- `DOY::Int64`: Ordinal date (integer): day of year from 1st January (day)
- `Latitude::Float64`: Latitude (deg)
- `Gsc::Float64`: The solar constant (W m-2), default to `constants().Gsc` (= 1367).

# Returns
`S0`, the daily extra-terrestrial radiation (``MJ\\ m^{-2}\\ d^{-1}``)


# References

Khorasanizadeh, H. and K. Mohammadi, Diffuse solar radiation on a horizontal surface:
Reviewing and categorizing the empirical models. Renewable and Sustainable Energy Reviews,
2016. 53: p. 338-362.

# Examples
```julia
# Daily extra-terrestrial radiation on january 1st at latitude 35 N :
Rad_ext(1,35.0)
```

"""
function Rad_ext(DOY::Int64,Latitude::Float64,Gsc::Float64=constants().Gsc)::Float64
    solar_declin= 23.45*sin°(((float(DOY)+284.0)*360.0)/365.0)
    sunset_hour_angle= acos°(-tan°(Latitude) * tan°(solar_declin))
    S0= (86400.0/π) * Gsc * (1.0 + 0.033 * cos°(float(360*DOY)/365.0)) * (cos°(Latitude) * 
        cos°(solar_declin) * sin°(sunset_hour_angle) + (π * sunset_hour_angle / 180.0) *
        sin°(Latitude) * sin°(solar_declin))
    S0*10^-6
end


"""
    sun_zenithal_angle(DOY::Int64, Latitude::Float64)

Computes the sun zenithal angle at noon (solar time).

# Arguments  
- `DOY::Int64`: Ordinal date (integer): day of year from 1st January (day)
- `Latitude::Float64`: Latitude (deg)

# Returns
`ZEN`, the sun zenithal angle (`radian`)

# References

[solartime](https://cran.r-project.org/web/packages/solartime/) R package from Thomas Wutzler, and more specificly the
`computeSunPositionDoyHour` function (considering the hour at noon).

# Examples
```julia
# Daily extra-terrestrial radiation on january 1st at latitude 35 N :
sun_zenithal_angle(1,35.0)
```
"""
function sun_zenithal_angle(DOY::Int64, Latitude::Float64)::Float64
  fracYearInRad= 2.0 * π * (DOY - 1.0)/365.24

  SolDeclRad=
  ((0.33281 - 22.984 * cos(fracYearInRad) - 
  0.3499 * cos(2.0 * fracYearInRad) - 0.1398 * cos(3.0 * fracYearInRad) + 
  3.7872 * sin(fracYearInRad) + 0.03205 * sin(2.0 * fracYearInRad) + 
  0.07187 * sin(3.0 * fracYearInRad))/180.0 * π)

SolElevRad= asin(sin(SolDeclRad) * sin(Latitude/180.0 * π) + cos(SolDeclRad) * cos(Latitude/180.0 * π))
acos(sin(SolElevRad))
end



"""
    Rad_net(DOY::Int64,RAD::Float64,Tmax::Float64,Tmin::Float64,VPD::Float64,Latitude::Float64,
     Elevation::Float64,albedo::Float64,formula::String;
     σ::Float64= constants().σ, Gsc::Float64= constants().Gsc)

Compute the daily net radiation of the system using incident radiation, air temperature, wind speed,
relative humidity and the albedo. A clear description of this methodology can be found in Allen et al. (1998)
or in An et al. (2017).

# Arguments  
- `DOY::Int64`: Ordinal day, which is the day of year from 1st January (day)
- `RAD::Float64`: Incident total radiation (MJ m-2 d-1)- `Tmax::Float64`: Maximum daily air temperature (°C)
- `Tmin::Float64`: Minimum daily air temperature (°C)
- `VPD::Float64`: Vapor pressure deficit (kPa)
- `Latitude::Float64`: Latitude (°)
- `Elevation::Float64`: Elevation (m)
- `albedo::Float64`: Shortwave surface albedo (-)
- `formula::String`: (optional) Formula to be used for the calculation of esat. One of "Sonntag_1990" (Default),
"Alduchov_1996", or "Allen_1998".
- `σ::Float64`: (sigma) Stefan-Boltzmann constant (``W\\ m^{-2} K^{-4}``), default to `constants().σ`.
- `Gsc::Float64`: The solar constant (W m-2), default to `constants().Gsc` (= 1367).

# Returns
Rn, the daily net radiation (MJ m-2 d-1)

# Details 
The daily net radiation is computed using the surface albedo. This method is only a simple estimation. Several parameters 
(ac, bc, a1 and b1) are taken from Evett et al. (2011). The net radiation is computed as: 
``Rn=(1-\\alpha)\\cdot RAD-(ac\\cdot\\frac{RAD}{Rso}+bc)\\cdot(a1+b1\\cdot ea^{0.5})\\cdot\\sigma\\cdot\\frac{T_{\\max}^4+T_{\\min}^4}{2}``
And is derived from the equation :
``Rn= (1-\\alpha)\\cdot RAD-Rln``
where \\eqn{Rln} is the net upward longwave radiation flux, \\eqn{\\alpha} is the albedo, \\eqn{R_{so}} the daily total clear sky solar
irradiance, computed as follow:
``R_{so}= (0.75+0.00002\\cdot Elevation)\\cdot R{sa}``
where ``R_{sa}`` is the daily extra-terrestrial radiation, computed using [`Rad_ext`](@ref).
The actual vapor pressure `ea` can be computed using either VPD or the relative humidity and the maximum and minimum daily
temperature. If both are provided, Rh will be used.

# References
An, N., S. Hemmati, and Y.-J. Cui, Assessment of the methods for determining net radiation at different time-scales
of meteorological variables. Journal of Rock Mechanics and Geotechnical Engineering, 2017. 9(2): p. 239-246.

# Examples
```julia
dew_point(20.0,1.0)
```

"""
function Rad_net(DOY::Int64,RAD::Float64,Tmax::Float64,Tmin::Float64,VPD::Float64,Latitude::Float64,
  Elevation::Float64,albedo::Float64,formula::String="Sonntag_1990";
  σ::Float64= constants().σ, Gsc::Float64= constants().Gsc)
  
  Rsa= Rad_ext(DOY,Latitude,Gsc)
  Rso= (0.75 + 0.00002 * Elevation) * Rsa
  ea= esat(dew_point((Tmax + Tmin) / 2.0, VPD,formula),formula)
  
  ac= 1.35
  bc= -0.35
  a1= 0.35
  b1= -0.14

  (1-albedo)*RAD-(ac*(RAD/Rso)+bc)*(a1+b1*ea^0.5)*σ*((Tmax^4+Tmin^4)/2)
end



"""
    days_without_rain(Rain::Array{Float64,1})

Computes the number of days without rain from a rainfall data `Array`. It is assumed the `Array` is sorted following ascending dates.

# Arguments  
- `Rain::Array{Float64,1}`: An `Array` of daily rainfall data (whatever the unit) in ascending day order.

# Returns
An `Array{Int64,1}` determining how many days there was without rainfall before the given day.

# Examples
```julia
rainfall= [0.0,0.0,0.0,0.0,1.0,0.0,0.0,0.2,0.6]
days_without_rain(rainfall)
```
"""
function days_without_rain(Rain::Array{Float64,1})::Array{Int64,1}
  DaysWithoutRain= zeros(length(Rain))
  is_raining = zeros(length(Rain))
  is_raining[Rain .> 0.0] .= 1
  
  for i in 1:length(Rain)
      for j in i:-1:1
          if is_raining[j] == 0
              DaysWithoutRain[i] += 1
          else
              break
          end
      end
  end
  DaysWithoutRain
end