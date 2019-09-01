"""
Physical constants used in the DynACof package

This function defines the following constants:
- cp: specific heat of air for constant pressure (``J\\ K^{-1}\\ kg^{-1}``), Source: Allen 1998 FAO Eq. 8 p. 32
- epsi: Ratio of the molecular weight of water vapor to dry air (=Mw/Md)
- pressure0: reference atmospheric pressure at sea level (kPa)
- FPAR: Fraction of global radiation that is PAR (source: MAESPA model)
- g: gravitational acceleration (``m\\ s^{-2}``)
- Rd: gas constant of dry air (``J\\ kg^{-1}\\ K^{-1}``), source : Foken p. 245
- Rgas: universal gas constant (``J\\ mol^{-1}\\ K^{-1}``)
- Kelvin: conversion degree Celsius to Kelvin
- vonkarman: von Karman constant (-)
- MJ_to_W: coefficient to convert MJ into W (``W\\ MJ^{-1}``)
- Gsc: solar constant (``W\\ m^{-2}=J\\ m^{-2}\\ s^{-1}``), source : Khorasanizadeh and Mohammadi (2016)
- σ (sigma): Stefan-Boltzmann constant (``W\\ m^{-2}\\ K^{-4}``)
- H2OMW: Conversion factor from kg to mol for H2O (``kg\\ mol^{-1}``)
- W_umol: Conversion factor from watt to micromole for H2O (``W\\ \\mu mol^{-1}``)
- λ (lambda): Latent heat of vaporization (``MJ\\ kg_{H2O}^{-1}``)
- cl: Drag coefficient per unit leaf area (``m\\ s^{-1}``)
- Dheat: Molecular diffusivity for heat (``m\\ s^{-1}``)

Values are partly burrowed from [bigleaf::bigleaf.constants()](https://www.rdocumentation.org/packages/bigleaf/versions/0.7.0/topics/bigleaf.constants)

# References
- Allen, R. G., et al. (1998). "Crop evapotranspiration-Guidelines for computing crop water requirements-FAO Irrigation and drainage paper 56."  300(9): D05109.
- Foken, T, 2008: Micrometeorology. Springer, Berlin, Germany.
- Khorasanizadeh, H. and K. Mohammadi (2016). "Diffuse solar radiation on a horizontal surface: Reviewing and categorizing the empirical models." Renewable and Sustainable Energy Reviews 53: 338-362.
"""
Base.@kwdef struct constants
    cp::Float64= 1013*10^-6
    epsi::Float64= 0.622 
    pressure0::Float64 = 101.325
    FPAR::Float64      = 0.5
    g::Float64         = 9.81
    Rd::Float64        = 287.0586
    Rgas::Float64      = 8.314
    Kelvin::Float64    = 273.15
    vonkarman::Float64 = 0.41
    MJ_to_W::Float64   = 10^-6
    Gsc::Float64       = 1367.0            # also found 1366 in Kalogirou (2013)
    σ::Float64         = 5.670367e-08
    H2OMW::Float64     = 18.e-3
    W_umol::Float64    = 4.57 
    λ::Float64         = 2.45
    cl::Float64        = 0.4
    Dheat::Float64     = 21.5e-6
end


Base.@kwdef struct site
    Location::String   = "Aquiares"     # Site location name (optional)
    Start_Date::String = "1979/01/01"   # Start date of the meteo data only used if "Date" is missing from input Meteorology (optionnal)
    Latitude::Float64  = 9.93833        # Latitude (degree)
    Longitude::Float64 = -83.72861      # Longitude (degredd)
    TimezoneCF::Int64  = 6              # Time Zone
    Elevation::Float64 = 1040.0         # Elevation (m)
    ZHT::Float64       = 25.0           # Measurment height (m)
    extwind::Float64   = 0.58           # Wind extinction coefficient (-) used to compute the wind speed in the considered layer. Measured on site.
    albedo::Float64    = 0.144          # Site albedo computed using MAESPA.
end

