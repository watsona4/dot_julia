# Height-Diameter Equations

## Calculating missing tree heights using a height diameter equation
Height-diameter equations are widespread in forestry and have been the subject of extensive research over the past decades.
As a result there is a large amount of formulas and parameter sets based on regional, operational and biological differences.

In forest inventories, measuring heights on all trees may not be possible so formulas are used to fill in missing data.

## Types

ForestBiometrics creates a type `HeightDiameter` that holds an equation form and its parameters for estimating a tree height given a diameter at a fixed height(usually 4.5 feet).

    struct HeightDiameter <: Function
    formula::Function
    b
    end

`formula` can be one of the pre-named equation forms such as Wyckoff, Korf, etc.

    Wyckoff=(x,b)->4.5+exp(b[1]+(b[2]/(x+1)) #defined in HeightDub.jl

`b` is a dictionary of species specific equation parameters in the form of

    String: Array{Float64} #species specific coefficients stored as dictionary

    coeffs =Dict{String,Array{Float64}}(
    "WP"=> [5.19988	-9.26718],
    "WL"=>[4.97407	-6.78347],
    "DF"=>[4.81519	-7.29306] )

    HD = HeightDiameter(Wyckoff,coeffs)

If a user wanted to change model parameters, they can redefine them as needed independent of model form or change both equation form and associated parameters.

Pre-defined equation forms available include:

2 parameter equation forms, mainly from LMFOR package:

Curtis: ``ht(diameter) = bh + b1(\frac{dbh}{1+dbh})^{b2}``

Michailoff: ``ht(diameter) = bh + b1e^{b2dbh^{-1}}``

Meyer: ``ht(diameter) = bh + b1(1-e^{-b2dbh})``

Micment: ``ht(diameter) = bh + \frac{b1dbh}{b2+dbh}``

Micment2: ``ht(diameter) = bh +\frac{dbh}{b1+b2*dbh}``

Naslund: ``ht(diameter) = bh + \frac{dbh^2}{(b1+b2dbh)^{2}}``

Naslund2: ``ht(diameter) = bh + \frac{dbh^2}{(b1+e^{b2}dbh)^2}``

Naslund3: ``ht(diameter) = bh + \frac{dbh^2}{e^{b1}+b2dbh^{2}}``

Naslund4: ``ht(diameter) = bh + \frac{dbh^2}{(e^{b1}+e^{b2}dbh)^{2}}``

Power: ``ht(diameter) = bh + b1dbh^{b2}``

Wyckoff: ``ht(diameter) = bh + exp(b1+\frac{b2}{dbh+1})``


3 parameter equations, mainly from LMFOR R package:

Chapman: ``ht(diameter) = bh + b1(1-e^{-b2dbh})^{b3}``

Gompertz: ``ht(diameter) = bh + b1exp(-b2exp(-b3dbh))``

HossfeldIV: ``ht(diameter) = bh + \frac{b1}{1+\frac{1}{b2dbh^{b3}}}``

Korf: ``ht(diameter) = bh + b1exp(-b2dbh^{-b3})``

Logistic: ``ht(diameter) = bh + \frac{b1}{1+b2e^{-b3dbh}}``

Monserud: ``ht(diameter) = bh + exp(b1 + b2dbh^{b3})``

Prodan: ``ht(diameter) = bh + \frac{dbh^2}{b1+b2dbh+b3dbh^2}``

Ratkowsky: ``ht(diameter) = bh + b1exp(\frac{-b2}{dbh+b3})``

Sibbesen: ``ht(diameter) = bh + b1dbh^{b2dbh^{-b3}}``

Weibull: ``ht(diameter) = bh + b1(1-e^{-b2dbh^{b3}})``

## Functions

`calculate_height(params::HeightDiameter,dbh,species)`

This takes a HeightDiameter type and applies the function given a species and dbh.
