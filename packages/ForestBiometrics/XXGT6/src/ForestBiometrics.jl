#__precompile__(true) #needed?

module ForestBiometrics

#dependencies
using RecipesBase
using OffsetArrays

#end dependencies

export emc
export sdi, qmd
export gingrich_chart
export HeightDiameter, calculate_height

export Curtis,
Michailoff,
Meyer,
Micment,
Micment2,
Naslund,
Naslund2,
Naslund3,
Naslund4,
Power,
Wyckoff

#3 parameter equations, mainly from LMFOR R package
#sorted alphabetically
export Chapman,
Gompertz,
HossfeldIV,
Korf,
Logistic,
Monserud,
Prodan,
Ratkowsky,
Sibbesen,
Weibull

export K, KMETRIC,VolumeEquation, MerchSpecs, Sawtimber, Pulp, Fiber

export limiting_distance

export sdi_chart

export  Log, LogSegment,
        Shape, Cylinder,
        Paraboloid,
        Cone,Neiloid,
        ParaboloidFrustrum,
        NeiloidFrustrum,
        ConeFrustrum,
        area,volume,
        scribner_volume,
        international_volume,
        doyle_volume

#Alphabetic order

include("EquilibriumMoistureContent.jl")
include("ForestStocking.jl")
include("GingrichStocking_chart.jl")
include("HeightDub.jl")
include("LimitingDistance.jl")
include("SDI_chart.jl")
include("VolumeEquations.jl")

end
#end module