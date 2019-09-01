"""
Bud induction window computation

Bud induction can start only at F_Tffb degree-days after vegetative growth stops (Rodriguez et al., 2011). 
The following function finds the vegetative growth end day, and add the F_Tffb parameter
(Time of first floral buds, in dd), then find the very first flowering of the year
and set the vector BudInitPeriod to TRUE between the two dates. So buds will appear
between plant F_Tffb parameter and the first flowering day only.

# Return

Nothing, modify the DataFrame of simulation `Sim` in place. See [`dynacof`](@ref) for more details.

# References
Rodríguez, D., Cure, J., Cotes, J., Gutierrez, A. and Cantor, F., 2011. A coffee agroecosystem model: I. Growth and development of
the coffee plant. Ecological Modelling, 222(19): 3626-3639.

"""
function bud_init_period!(Sim::DataFrame,Met_c::DataFrame,Parameters)
  # Compute cumulative degree-days based on previous daily DD from semi-hourly data:
  CumulDegreeDays= cumsum(Met_c.DegreeDays)
    
  # Day of vegetative growth end:
  VegetGrowthEndDay= findall(x -> x == Parameters.DVG2, Met_c.DOY)
  # Temporary variables declaration:
  CumsumRelativeToVeget= Array{Float64,2}(undef, length(VegetGrowthEndDay), length(Met_c.Date))
  CumsumRelativeToBudinit= Array{Float64,2}(undef, length(VegetGrowthEndDay), length(Met_c.Date))

  DateBudinit= zeros(Int64, length(VegetGrowthEndDay))
  DateFFlowering= zeros(Int64, length(VegetGrowthEndDay))

  for i in 1:length(VegetGrowthEndDay)
    CumsumRelativeToVeget[i,:]= CumulDegreeDays .- CumulDegreeDays[VegetGrowthEndDay[i]-1]
    # Date of first bud initialisation:
    DateBudinit[i]= findlast(CumsumRelativeToVeget[i,:] .< Parameters.F_Tffb)
    CumsumRelativeToBudinit[i,:]= CumulDegreeDays .- CumulDegreeDays[DateBudinit[i]-1]
    # Minimum date of first bud development end (i.e. without dormancy):
    BudDevelEnd= findlast(CumsumRelativeToBudinit[i,:] .< Parameters.F_buds1) - 1
    # Maximum date of first bud development end (i.e. with maximum dormancy):
    MaxDormancy= findlast(CumsumRelativeToBudinit[i,:] .< Parameters.F_buds2) - 1
    # Cumulative rainfall within the period of potential dormancy:
    CumRain= cumsum(Met_c.Rain[BudDevelEnd:MaxDormancy])
    # Effective (real) day of first buds breaking dormancy:
    BudDormancyBreakDay= BudDevelEnd + sum(CumRain .< Parameters.F_rain) - 1
    # Effective day of first flowers:
    DateFFlowering[i]= findlast(CumsumRelativeToBudinit[i,:] .< CumsumRelativeToBudinit[i,BudDormancyBreakDay] .+
                                Parameters.BudInitEnd)
    # Effective dates between which buds can appear
    Sim.BudInitPeriod[DateBudinit[i]:DateFFlowering[i]] .= true
  end

  Sim.BudInitPeriod[CumulDegreeDays .< Parameters.VF_Flowering] .= false

end