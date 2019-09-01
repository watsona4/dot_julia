"""
Get the average wind speed at center of canopy layer by computing the wind speed decrease in two steps:
 + Decrease the measured wind speed from measurement height until top of the canopy using the formula of
Van de Griend and Van Boxel (1989)

 + Decrease wind speed further with increasing canopy depth using an exponential extinction coefficient and a
cumulated LAI above the target point.


# Arguments 

- `Wind::Float64`:      Above canopy wind speed (m s-1)
- `LAI_lay::Float64`:   Leaf area index of the layer (m2 leaves m-2 soil)
- `LAI_abv::Float64`:   Cumulated leaf area index above the layer (m2 leaves m-2 soil)
- `extwind::Float64`:   Extinction coefficient. Default: `0`, no extinction.
- `Z_top::Float64`:     Average canopy height of the taller crop (m)
- `ZHT::Float64`:       Wind measurement height (m)
- `Z0::Float64`:        Roughness length (m). Default: `0.1 ⋅ Z_top`
- `ZPD::Float64`:       Zero-plane displacement (m), Default: `0.75 ⋅ Z_top`
- `α::Float64`:         Alpha, the constant for diffusivity at top canopy. Default: `1.5` following Van de Griend et al (1989).
- `ZW::Float64`:        Top height of the roughness sublayer (m). Default: `ZPD + α ⋅ (Z2 - ZPD)`
- `vonkarman::Float64`: Von Karman constant, default to `constants().vonkarman`, 0.41.
- `verbose::Bool`:      Print information of [`test_ZHT`](@ref)

# Details
The function computes the average wind speed at the center of the canopy layer. It is considered
that the leaf distibution is homogeneous in the layer, so the `LAI_lay` parameter is used to
add half of the target layer to the cumulated LAI above:
```WindLay=Wh*e^{^{\\left(-extwind*\\left(LAI_{abv}+\\frac{LAI_{lay}}{2}\\right)\\right)}}```
with `Wh` the wind speed at top of the canopy. Note: the `α` parameter can also be computed as:
```α=\\frac{zw-d}{Z2-d}```


# Return
**WindLay**: The winspeed at the center of the layer (m s-1)

# References
Van de Griend, A.A. and J.H. Van Boxel, Water and surface energy balance model with a multilayer canopy representation 
for remote sensing purposes. Water Resources Research, 1989. 25(5): p. 949-971.

Part of the code is taken from the [MAESPA model](https://maespa.github.io).

# Examples
```julia
# Windspeed in a coffee layer managed in agroforestry system
GetWind(Wind=3.0,LAI_lay=4.0,LAI_abv=0.3,extwind= 0.58,Z_top = 24.0,ZHT = 25.0)
```
"""
function GetWind(;Wind,LAI_lay,LAI_abv,Z_top,ZHT,extwind=0,Z0=Z_top*0.1,ZPD=Z_top*0.75,α=1.5,ZW=ZPD+α*(Z_top-ZPD),vonkarman=constants().vonkarman, verbose=false)
    ZHT= test_ZHT(ZHT, Z_top, verbose= false)
    Ustar = Wind * vonkarman / log((ZHT - ZPD) / Z0) # by inverting eq.41 from Van de Griend
    # Wind at the top of the canopy:
    Uh= (Ustar / vonkarman) * log((ZW - ZPD) / Z0) - (Ustar / vonkarman) * (1 - ((Z_top - ZPD) / (ZW - ZPD)))
    LAI_abv = LAI_lay / 2.0 + LAI_abv
    WindLay= Uh * exp(-extwind * LAI_abv)

    return WindLay
end

"""
    test_ZHT(ZHT::Float64, Z_top::Float64; verbose::Bool= false)::Float64

Test if ZHT is lower than Z_top, and return 1.01 * Z_top if so (or ZHT if not).
# Arguments 

- `ZHT::Float64`:       Wind measurement height (m)
- `Z_top::Float64`:     Average canopy height of the taller crop (m)
- `verbose::Bool`:      Print information if ZHT < Z_top

# Examples
```julia
test_ZHT(8.0, 10.0, verbose= true)
```
"""
function test_ZHT(ZHT::Float64, Z_top::Float64; verbose::Bool= false)::Float64
    if ZHT < Z_top
        if verbose
             printstyled("Warning: Measurement height lower than canopy height (ZHT < Z_top), forcing ZHT > Z_top \n", bold= true,color= :yellow)
        end
        ZHT= 1.01 * Z_top
    end
    return ZHT    