Base.@kwdef struct soil
    TotalDepth::Float64      = 3.75     # Total soil depth (m)
    Wm1::Float64             = 210.0    # Minimum water content of the first layer (mm)
    Wm2::Float64             = 58.0     # Minimum water content of the second layer (mm)
    Wm3::Float64             = 64.0     # Minimum water content of the third layer (mm)
    Wf1::Float64             = 290.0    # Field capacity of the first layer (mm)
    Wf2::Float64             = 66.0     # Field capacity of the second layer (mm)
    Wf3::Float64             = 69.0     # Field capacity of the third layer (mm)
    EWMtot::Float64          = 93.0     # = (Wf1-Wm1)+(Wf2-Wm2)+(Wf3-Wm3) (mm)
    IntercSlope::Float64     = 0.2      # Rainfall interception coefficient (mm LAI-1)
    WSurfResMax::Float64     = 120.0    # Maximum soil water level at the surface reservoir. Above this value excess rainfall runs-off inmediately (mm)
    fc::Float64              = 13.4     # Minimum infiltration capacity (mm d-1)
    alpha::Float64           = 101.561  # Multiplicative coefficient for the maximum infiltration capacity (alpha >= 1)
    fo::Float64              = 1360.917 # Maximum infiltration capacity (mmd-1) = fc*alpha
    kB::Float64              = 0.038079 # Discharge coefficient for surface runoff from surface reservoir (d-1)
    k_Rn::Float64            = 0.283    # Radiation extinction coefficient. Source: Shuttleworth and wallace 1985 p. 851
    Soil_LE_p::Float64       = 0.70     # Partitioning of the available energy between LE and H for the soil. Source: MAESPA simulation
    PSIE::Float64            = -0.0002580542 # Average PSIE used for soil water potential through Campbell (1974) equation (MPa).
    PoreFrac::Float64        = 0.4      # Average pore fraction of the soil IDEM
    B::Float64               = 4.71     # Average b of the soil IDEM
    RootFraction1::Float64   = 0.87     # Root fraction in the first layer (compared to total root biomass)
    RootFraction2::Float64   = 0.069    # Root fraction in the second layer
    RootFraction3::Float64   = 0.061    # Root fraction in the third layer
    REWc::Float64            = 0.40     # Constant critical relative extractable water. Source Granier et al. 1999 Biljou
    Metamodels_soil = Metamodels_soil # Default metamodels from the package. If you want to update them, modify this function:
end

function Metamodels_soil(Sim::DataFrame,Met_c::DataFrame,i::Int64)
    Sim.Rn_Soil[i]= -1.102 + 1.597 * Sim.PAR_Trans[i] + 1.391 * sqrt(1.0 - Met_c.FDiff[i])
end

