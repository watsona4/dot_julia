"""
# American Leaf Spot

Compute the percentage of *Coffea* leaves dying from American Leaf Spot disease, drought excluded. 
The function needs at least a year of data at daily time-step. 

# Arguments  

- `Elevation::Float64`:           Site elevation       (m.a.s.l)
- `df_rain::DataFrame`            Data frame with DOY, year and Rain (mm) values at daily time-step, with a whole year (or more) of data
- `SlopeAzimut::Float64`:         Slope azimuth        (degree)
- `Slope::Float64`:               Slope percentage     (%)
- `RowDistance::Float64`:         Coffee rows distance (m)
- `Shade::Float64`:               Shade percentage     (%)
- `height_coffee::Float64`: Coffee Height        (m)
- `Fertilization::Int64`:       N fertilization per year
- `ShadeType::Int64`:             Shade type:
    + 1: Legume only
    + 2: Bananas and legume
    + 3: Bananas and other plants
    + 4: Fruit and forest trees only
    + 5: No shade (Full sun)
- `CoffeePruning::String`         Character specifying the pruning management. Values: "tree", "row", "block" or "" (empty String, no pruning).

# Note
All arguments are named.
It is good practice to use shade tree transmittance to compute "Shade" percentage (`Shade= 1-Transmittance`).

# Return
**ALS**: Percentage of dead leaves by ALS by day (% day-1)

# References
Avelino et al. (2007) Topography and Crop Management Are Key Factors for the Development of American Leaf Spot Epidemics on
Coffee in Costa Rica. File: "Ia_digitized from Avelino 2007 - JA_lineaire.xlsx"

# Examples
```julia
using DataFrames
# Making df_rain :
df_rain= DataFrame(DOY= 1:365, year= fill(2018,365), Rain= rand(0:0.1:5, 365))
ALS(Elevation = 1000, df_rain= df_rain)
```
"""
function ALS(;Elevation,df_rain,SlopeAzimut=0.0,Slope=0.0,RowDistance=1.5,Shade= 0.0,height_coffee=2.0,Fertilization= 3,ShadeType= 5,CoffeePruning= "tree")
 
    Ia_Elevation= -0.000000000080801 * Elevation^3 - 0.0000068050865205 * Elevation^2 + 0.0184187089250643 * Elevation - 11.9175485660755
    Ia_SlopeAzimut= 0.0000000000035758 * SlopeAzimut^5 - 0.0000000002237767 * SlopeAzimut^4 - 0.0000013880057625 * SlopeAzimut^3 +
                    0.000492076366075 * SlopeAzimut^2 - 0.046667060826288 * SlopeAzimut + 0.492587332814335
    Ia_Slope= -0.0006135200057836 * Slope^2 + 0.0611762490434003 * Slope - 0.96950860406751
    Ia_RowDistance= -1.67586900817065 * RowDistance^2 + 4.61297139285148 * RowDistance - 2.7957057499133
    Ia_Shade= 0.0180902153201516 * Shade - 0.218143985209743
    Ia_CoffeeHeight= 0.734362166489921 * height_coffee - 1.36982218159893
    Ia_NbFertiliz= -0.163949361429501*Fertilization + 0.395095964560203

    if ShadeType==1 
        Ia_ShadeType= -0.3
    elseif ShadeType==2 
        Ia_ShadeType= -0.2
    elseif ShadeType==3 
        Ia_ShadeType= -0.18
    elseif ShadeType==4
        Ia_ShadeType= 0.65
    elseif ShadeType==5
        Ia_ShadeType= 0.28
    end

    if CoffeePruning=="tree"
        Ia_CoffeePruning= 0.05
    elseif CoffeePruning=="row"
        Ia_CoffeePruning= 0.3
    elseif CoffeePruning=="block"
        Ia_CoffeePruning= -0.35
    elseif CoffeePruning==""
        Ia_CoffeePruning= 0.65
    end

    mid_june_to_mid_august= Float64.((df_rain.DOY .>= 166) .& (df_rain.DOY .<= 227))
    ShortDrought15JuneAugust_mm= zeros(nrow(df_rain))
    Ia_ShortDrought15JuneAugust= zeros(nrow(df_rain))
    Sum_Ia_ALS= zeros(nrow(df_rain))
    Defol_ALS= zeros(nrow(df_rain))

    for i in unique(df_rain.year)
        ShortDrought15JuneAugust_mm[df_rain.year .== i] .= 
            sum(df_rain.Rain[df_rain.year .== i] .* mid_june_to_mid_august[df_rain.year .== i])
    end

    
    Ia_ShortDrought15JuneAugust .= 0.0012200723943985 .* ShortDrought15JuneAugust_mm .- 0.923932085933056

    Sum_Ia_ALS .= Ia_Elevation .+ Ia_SlopeAzimut .+ Ia_Slope .+ Ia_RowDistance .+ Ia_Shade .+ Ia_CoffeeHeight .+ Ia_NbFertiliz .+ Ia_ShadeType .+ 
                Ia_CoffeePruning .+ Ia_ShortDrought15JuneAugust
    Sum_Ia_ALS[Sum_Ia_ALS .< 0.0] .= 0.0
    Sum_Ia_ALS .= 0.2797 .* Sum_Ia_ALS .+ 0.3202

    Defol_ALS_pc= zeros(length(Sum_Ia_ALS))
    Defol_ALS_pc[(df_rain.DOY .> 15) .& (df_rain.DOY .< 166)] .= 0.0
    Defol_ALS_pc[(df_rain.DOY .>= 166) .& (df_rain.DOY .<= 366)] .= 
        Sum_Ia_ALS[(df_rain.DOY .>= 166) .& (df_rain.DOY .<= 366)] .* exp.(0.0180311 .* (df_rain.DOY[(df_rain.DOY .>= 166) .& (df_rain.DOY .<= 366)] .- 166))
    Defol_ALS_pc[df_rain.DOY .<= 15] .= Sum_Ia_ALS[df_rain.DOY .<= 15] .* exp.(0.0180311 .* (df_rain.DOY[df_rain.DOY .<= 15] .- 166 .+ 365))
    Defol_ALS .= (Defol_ALS_pc .- Defol_ALS_pc[previous_i.(1:length(Sum_Ia_ALS))]) ./ 100.0
    Defol_ALS[Defol_ALS .< 0.0] .= 0.0

    return Defol_ALS
end