end

"""
Bulk aerodynamic conductance

Compute the aerodynamic conductance for sensible and latent heat above the canopy following Van de Griend and Van Boxel (1989).

# Arguments 

- `Wind::Float64`:      Average daily wind speed above canopy (m s-1)
- `LAI::Float64`:       Leaf area index of the upper layer (m2 leaf m-2 soil)
- `ZHT::Float64`:       Wind measurement height (m)
- `Z_top::Float64`:     Average canopy height of the taller crop (m)
- `Z0::Float64`:        Roughness length (m). Default: `0.1 ⋅ Z_top`
- `ZPD::Float64`:       Zero-plane displacement (m), Default: `0.75*Z_top`
- `α::Float64`:         Alpha, the constant for diffusivity at top canopy. Default: `1.5` following
                 Van de Griend et al (1989).
- `ZW::Float64`:        Top height of the roughness sublayer (m). Default: `ZPD + α ⋅ (Z_top - ZPD)`
- `extwind::Float64`:   Extinction coefficient. Default: `0`, no extinction.
- `vonkarman::Float64`: Von Karman constant, default to `constants().vonkarman`, 0.41.
- `verbose::Bool`:      Print information of [`test_ZHT`](@ref)

# Details

All arguments are named.
`α` can also be computed as: ```α=\\frac{zw-d}{Z_{top}-d}```  
The bulk aerodynamic conductance ```ga_{bulk}``` is computed as follow:
```ga_{bulk}=\\frac{1}{r1+r2+r3}```  
where `r1`, `r2` and `r3` are the aerodynamic resistances of the inertial sublayer, the roughness sublayer and
the top layer of the canopy respectively. 
Because wind speed measurements are more often made directly in the roughness sublayer, the resistance in the inertial 
sublayer `r1` is set to `0` though. `r2` and `r3` are computed using the equation 43 of Van de Griend and Van Boxel (refer to
the web version of the help file for Latex rendering):
```r2=\\int_{zh}^{zw}\\frac{1}{K''}```
with ```K''= kU_*(z_w-d)```
And: ```r3=\\int_{(z2+z1)/2}^{zh}\\frac{1}{K'''}\\mathrm{d}z```
with ```K'''= U_z\\frac{K_h}{U_h}```
Integration of `r2` and `r3` equations give:
```\\frac{(\\ln(ZPD-ZW)^2-\\ln(ZPD-Z2)^2)}{(2kU_*)}```
simplified in:
```r2= \\frac{1}{kU_*}\\ln(\\frac{ZPD-ZW}{ZPD-Z2})```
and finaly:  ```r3= \\frac{Uh}{Kh}\\ln(\\frac{Uh}{U_{interlayer}})```

# Return
**G_bulk**: The bulk aerodynamic conductance (m s-1)

# References
Van de Griend, A.A. and J.H. Van Boxel, Water and surface energy balance model with a multilayer canopy representation for 
remote sensing purposes. Water Resources Research, 1989. 25(5): p. 949-971.

# See also 
[`G_interlay`](@ref) and [`GetWind`](@ref), which is used internaly.

# Examples
```julia
# The bulk aerodynamic conductance for a coffee plantation managed in agroforestry system:
G_bulk(Wind=3.0,ZHT=25.0,Z_top=24.0,LAI = 0.5,extwind = 0.58)
```
"""
function G_bulk(;Wind,LAI,ZHT,Z_top,Z0=Z_top*0.1,ZPD=Z_top*0.75,α=1.5,ZW=ZPD+α*(Z_top-ZPD),extwind=0.0,vonkarman=constants().vonkarman,verbose= false)
    ZHT= test_ZHT(ZHT, Z_top, verbose= false)
    
    Ustar = Wind * vonkarman / log((ZHT - ZPD) / Z0) # by inverting eq.41 from Van de Griend
    Kh= α * vonkarman * Ustar * (Z_top - ZPD)
    Uw= (Ustar / vonkarman) * log((ZW - ZPD) / Z0)
    Uh= Uw - (Ustar / vonkarman) * (1.0 - ((Z_top - ZPD) / (ZW - ZPD)))
    r1= 0.0
    r2= (1.0 / (vonkarman * Ustar)) * log((ZPD - ZW) / (ZPD - Z_top))
    # r2= (1/(vonkarman*Ustar))*((ZW-Z_top)/(ZW-ZPD)) # this equation is found in Van de Griend but it is wrong.
    U_inter= GetWind(Wind= Wind,LAI_lay=0.0,LAI_abv=LAI/2.0,extwind=extwind,Z_top=Z_top,ZHT=ZHT,Z0=Z0,ZPD=ZPD,α=α,ZW=ZW)

    r3= (Uh / Kh) * log(Uh / U_inter)
    ga_bulk= 1.0 / (r1 + r2 + r3)
    
    return ga_bulk