Base.@kwdef struct coffee
    Stocking_Coffee::Float64   = 5580.0     # Coffee density at planting (plant ha-1)
    AgeCoffeeMin::Int64        = 1          # minimum coffee stand age
    AgeCoffeeMax::Int64        = 40         # maximum coffee stand age (start a new rotation after)
    SLA::Float64               = 10.97      # Specific Leaf Area (m-2 kg-1 dry mass)
    wleaf::Float64             = 0.068      # Leaf width (m)
    DELM::Float64              = 7.0        # Max leaf carbon demand (gC plant-1 d-1)
    LAI_max::Float64           = 6.0        # Max measured LAI to compute leaf demand. (measured= 5.56)
    Height_Coffee::Float64     = 2.0        # Average coffee canopy height (m) used for aerodynamic conductance.
    D_pruning::Int64           = 74         # day of year of pruning
    MeanAgePruning::Int64      = 5          # Age of first pruning (year)
    LeafPruningRate::Float64   = 0.6        # how much leaves are pruned (ratio)
    WoodPruningRate::Float64   = 1.0/3.0    # how much branches wood are pruned (ratio)
    k_Dif::Float64             = 0.4289     # Light extinction coefficient for diffuse light (-) computed from MAESPA
    k_Dir::Float64             = 0.3579     # Light extinction coefficient for direct light (-) computed from MAESPA
    kres::Float64              = 0.08       # Maximum carbon proportion extracted from reserves mass per day
    DVG1::Int64                = 105        # Day of year for the beginning of the Vegetative Growing Season
    DVG2::Int64                = 244        # Day of year for the end of the Vegetative Growing Season
    MinTT::Float64             = 10.0       # Minimum temperature threshold (deg C) for degree days computation
    MaxTT::Float64             = 40.0       # Maximum temperature threshold (deg C) for degree days computation (if any)
    RNL_base::Float64          = 91.2       # Nodes per LAI unit at the reference 20 Celsius degrees following Drinnan & Menzel (1995)
    VF_Flowering::Float64      = 5500.0     # Very first flowering (dd) source: Rodriguez et al. (2001)
    F_buds1::Float64           = 840.0      # Bud development stage 1 (2) source: PhD Louise Meylan p.58.
    F_buds2::Float64           = 2562.0     # Bud development stage 2 (dd)
    a_bud::Float64             = 0.004      # Parameter for bud initiation from Eq. 12 in Rodriguez et al. (2001)
    b_bud::Float64             = -0.0000041 # Parameter for bud initiation from Eq. 12 in Rodriguez et al. (2001)
    F_Tffb::Float64            = 4000.0     # Time of first floral buds (Rodriguez et al. 2001).
    a_p::Float64               = 5.78       # Parameter for bud dormancy break from Rodriguez et al. (2011)
    b_p::Float64               = 1.90       # Parameter for bud dormancy break from Rodriguez et al. (2011)
    F_rain::Float64            = 40.0       # Amount of cumulative rainfall to break bud dormancy (mm). Source: 20 mm Zacharias et al. (2008)
    Max_Bud_Break::Int64       = 12         # Max number of nodes that can break dormancy daily (buds node-1). Source : Rodriguez et al. (2011)
    ageMaturity::Int64         = 3          # Coffee maturity age (Years)
    BudInitEnd::Float64        = 100.0      # End of bud initiation period relative to first potential bud break of the year (dd).
    F_over::Float64            = 3304.0     # Duration until fruit stage 5 overripe in  the  soil (dd). Source: Rodriguez 2011 Table 1
    u_log::Float64             = 1418.0     # Parameters for the logistic fruit growth pattern (FruitMaturation/2)
    s_log::Float64             = 300.0      # Idem
    S_a::Float64               = 5.3207     # Sucrose concentration in berries throught time (dd) parameter. Source : Pezzopane et al. (2011).
    S_b::Float64               = -28.5561   # Sucrose concentration in berries throught time parameter
    S_x0::Float64              = 190.9721   # Sucrose concentration in berries throught time parameter adapt. to Aquiares (95% maturity ~ at 195 dd)
    S_y0::Float64              = 3.4980     # Sucrose concentration in berries throught time parameter
    Optimum_Berry_DM::Float64  = 0.246      # Optimum berry dry mass without carbohydrate limitation (g dry mass berry-1). Source: Wintgens book + Vaast et al. (2005)
    kscale_Fruit::Float64      = 0.05       # Empirical coefficient for the exponential fruit growth
    harvest::String            = "quantity" # Harvest condition: "quality"  -> harvest when most fruits are mature is reached (optimize fruit quality)
    #                    "quantity" -> harvest when fruit dry mass is at maximum.
    # NB: "quality" requires a well-set maturation module.
    Min_Fruit_CM::Float64      = 20.0       # Minimum fruit carbon mass below which harvest cannot be triggered
    FtS::Float64               = 0.63       # Fruit to seed ratio (g g-1). Source: Wintgens
    lambda_Shoot::Float64      = 0.14       # Allocation coefficient to resprout wood
    lambda_SCR::Float64        = 0.075      # Allocation coefficient to stump and coarse roots.
    lambda_Leaf_remain::Float64= 0.85       # Allocation coefficient to allocate the remaining carbon to leaves and fine roots
    lambda_FRoot_remain::Float64= 0.15      # Idem remain carbon: (1-lambda_Shoot-lambda_SCR-Fruit_Allocation)
    lifespan_Leaf::Float64     = 265.0      # Leaf life span. Source: Charbonnier et al. (2017)
    lifespan_Shoot::Float64    = 7300.0     # Resprout wood life span. Source: Van Oijen et al (2010 I)
    lifespan_SCR::Float64      = 7300.0     # Stump and coarse roots life span. Source: Charbonnier et al. (2017)
    lifespan_FRoot::Float64    = 365.0      # Fine roots life span. Source: Van Oijen et al (2010 I)
    m_FRoot::Float64           = 0.05       # Fine root percentage that die at pruning
    CC_Fruit::Float64          = 0.4857     # Fruit carbon content (gC g-1 dry mass)
    CC_Leaf::Float64           = 0.463      # Leaf carbon content (gC g-1 dry mass)
    CC_Shoot::Float64          = 0.463      # Resprout wood carbon content (gC g-1 dry mass)
    CC_SCR::Float64            = 0.475      # Stump and coarse root carbon content (gC g-1 dry mass)
    CC_FRoots::Float64         = 0.463      # Fine root carbon content (gC g-1 dry mass)
    epsilon_Fruit::Float64     = 1.6        # Fruit growth respiration coefficient (g g-1) computed using : http://www.science.poorter.eu/1994_Poorter_C&Nrelations.pdf :
    epsilon_Leaf::Float64      = 1.279      # Leaf growth respiration coefficient (g g-1)
    epsilon_Shoot::Float64     = 1.20       # Resprout wood growth respiration coefficient (g g-1). Source: Dufrêne et al. (2005)
    epsilon_SCR::Float64       = 1.31       # Stump and coarse root growth respiration coefficient (g g-1).
    epsilon_FRoot::Float64     = 1.279      # Fine root growth respiration coefficient (g g-1).
    NC_Fruit::Float64          = 0.011      # Fruit nitrogen content (gN gDM-1). Source: Van Oijen et al. (2010) (1.1% of DM)
    NC_Leaf::Float64           = 0.0296     # Leaf nitrogen content (gN gDM-1). Source: Ghini et al. (2015) 28.2 to 30.9 g kg−1 DW
    NC_Shoot::Float64          = 0.0041     # Resprout wood nitrogen content (gN gDM-1). Source: Ghini et al. (2015) 28.2 to 30.9 g kg−1 DW
    NC_SCR::Float64            = 0.005      # Stump and coarse root nitrogen content (gN gDM-1).
    NC_FRoot::Float64          = 0.018      # Fine root nitrogen content (gN gDM-1).
    Q10_Fruit::Float64         = 2.4        # Fruit Q10 computed from whole plant chamber measurements (Charbonnier 2013) (-)
    Q10_Leaf::Float64          = 2.4        # Leaf Q10 (-)
    Q10_Shoot::Float64         = 2.4        # Resprout wood Q10 (-)
    Q10_SCR::Float64           = 1.65       # Stump and coarse root Q10 (-). Source: Van Oijen et al. (2010)
    Q10_FRoot::Float64         = 1.65       # Fine root Q10 (-). Source: Van Oijen et al. (2010)
    TMR::Float64               = 15.0       # Base temperature for maintenance respiration (deg C)
    MRN::Float64               =            # Base maintenance respiration (gC gN-1 d-1). Computed from Ryan (1991)
      ((0.00055 * 12.0 * 12.0) + (0.00055 * 0.6 * 12.0 * 12.0)) / 2.0
    # MRN: transformed in gDM gN-1 d-1 in the model using CC of each organ.
    # Accounting for 40% reduction during daytime (*1+ during night *0.6 during daylight)
    pa_Fruit::Float64          = 1.0        # Fruit living tissue (fraction)
    pa_Leaf::Float64           = 1.0        # Leaf living tissue (fraction)
    pa_Shoot::Float64          = 0.37       # Resprout wood living tissue (fraction)
    pa_SCR::Float64            = 0.21       # Stump and coarse root living tissue (fraction)
    pa_FRoot::Float64          = 1.0        # Fine root living tissue (fraction)
    DE_opt::Float64            = 0.164      # optimum demand in total carbon for each berry (including growth respiration)
    # = Optimum_Berry_DM*CC_Fruit+Optimum_Berry_DM*CC_Fruit*(1-epsilonFruit)
    Bud_T_correction           =  CB      # function to predict the temperature-dependent coefficient giving the mean T in input
    # Parameters for American Leaf Spot
    SlopeAzimut::Float64       = 180.0      # site slope azimuth (deg)
    Slope::Float64             = 5.0        # Percentage slope (%)
    RowDistance::Float64       = 1.5        # Coffee inter-row distance
    Shade::Float64             = 0.25       # Shade percentage see in Anna Deffner
    Fertilization::Int64       = 3          # Number of fertilizations per year
    ShadeType::Int64           = 1          # Shade type:
    # 1 Legume only; 2	bananas and legume only;3	bananas and other plants;
    # 4	fruit and forest tree only; 5	no shade
    CoffeePruning::String      = "tree"           # Coffee pruning management type:
    # tree ; row ; 3 by block ; 4 NULL (no pruning)
    LeafWaterPotential= LeafWaterPotential
    T_Coffee= T_Coffee
    H_Coffee= H_Coffee
    lue= lue
