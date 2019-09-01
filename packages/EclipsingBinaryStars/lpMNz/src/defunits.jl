#=
    defunits
    Copyright © 2019 Mark Wells <mwellsa@gmail.com>

    Distributed under terms of the AGPL-3.0 license.
=#

const MassMsun{T} = Quantity{T,u.𝐌,typeof(Msun)}
const TimeDay{T} = Quantity{T,u.𝐓,typeof(d)}
const LengthAU{T} = Quantity{T,u.𝐋,typeof(AU)}
const LengthRsun{T} = Quantity{T,u.𝐋,typeof(Rsun)}
const AreaRsunSq{T} = Quantity{T,u.𝐋^2,typeof(Rsun^2)}

const AngleDeg{T} = Quantity{T, NoDims, typeof(°)}
const AngleRad{T} = Quantity{T, NoDims, typeof(rad)}
const AbstractAngle = Union{AngleDeg,AngleRad}

short(x::Quantity) = short(x.val)unit(x)
function short(x::T) where T
    return parse(T, sprint(show, x; context=:compact => true))
end