end



"""
# Leaf boundary layer conductance for heat.

Compute the bulk leaf boundary layer conductance for heat using the wind speed, the leaf dimension, and leaf area distribution
following Jones (1992).

# Arguments 

- `Wind::Float64`:        Average daily wind speed above canopy (m s-1)
- `wleaf::Float64`:       Average leaf width (m)
- `LAI_lay::Float64`:     Leaf area index of the layer (m2 leaves m-2 soil)
- `LAI_abv::Float64`:     Cumulated leaf area index above the layer (m2 leaves m-2 soil)
- `extwind::Float64`:     Extinction coefficient. Default: `0`, no extinction.
- `Z_top::Float64`:       Average canopy height of the taller crop (m)
- `ZHT::Float64`:         Wind measurement height (m)
- `Z0::Float64`:          Roughness length (m). Default: `0.1 ⋅ Z_top`
- `ZPD::Float64`:         Zero-plane displacement (m), Default: `0.75 ⋅ Z_top`
- `α::Float64`:           Alpha, the constant for diffusivity at top canopy. Default: `1.5` following Van de Griend et al (1989).
- `ZW::Float64`:          Top height of the roughness sublayer (m). Default: `ZPD + α ⋅ (Z_top - ZPD)`

# Details  
The leaf boundary layer conductance for heat can be transformed into leaf boundary layer conductance for water vapour as follow:
```Gb_w= 1.075*gb_h```  
Note that ```Gb_w``` should be doubled for amphistomatous plants (stomata on both sides of the leaves).

# Return  
**Gb**: The leaf boundary layer conductance for heat (m s-1)

# References  
 +  Mahat, V., D.G. Tarboton, and N.P. Molotch, Testing above‐ and below‐canopy represetations of turbulent fluxes in an 
 energy balance snowmelt model. Water Resources Research, 2013. 49(2): p. 1107-1122.

# See also  
[`G_bulk`](@ref), [`G_soilcan`](@ref), [`G_interlay`](@ref) and [`GetWind`](@ref), which is used internaly.

# Examples  
```julia
# Gb for a coffee plantation managed in agroforestry system:
Gb_h(Wind=3.0,wleaf=0.068,LAI_lay=4.0,LAI_abv=0.5,ZHT=25.0,Z_top=24.0,extwind=0.58)
```
"""
function Gb_h(;Wind,wleaf,LAI_lay,LAI_abv,extwind,Z_top,ZHT,Z0=Z_top*0.1,ZPD=Z_top*0.75,α=1.5,ZW=ZPD+α*(Z_top-ZPD))
    U_z= GetWind(Wind= Wind,LAI_lay= LAI_lay, LAI_abv= LAI_abv,extwind= extwind,Z_top= Z_top, ZHT= ZHT, Z0= Z0, ZPD= ZPD,α= α, ZW= ZW)
    0.01 * sqrt(U_z/wleaf)