end

function CB()
    Data_Buds_day= DataFrame(Air_T= [-100.0,10,15.5,20.5,25.5,30.5,100.0],
                             Inflo_per_Node= [0.0,0,2.6,3.2,1.5,0,0.0],
                             Buds_per_Inflo= [0.0,0,1.2,1.2,0.15,0,0.0])
                             # We add artificial values at -100 and 100°C so LinearInterpolation works at low and high values
    Data_Buds_day.Inflo_per_Node_standard= Data_Buds_day.Inflo_per_Node ./ maximum(Data_Buds_day.Inflo_per_Node)
    Data_Buds_day.Buds_per_Inflo_standard= Data_Buds_day.Buds_per_Inflo ./ maximum(Data_Buds_day.Buds_per_Inflo)
    Data_Buds_day.T_cor_Flower= Data_Buds_day.Inflo_per_Node_standard .* Data_Buds_day.Buds_per_Inflo_standard
  
    CB_fun= LinearInterpolation(Data_Buds_day.Air_T, Data_Buds_day.T_cor_Flower);
    return CB_fun
end


# Metamodels (or subroutines):
# Leaf Water Potential (MPa)
  function LeafWaterPotential(Sim::DataFrame,Met_c::DataFrame,i::Int64)
    0.040730 - 0.005074 * Met_c.VPD[i] - 0.037518 * Sim.PAR_Trans_Tree[i] + 2.676284 * Sim.SoilWaterPot[previous_i(i)]
