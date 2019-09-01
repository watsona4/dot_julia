"""
Meteorology(file = NULL, period = NULL, Parameters = Import_Parameters())

Import the meteorology data, check its format, and eventually compute missing variables.
# Arguments
- `file::String`: The daily time-step meteorology file path.
- `period::Array{String,1}`: A vector of two character string as POSIX dates that correspond to the min and max dates for the desired time period to be returned.
The default value ["0000-01-01", "0000-01-02"] makes the function take the min and max values from the meteorology file.
- `Parameters`: A named tuple with parameter values (see [`import_parameters`](@ref)):
    + Start_Date: optional, the Posixct date of the first meteo file record. Only needed if the Date column is missing.
    + FPAR      : Fraction of global radiation corresponding to PAR radiation, only needed if either RAD or PAR is missing.
    + Elevation : elevation of the site (m), only needed if atmospheric pressure is missing
    + Latitude  : latitude of the site (degree), only needed if the diffuse fraction of light is missing
    + WindSpeed : constant wind speed (m s-1), only needed if windspeed is missing
    + CO2       : constant atmospheric ``CO_2`` concentration (ppm), only needed if ``CO_2`` is missing
    + MinTT     : minimum temperature threshold for degree days computing (Celsius), see [GDD()]
    + MaxTT     : maximum temperature threshold for degree days computing (Celsius), see [GDD()]
    + albedo    : site shortwave surface albedo, only needed if net radiation is missing, see [Rad_net()]

# Details
The imported file is expected to be at daily time-step. The albedo is used to compute the system net radiation that is then
used to compute the soil net radiation using an extinction coefficient with the plot LAI following the Shuttleworth & Wallace (1985)
formulation. This computation is likely to be depreciated in the near future as the computation has been replaced by a metamodel. It
is kept for information for the moment.

| *Var*           | *unit*      | *Definition*                                 | *If missing*                                                       |
|-----------------|-------------|----------------------------------------------|--------------------------------------------------------------------|
| Date            | POSIXct     | Date in POSIXct format                       | Computed from start date parameter, or set a dummy date if missing |
| year            | year        | Year of the simulation                       | Computed from Date                                                 |
| DOY             | day         | day of the year                              | Computed from Date                                                 |
| Rain            | mm          | Rainfall                                     | Assume no rain                                                     |
| Tair            | Celsius     | Air temperature (above canopy)               | Computed from Tmax and Tmin                                        |
| Tmax            | Celsius     | Maximum air temperature during the day       | Required (error)                                                   |
| Tmin            | Celsius     | Minimum air temperature during the day       | Required (error)                                                   |
| RH              | `%`          | Relative humidity                            | Not used, but prefered over VPD for Rn computation                |
| RAD             | MJ m-2 d-1  | Incident shortwave radiation                 | Computed from PAR                                                  |
| Pressure        | hPa         | Atmospheric pressure                         | Computed from VPD, Tair and Elevation, or alternatively from Tair and Elevation. |
| WindSpeed       | m s-1       | Wind speed                                   | Taken as constant: `Parameters -> WindSpeed`                       |
| CO2             | ppm         | Atmospheric CO2 concentration                | Taken as constant: `Parameters -> CO2`                             |
| DegreeDays      | Celsius     | Growing degree days                          | Computed using [`GDD`](@ref)                                             |
| PAR             | MJ m-2 d-1  | Incident photosynthetically active radiation | Computed from RAD                                                  |
| FDiff           | Fraction    | Diffuse light fraction                       | Computed using [`diffuse_fraction`](@ref) using Spitters et al. (1986) formula  |
| VPD             | hPa         | Vapor pressure deficit                       | Computed from RH                                                   |
| Rn              | MJ m-2 d-1  | Net radiation (will be depreciated)          | Computed using [`Rad_net`](@ref) with RH, or VPD                         |
| DaysWithoutRain | day         | Number of consecutive days with no rainfall  | Computed from Rain                                                 |
| Air_Density     | kg m-3      | Air density of moist air (ρ) above canopy | Computed using [`air_density`](@ref)                       |
| ZEN             | radian      | Solar zenithal angle at noon                 | Computed from Date, Latitude, Longitude and Timezone               |
    
# Returns
A daily meteorology DataFrame.

See also: [`dynacof`](@ref)

# Examples
```julia
# Using the example meteorology from the `DynACof.jl_inputs` repository:
file= download("https://raw.githubusercontent.com/VEZY/DynACof.jl_inputs/master/meteorology.txt")
Meteo= meteorology(file,import_parameters())
# NB: `import_parameters` without arguments uses the package default values
rm(file)
```
"""
function meteorology(file::String, Parameters, period::Array{String,1}= ["0000-01-01", "0000-01-02"])::DataFrame
    period_date= Dates.Date.(period)

    MetData= CSV.read(file; copycols=true);

    if is_missing(MetData,"Date")
        if !is_missing(Parameters,"Start_Date")
            MetData[:Date] = collect(Dates.Date(Parameters.Start_Date):Dates.Day(1):(Dates.Date(Parameters.Start_Date) + Dates.Day(nrow(MetData)-1)))
            warn_var("Date","Start_Date from Parameters","warn")
        else
            MetData[:Date] = collect(Dates.Date("2000-01-01"):Dates.Day(1):(Dates.Date(Dates.Date("2000-01-01")) + Dates.Day(nrow(MetData)-1)))
            warn_var("Date","dummy 2000-01-01", "warn")
        end
    end

    if is_missing(MetData,"DOY")
        MetData[:DOY] = dayofyear.(MetData.Date)
        warn_var("DOY","MetData.Date","warn")
    end

    if is_missing(MetData,"year")
        MetData[:year] = year.(MetData.Date)
        warn_var("year","MetData.Date","warn")
    end

    if period != ["0000-01-01", "0000-01-02"]
        if period_date[1] < minimum(MetData.Date) || period_date[2] > maximum(MetData.Date)
            error("Given period is not covered by the meteorology file")
        else
            MetData= MetData[period_date[1] .<= MetData.Date .<= period_date[2], :]
        end
    end

    if is_missing(MetData,"RAD")
        if !is_missing(MetData,"PAR")
            MetData[:RAD] = MetData[:PAR] ./ Parameters.FPAR
            warn_var("RAD", "PAR", "warn")
        else
            warn_var("RAD", "PAR", "error")
        end
    end

    if is_missing(MetData,"PAR")
        if !is_missing(MetData,"RAD")
            MetData[:PAR] = MetData[:RAD] .* Parameters.FPAR
            warn_var("PAR", "RAD", "warn")
        else
            warn_var("PAR", "RAD", "error")
        end
    end
    MetData.PAR[MetData.PAR.<0.1, :] .= 0.1

    if is_missing(MetData,"Tmin") || is_missing(MetData,"Tmax")
        warn_var("Tmin and/or Tmax","error")
    end

    if is_missing(MetData,"Tair")
        MetData[:Tair] = (MetData.Tmax .+ MetData.Tmin) ./ 2.0
        warn_var("Tair","the equation (MetData.Tmax-MetData.Tmin)/2","warn")
    end

    if is_missing(MetData,"VPD")
        if !is_missing(MetData,"RH")
            MetData[:VPD] = rH_to_VPD.(MetData.RH ./ 100.0, MetData.Tair) .* 10.0 # hPa
            warn_var("VPD","RH and Tair using bigleaf::rH.to.VPD","warn")
        else
            warn_var("VPD","RH","error")
        end
    end

    if is_missing(MetData,"Pressure")
        if !is_missing(Parameters,"Elevation")
            MetData[:Pressure] = pressure_from_elevation.(Parameters.Elevation, MetData.Tair, MetData.VPD) .* 10
            # Return in kPa
            warn_var("Pressure","Elevation, Tair and VPD using pressure_from_elevation","warn")
        else
            warn_var("Pressure","Elevation","error")
        end
    end

    # Missing rain:
    if is_missing(MetData,"Rain")
        MetData[:Rain] .= 0.0
        warn_var("Rain","constant (= 0, assuming no rain)","warn")
    end

    # Missing wind speed:
    if is_missing(MetData,"WindSpeed")
        if !is_missing(Parameters,"WindSpeed")
            MetData[:WindSpeed] = Parameters.WindSpeed # assume constant windspeed
            warn_var("WindSpeed","constant (= WindSpeed from Parameters )","warn")
        else
            warn_var("WindSpeed",  "WindSpeed from Parameters (constant value)","error")
        end
    end

    MetData.WindSpeed[MetData.WindSpeed.<0.01, :] .= 0.01

    # Missing atmospheric CO2 concentration:
    if is_missing(MetData,"CO2")
        if !is_missing(Parameters,"CO2")
            MetData[:CO2] = Parameters.CO2 # assume constant CO2
            warn_var("CO2","constant (= CO2 from Parameters)","warn")
        else
            warn_var("WindSpeed",  "CO2 from Parameters (constant value)","error")
        end
    end

    # Missing DegreeDays:
    if is_missing(MetData,"DegreeDays")
        MetData[:DegreeDays] = GDD.(MetData.Tmax, MetData.Tmin, Parameters.MinTT, Parameters.MaxTT)
        warn_var("DegreeDays","Tmax, Tmin and MinTT","warn")
    end

    # Missing diffuse fraction:
    if is_missing(MetData,"FDiff")
        MetData[:FDiff] = diffuse_fraction.(MetData.DOY, MetData.RAD, Parameters.Latitude, "Spitters")
        warn_var("FDiff","DOY, RAD and Latitude using diffuse_fraction()","warn")
    end

    # Solar zenithal angle at noon (radian):
    MetData.ZEN= sun_zenithal_angle.(MetData.DOY,Parameters.Latitude)

    # Compute net radiation using the Allen et al. (1998) equation :
    MetData.Rn= Rad_net.(MetData.DOY,MetData.RAD,MetData.Tmax,MetData.Tmin,MetData.VPD/10.0,
    Parameters.Elevation,Parameters.Latitude,Parameters.albedo)

    # Number of days without rainfall:
    MetData.DaysWithoutRain= days_without_rain(MetData.Rain)

    printstyled("Meteo computation done \n", bold= true, color= :light_green)
    return MetData
end