end


"""
# Canopy to soil aerodynamic conductance

Compute the aerodynamic conductance for sensible and latent heat between the center of the lowest canopy layer
and the soil surface following Van de Griend and Van Boxel (1989).

# Arguments 

- `Wind::Float64`:      Average daily wind speed above canopy (m s-1)
- `LAI::Float64`:       Total leaf area index above the soil (m2 leaf m-2 soil).
- `ZHT::Float64`:       Wind measurement height (m)
- `Z_top::Float64`:     Average canopy height of the taller crop (m)
- `Z0::Float64`:        Roughness length (m). Default: `0.1*Z_top`
- `ZPD::Float64`:       Zero-plane displacement (m), Default: `0.75*Z_top`
- `α::Float64`:         Alpha, the constant for diffusivity at top canopy. Default: `1.5` following Van de Griend et al (1989).
- `ZW::Float64`:        Top height of the roughness sublayer (m). Default: `ZPD + α ⋅ (Z_top - ZPD)`
- `extwind::Float64`:   Extinction coefficient. Default: `0.0`, no extinction.
- `vonkarman::Float64`: Von Karman constant, default to `constants().vonkarman`, 0.41.
- `verbose::Bool`:      Print information of [`test_ZHT`](@ref)

All arguments are named.

# Details
`α` can also be computed as: ```α=\\frac{zw-d}{Z_{top}-d}```  
The aerodynamic conductance between the lowest canopy layer and the soil is computed as:
```g_{a0}= \\frac{1}{\\frac{U_h}{K_h}\\ln(U_{mid}/U_{0})}```
where ```U_{mid}``` is the wind speed at median cumulated LAI between the top and the soil, and ```U_0``` the wind speed at
soil surface.


# Return
```g_a0```: The aerodynamic conductance of the air between the lowest canopy layer and the soil surface (m s-1)}

# References
Van de Griend, A.A. and J.H. Van Boxel, Water and surface energy balance model with a multilayer canopy representation for remote 
sensing purposes. Water Resources Research, 1989. 25(5): p. 949-971.

# See also
[`G_bulk`](@ref) and [`GetWind`](@ref), which is used internaly.


# Examples  
```julia
# G_a0 for a coffee plantation managed in agroforestry system:
G_soilcan(Wind= 1.0, ZHT= 25.0, Z_top= 24.0,LAI= 4.5, extwind= 0.58)
```
"""
function G_soilcan(;Wind,LAI,ZHT,Z_top,Z0=Z_top*0.1,ZPD=Z_top*0.75,α=1.5,ZW=ZPD+α*(Z_top-ZPD),extwind=0,vonkarman=constants().vonkarman,verbose= false)
    ZHT= test_ZHT(ZHT, Z_top, verbose= false)

    Ustar = Wind * vonkarman / log((ZHT - ZPD) / Z0) # by inverting eq.41 from Van de Griend
    Kh= α * vonkarman * Ustar * (Z_top - ZPD)
    Uw= (Ustar / vonkarman) * log((ZW - ZPD) / Z0)
    Uh= Uw - (Ustar / vonkarman) * (1.0 - ((Z_top - ZPD) / (ZW - ZPD)))
    U_mid= GetWind(Wind=Wind,LAI_lay=0.0,LAI_abv=LAI/2,extwind=extwind,Z_top=Z_top,ZHT=ZHT,Z0=Z0,ZPD=ZPD,α=α,ZW=ZW)
    U_0= GetWind(Wind=Wind,LAI_lay=0.0,LAI_abv=LAI,extwind=extwind,Z_top=Z_top,ZHT=ZHT,Z0=Z0,ZPD=ZPD,α=α,ZW=ZW)
    g_a0= 1.0 / ((Uh / Kh) * log(U_mid / U_0))
    
    return g_a0
end