end

# Transpiration:
function T_Coffee(Sim::DataFrame,Met_c::DataFrame,i::Int64)
    T_Cof= -0.72080 + 0.07319 * Met_c.VPD[i] -0.76984 * (1.0-Met_c.FDiff[i]) + 0.13646*Sim.LAI[i] + 0.12910*Sim.PAR_Trans_Tree[i]
    if T_Cof<0.0
        T_Cof= 0.0
    end
    T_Cof
end

# Sensible heat flux:
function H_Coffee(Sim::DataFrame,Met_c::DataFrame,i::Int64)
    1.2560 - 0.2886*Met_c.VPD[i] - 3.6280*Met_c.FDiff[i] + 2.6480*Sim.T_Coffee[i] + 0.4389*Sim.PAR_Trans_Tree[i]
end

# Light use efficiency:
function lue(Sim::DataFrame,Met_c::DataFrame,i::Int64)::Float64                       
2.784288 + 0.009667*Met_c.Tair[i] + 0.010561*Met_c.VPD[i] - 0.710361*sqrt(Sim.PAR_Trans_Tree[i])
end





Base.@kwdef struct tree
    Tree_Species::String = "Erythrina poeppigiana"   # Names of the shade Tree species
    Species_ID           = "Erythrina_Aquiares"      # Optional species ID
    StockingTree_treeha1 = 250.0                     # density at planting (trees ha-1). Source: Taugourdeau et al. (2014)
    SLA_Tree             = 17.4                      # Specific leaf area (m2 kg-1). Source: Van Oijen et al. (2010 I)
    wleaf_Tree           = 0.068                     # Leaf width (m)
    DELM_Tree            = 778.5                     # Max Leaf carbon demand (gC tree d-1).
    LAI_max_Tree         = 1.0                       # Max measured LAI to compute leaf demand. Should be ~1.5*higher than measured.
    Leaf_fall_rate_Tree  = [0.07,0.02,0.015,0.04]    # Mortality during leaf fall (fraction of the leaf mass).
    Fall_Period_Tree     = (1:55,175:240,300:354,355:365) # Time period were leaves fall at high rate (DOY). List of length= Leaf_fall_rate_Tree
    Thin_Age_Tree        = 22                        # Ages at which thinning is made (age). Set to 9999 if no thinning
    ThinThresh           = 0.0                       # (option) Lowest transmittance threshold under wich thinning is triggered (0-1)
    RateThinning_Tree    = 0.97072                   # How many trees are thinned per thinning event in percentage.
    date_Thin_Tree       = 100                       # Date(s) of thinning (DOY)
    D_pruning_Tree       = 213                       # Date(s) of pruning each year (DOY). Set to 9999 if no pruning.
    pruningIntensity_Tree= 0.7                       # Pruning intensity (% dry mass)
    m_FRoot_Tree         = 0.005                     # Fine root percentage that die at pruning
    Pruning_Age_Tree     = collect(1:21)             # Ages at which pruning is made (age). Set to 9999 if no pruning.
    # k_Dif_Tree           = 0.305                   # Light extinction coefficient for diffuse light. Now computed by metamodels
    # k_Dir_Tree           = 0.304                   # Light extinction coefficient for direct light. Now computed by metamodels
    # lue_Tree             = 1.1375                  # Light-use efficiency (gc MJ-1). Now computed by metamodels
    lambda_Stem_Tree     = 0.20                      # Allocation coefficient to the stem. Source: Litton (2007)
    lambda_Branch_Tree   = 0.25                      # Allocation coefficient to the branches wood. Source: Litton (2007)
    lambda_CR_Tree       = 0.10                      # Allocation coefficient to the coarse roots. Source: Litton (2007)
    lambda_Leaf_Tree     = 0.26                      # Allocation coefficient to the Leaves. Source: Litton (2007)
    lambda_FRoot_Tree    = 0.05                      # Allocation coefficient to the fine roots. Source: Litton (2007)
    Wood_alloc= lambda_Stem_Tree + lambda_CR_Tree + lambda_Branch_Tree
    kres_max_Tree        = 1.2                       # Maximum carbon extracted from reserves compared to maintenance respiration
    Res_max_Tree         = 150.0                     # Maximum reserve until Tree always use it for growth
    CC_Leaf_Tree         = 0.47                      # Leaf carbon content in gC gDM-1. Source: Van Oijen et al. (2010)
    CC_wood_Tree         = 0.47                      # Wood carbon content in gC gDM-1. Source: Van Oijen et al. (2010)
    epsilon_Branch_Tree  = 1.2                       # Branch growth cost coefficient (gC.gC-1). Source: This study
    epsilon_Stem_Tree    = 1.2                       # Stem growth cost coefficient (gC.gC-1). Source: This study
    epsilon_CR_Tree      = 1.33                      # Coarse root growth cost coefficient (gC.gC-1). Source: Litton et al. (2007)
    epsilon_Leaf_Tree    = 1.392                     # Leaf growth cost coefficient (gC.gC-1). Source: Erythrina excelsa Villar and Merino (2001)
    epsilon_FRoot_Tree   = 1.392                     # Leaf growth cost coefficient (gC.gC-1). Considered = to leaves
    epsilon_RE_Tree      = 1.000001                  # Reserves growth cost coefficient (gC.gC-1). No cost unknown.
    lifespan_Branch_Tree = 7300.0                    # Branch lifespan natural mortality (d)
    lifespan_Leaf_Tree   = 10^5                      # Leaf lifespan (d). Taken infinite because regulated by leaf fall phenology.
    lifespan_FRoot_Tree  = 90.0                      # Fine roots lifespan (d).
    lifespan_CR_Tree     = 7300.0                    # Coarse roots lifespan (d). Source: Van Oijen et al. (2010I)
    Kh                   = 0.46                      # Allometries source: CAF2007 Van Oijen et al. (2010). Adjusted to fit our observations.
    KhExp                = 0.5                       # Allometries source: CAF2007 Van Oijen et al. (2010). Adjusted to fit our observations.
    Kc                   = 8.0                       # Allometries source: CAF2007 Van Oijen et al. (2010). Adjusted to fit our observations.
    KcExp                = 0.45                      # Allometries source: CAF2007 Van Oijen et al. (2010). Adjusted to fit our observations.
    MRN_Tree             = 0.20                      # Base maintenance respiration (gC.gN.day-1)
    NC_Branch_Tree       = 0.005                     # Branch nitrogen content (gN.gDM-1).
    NC_Stem_Tree         = 0.005                     # Stem nitrogen content (gN.gDM-1).
    NC_CR_Tree           = 0.0084                    # Coarse roots nitrogen content (gN.gDM-1). Source: Van Oijen et al. (2010I)
    NC_Leaf_Tree         = 0.0359                    # Leaf nitrogen content (gN.gDM-1). Source: average 3.35 to 3.82% Van Oijen et al. (2010I)
    NC_FRoot_Tree        = 0.0084                    # Fine root nitrogen content (gN.gDM-1). Taken = to leaves
    Q10Branch_Tree       = 2.1                       # Branch Q10 (-)
    Q10Stem_Tree         = 1.7                       # Stem Q10 (-)
    Q10CR_Tree           = 2.1                       # Coarse root Q10 (-)
    Q10Leaf_Tree         = 1.896                     # Leaf Q10 (-) see 1-DATA/Erythrina/Respiration.docx
    Q10FRoot_Tree        = 1.4                       # Fine root Q10 (-). Source: Van Oijen et al (2010I)
    pa_Branch_Tree       = paliv_dis(40,0.4,0.05,5.0) # Branch living tissue (fraction). Not used (replaced by pa_Stem_Tree).
    pa_Stem_Tree         = paliv_dis(40,0.3,0.05,5.0) # Computation of living tissue at each age (do not modify)
    pa_CR_Tree           = 0.21                      # Coarse roots living tissue (fraction)
    pa_Leaf_Tree         = 1.0                       # Leaf living tissue (fraction)
    pa_FRoot_Tree        = 1.0                       # Fine root living tissue (fraction)
    WoodDensity          = 565.0                    # Potentially used for allometries (ref. value is for Cordia alliodora).
    k                    = light_extinction_K_Tree   # Light extinction coefficient (modify if needed)
    metamodels_tree      = metamodels_tree           # Idem for lue transpiration and sensible heat flux using MAESPA metamodels
    Allometries          = tree_allometries          # Idem for allometric equations (optional any kind of variable can be added here).
