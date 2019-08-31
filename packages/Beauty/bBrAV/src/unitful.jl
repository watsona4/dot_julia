# Part of Beauty.jl: Add Beauty to your julia output.
# Copyright (C) 2019 Quantum Factory GmbH

using Unitful
using DocStringExtensions

"""

Return the `Unitful.Units` to be used to output a quantity. This
method can dispatch on the type of the dimensions of the quantity
(first argument) and gets the quantity itself as second argument.

"""
function force_display_units(dim::Any, value::Any)
    if haskey(favorite_units, dim)
        for u in favorite_units[dim]
            x = uconvert(u, value) / u
            if one(x) <= x && x < 10000one(x)
                return u
            end
        end
        return first(favorite_units[dim])
    end
    return Unitful.unit(value)
end

# default output preferences for units
const favorite_units = Dict(
    Unitful.dimension(Unitful.m) => [
        Unitful.m,
        Unitful.mm, Unitful.µm, Unitful.nm,
        Unitful.km
    ],
    Unitful.dimension(Unitful.kg) => [
        Unitful.kg, Unitful.g
    ],
    Unitful.dimension(Unitful.A) => [
        Unitful.A,
        Unitful.µA, Unitful.mA,
        Unitful.kA
    ],
    Unitful.dimension(Unitful.V) => [
        Unitful.V, Unitful.µV, Unitful.mV, Unitful.kV
    ],
    Unitful.dimension(Unitful.W) => [
        Unitful.W,
        Unitful.µW, Unitful.mW,
        Unitful.kW, Unitful.MW, Unitful.GW
    ]
)

"""

Show displays `Unitful.AbstractQuantity` objects.

$(SIGNATURES)

"""
Base.show(io::IO, ::MIME"text/plain", n::Unitful.AbstractQuantity) =
    _show(io, "text/plain", n)
Base.show(io::IO, ::MIME"text/latex", n::Unitful.AbstractQuantity) =
    _show(io, "text/latex", n)
Base.show(io::IO, ::MIME"text/html", n::Unitful.AbstractQuantity) =
    _show(io, "text/html", n)

function _show(
    io::IO,
    mime::String,
    n::Unitful.AbstractQuantity{T,D,U}
) where {T,D,U}
    # determine the appropriate unit u
    u = force_display_units(D, n)
    local x
    try
        x = Unitful.ustrip(Unitful.uconvert(u, n))
    catch e
        u = Unitful.unit(n)
        x = Unitful.ustrip(n)
    end
    # output the number n with its units stripped away
    if x isa Rational && denominator(x) == 1
        # instead of N//1, just show N
        show(io, mime, numerator(x))
    elseif x isa Rational
        # don't output fractions but convert to a floating point number
        show(io, mime, float(x))
    else
        show(io, mime, x) 
    end

    # get an output representation of the units,
    # from Unitful's Base.show implementation
    #
    # To Do: It would be cleaner to replicate Unitful's implementation
    # at
    # https://github.com/ajkeller34/Unitful.jl/blob/master/src/display.jl
    buf = IOBuffer()
    print(buf, u)
    s = String(take!(buf))
    # optional replacement of Unitful's "L" by "l"
    if true 
        s = replace(s, "L" => "l")
    end

    # print a separator and the units in the chosen output
    # representation
    if mime == "text/latex"
        print(io, "\ensuremath{\textrm{~")
        print(io, replace(s, r"\^-?." => s"$^{\0}$"))
        print(io, "}}")
    elseif mime == "text/html"
        s = replace(s, r"\^-?." => s"<sup>\0</sup>")
        print(io, "&nbsp;")
        print(io, replace(s, "^" => ""))
        else
        # assume "text/plain"
        if hasunicodesupport(io)
            print(io, " ") # narrow non-breaking space
            print(io, unicode_superscript_digits(
                replace(s, "^" => "")
            ))
        else
            print(io, " ")
            print(io, s)
        end
    end

    # return nothing
    nothing
end