"""
Canopy layer to canopy layer aerodynamic conductance

Compute the aerodynamic conductance for sensible and latent heat between canopy layers following Van de Griend and Van Boxel (1989).

# Arguments 

- `Wind::Float64`:      Average daily wind speed above canopy (m s-1)
- `LAI_top::Float64`:   Leaf area index of the upper layer (m2 leaf m-2 soil).
- `LAI_bot::Float64`:   Leaf area index of the layer below the upper layer (m2 leaf m-2 soil).
- `ZHT::Float64`:       Wind measurement height (m)
- `Z_top::Float64`:     Average canopy height of the taller crop (m)
- `Z0::Float64`:        Roughness length (m). Default: `0.1*Z_top`
- `ZPD::Float64`:       Zero-plane displacement (m), Default: `0.75*Z_top`
- `α::Float64`:         Alpha, the constant for diffusivity at top canopy. Default: `1.5` following Van de Griend et al (1989).
- `ZW::Float64`:        Top height of the roughness sublayer (m). Default: `ZPD+α*(Z_top-ZPD)`
- `extwind::Float64`:   Extinction coefficient. Default: `0`, no extinction.
- `vonkarman::Float64`: Von Karman constant, default to `constants().vonkarman`, 0.41.
- `verbose::Bool`:      Print information of [`test_ZHT`](@ref)

All arguments are named. 

# Details
`α` can also be computed as: ```α=\\frac{zw-d}{Z_{top}-d}```  
The aerodynamic conductance between canopy layers is computed as:
```g_{af}= \\frac{1}{\\frac{U_h}{K_h}\\ln(U_{mid}/U_{inter})}```
where usually ```U_{mid}``` is the wind speed at (median) cumulated LAI between the top and the soil, and
```U_{inter}``` the wind speed at the height between the two canopy layers. In this function, ```U_{mid}``` and
```U_{inter}``` are computed relative to the leaf area instead of the height of the vegetation layers.

# Return
```g_af```: The aerodynamic conductance of the air between two canopy layers (m s-1)

# References
Van de Griend, A.A. and J.H. Van Boxel, Water and surface energy balance model with a multilayer canopy representation for remote 
sensing purposes. Water Resources Research, 1989. 25(5): p. 949-971.

# See also
[`G_bulk`](@ref) and [`GetWind`](@ref), which is used internaly.

# Examples  
```julia
# G_af for a coffee plantation managed in agroforestry system:
G_interlay(Wind = 3,ZHT = 25,Z_top = 2,LAI_top = 0.5,LAI_bot = 4)
```
"""
function G_interlay(;Wind,LAI_top,LAI_bot,ZHT,Z_top,Z0=Z_top*0.1,ZPD=Z_top*0.75,α=1.5,ZW=ZPD+α*(Z_top-ZPD),extwind=0.58,vonkarman=constants().vonkarman,verbose= false)
    ZHT= test_ZHT(ZHT, Z_top, verbose= false)

    Ustar = Wind * vonkarman / log((ZHT - ZPD) / Z0) # by inverting eq.41 from Van de Griend
    Kh= α * vonkarman * Ustar * (Z_top - ZPD)
    Uw= (Ustar / vonkarman) * log((ZW - ZPD) / Z0)
    Uh= Uw - (Ustar / vonkarman) * (1.0 - ((Z_top - ZPD) / (ZW - ZPD)))
    # U_inter is computed using LAI instead of height, so (z1+Z_top)/2 become
    # LAI_top/2
    U_inter= GetWind(Wind=Wind,LAI_lay=0.0,LAI_abv=LAI_top/2.0,extwind=extwind,Z_top=Z_top,ZHT=ZHT,Z0=Z0,ZPD=ZPD,α=α,ZW=ZW)
    # U_mid is computed using LAI instead of height, so Z_top/2 become
    # (LAI_top+LAI_bot)/2, (LAI_top+LAI_bot) for top layer.
    U_mid= GetWind(Wind=Wind,LAI_lay=0.0,LAI_abv=(LAI_top+LAI_bot)/2.0,extwind=extwind,Z_top=Z_top,ZHT=ZHT,Z0=Z0,ZPD=ZPD,α=α,ZW=ZW)

    g_af= 1.0 / ((Uh / Kh) * log(U_inter / U_mid))

    return g_af
end