end


function metamodels_tree(Sim::DataFrame,Met_c::DataFrame,i::Int64)
    Sim.lue_Tree[i]= 2.87743 + 0.07595 * Met_c.Tair[i] - 0.03390 * Met_c.VPD[i] - 0.24565*Met_c.PAR[i]
  
    Sim.T_Tree[i]= -0.2366 + 0.6591 * Sim.APAR_Tree[i] + 0.1324*Sim.LAI_Tree[i]
    if Sim.T_Tree[i] < 0.0
        Sim.T_Tree[i]= 0.0
    end

    Sim.H_Tree[i]=
      0.34062 + 0.82001 * Sim.APAR_Dir_Tree[i] + 0.32883 * Sim.APAR_Dif_Tree[i] -
      0.75801 * Sim.LAI_Tree[i] - 0.57135 * Sim.T_Tree[i] -
      0.03033 * Met_c.VPD[i]
end


function light_extinction_K_Tree(Sim::DataFrame,Met_c::DataFrame,i::Int64)
    # See MAESPA_Validation project, script 4-Aquiares_Metamodels.R
    # Source for non-constant k: Sinoquet et al. 2007
    # DOI: 10.1111/j.1469-8137.2007.02088.x
    Sim.K_Dif_Tree[i]= 0.6161 - 0.5354 * Sim.LAD_Tree[previous_i(i,1)]
    Sim.K_Dir_Tree[i]= 0.4721 - 0.3973 * Sim.LAD_Tree[previous_i(i,1)]
