module PowerSystemsUnits

import Unitful
import Unitful: J, W, hr, 𝐋, 𝐌, 𝐓
using Unitful: @unit, @derived_dimension, @dimension, @refunit, @u_str, uconvert, Quantity

export asqtype, fustrip, UnitfulMissing

# Power Units
@derived_dimension PowerHour 𝐋^2*𝐌*𝐓^-2
@unit Wh "Wh" WattHour 3600J true

@derived_dimension ReactivePowerHour 𝐋^2*𝐌*𝐓^-2
@unit VARh "VARh" VARHour 3600J true

# Monetary Units
@dimension Money "Money" Currency
@refunit USD "USD" Currency Money false

# Monetary and Power Units
@derived_dimension MoneyPerPowerHour Money*𝐋^-2*𝐌^-1*𝐓^2
@unit USDPerMWh "USDPerMWh" DollarPerMegaWattHour USD/(1000000*Wh) false

include("utils.jl")

# Some gymnastics needed to get this to work at run-time.
# Sourced from https://github.com/ajkeller34/UnitfulUS.jl
const localunits = Unitful.basefactors
const localpromotion = Unitful.promotion
function __init__()
    merge!(Unitful.basefactors, localunits)
    merge!(Unitful.promotion, localpromotion)  # only if you've used @dimension
    Unitful.register(PowerSystemsUnits)
end

end