end

function tree_allometries(Sim::DataFrame,Met_c::DataFrame,Parameters,i::Int64)
    Sim.DBH_Tree[i]= ((Sim.DM_Stem_Tree[i] / (Parameters.CC_wood_Tree * 1000 * Sim.Stocking_Tree[i]) / 0.5)^0.625) / 100.0
    # Source: Rojas-García et al. (2015) DOI: 10.1007/s13595-015-0456-y
    # /!\ DBH is an average DBH among trees.
    #Tree Height. Source:  CAF2007 used in Van Oijen et al. (2011). With no pruning :
    Sim.Height_Tree[i]= Parameters.Kh * (((Sim.DM_Stem_Tree[i] / 1000.0) / Sim.Stocking_Tree[i])^Parameters.KhExp)
  
    # Crown projected area:
    Sim.CrownProj_Tree[i]= Parameters.Kc * (((Sim.DM_Branch_Tree[i] / 1000.0) / Sim.Stocking_Tree[i])^Parameters.KcExp)
    # Source: Van Oijen et al. (2010, I).
    Sim.CrownRad_Tree[i]= sqrt(Sim.CrownProj_Tree[i] / pi )
    Sim.Crown_H_Tree[i]= Sim.CrownRad_Tree[i] # See Charbonnier et al. 2013, Table 2.
    Sim.Trunk_H_Tree[i]= Sim.Height_Tree[i] - Sim.Crown_H_Tree[i]
  
    # If there is a pruning management, change the allometries (mostly derived from Vezy et al. 2018) :
    if any(Sim.Plot_Age[i] .== Parameters.Pruning_Age_Tree)
      # Pruning : trunk height does not depend on trunk dry mass anymore (pruning effect)
      Sim.Trunk_H_Tree[i]= 3.0 * (1. - exp(-0.2 - Sim.Plot_Age_num[i]))
      Sim.Height_Tree[i]= Sim.Crown_H_Tree[i] + Sim.Trunk_H_Tree[i]
      # The equation make it grow fast at the early stages and reach a plateau at the
      # maximum height after ca. few months.
    elseif any(Sim.Plot_Age[i] .> Parameters.Pruning_Age_Tree)
      # if there were any pruning before, add the trunk
      Lastheight_Trunk= 3.0 * (1. - exp(-0.2 - Parameters.Pruning_Age_Tree[findlast(Sim.Plot_Age[i] .>= Parameters.Pruning_Age_Tree)]+1))
      Sim.Height_Tree[i]= Parameters.Kh * (((Sim.DM_Stem_Tree[i] / 1000.0) / Sim.Stocking_Tree[i])^Parameters.KhExp) + Lastheight_Trunk
      Sim.Trunk_H_Tree[i]= Sim.Height_Tree[i] - Sim.Crown_H_Tree[i]
    end

    Sim.LA_Tree[i]= Sim.LAI_Tree[i] / Sim.Stocking_Tree[i]
    Sim.LAD_Tree[i]= Sim.LA_Tree[i] / ((Sim.CrownRad_Tree[i]^2.0) * (0.5 * Sim.Crown_H_Tree[i]) * pi * (4.0 / 3.0))

    if Sim.LAD_Tree[i] == Inf || Sim.LAD_Tree[i] < 0.21
        Sim.LAD_Tree[i]= 0.21
    elseif Sim.LAD_Tree[i] > 0.76
        Sim.LAD_Tree[i]= 0.76
    end
end

"""
Parameter structures

Those structures are used to make the parameter inputs to DynACof. Default values are provided to the user (the struct are Base.@kwdef).
They are mainly used under the hood from [Import_Parameters()], but can still be called by the user for conveniance (but not needed 
for a model run). The Parameters are divided into five structures: `constants`, `site`, `soil`, `coffee`, and `tree`.

## site:

The site structure. The default values comes from a stand from the Aquiares farm located in Costa Rica. It is a *Coffea arabica*
plantation in agroforestry management under *Erythrina poeppigiana* shade trees. The plot is visible
at this [address](https://goo.gl/7FRNXg), and a full desciption is available [here](https://www.researchgate.net/publication/323398728_Measuring_and_modelling_energy_partitioning_in_canopies_of_varying_complexity_using_MAESPA_model)
and [here](https://www.researchgate.net/publication/333776631_DynACof_a_process-based_model_to_study_growth_yield_and_ecosystem_services_of_coffee_agroforestry_systems).

## constants

See [`constants`](@ref).

## soil

The soil structure.

## coffee

The coffee structure. The default values comes from a high density plantation (5580 coffee plants per hectares) of *Coffea arabica var. Caturra* pruned
every year to sustain the production on three resprouts per stump in average (see same references than site).

# tree

The shade tree structure. The default values come from *Erythrina poeppigiana* shade trees from Aquiares. They were planted at high density 
(250 trees ha-1) pruned to optimize light transmitted to the *Coffea*, and were thinned in 2000 to a low density of ~7.4 trees ha-1.
Starting from 2000, these trees made a relatively large crown with an average height of 26 m in 2018 on this site. 
NB: the tree parameter structure is optional, and not needed for monospecific coffee plantations.

# Return 

An instance of a structure with Parameters needed for a DynACof simulation.

# Details
The values of the instance can be read from files using [`import_parameters`](@ref). In that case, the user 
can provide only the parameter values that need to be changed, and all others will be taken as the default values. Example files are provided in
a specific Github repository [here](https://github.com/VEZY/DynACof.jl_inputs).
"""
site, soil, coffee, tree