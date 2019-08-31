# Part of Beauty.jl: Add Beauty to your julia output.
# Copyright (C) 2019 Quantum Factory GmbH

"""

Guesses if an IO object has support for unicode and returns true if
this is the case, false otherwise.

Implemented by checking for a nonstandard property :unicode and
falling back to the property :color. The rationale is that if a
terminal is smart enough to support color, it will probably also be
modern enough to support unicode. If this heuristic fails, explicitly
set the :unicode to be false to overrule it.

!!! info "To Do"
    An IOContext might come with an entire history of past settings.
    Consider checking if :color was ever true in that history to
    get a better heuristic (:color can be turned off simply because
    colorful output is undesired in some context).

"""
function hasunicodesupport(io::IO)
    return get(io, :unicode, get(io, :color, false))
end

"""

Replace arbitrary many pairs of strings (e.g. "ac" => "abc") in an
`AbstractString` passed as first argument.

```jldoctest
import Beauty
Beauty.stringreplace("ACDFH", "A" => "AB", "D" => "DE", "FH" => "FGH")

# output

"ABCDEFGH"
```

"""
function stringreplace(s::AbstractString, pairs::Pair{String,String}...)
    for pair in pairs
        s = replace(s, pair)
    end
    return s
end

"""

Return the argument, an `AbstractString`, with all digits and the
minus sign replaced by superscript digits.

```jldoctest
import Beauty
Beauty.unicode_superscript_digits("x^-13")

# output

"x^⁻¹³"
```

"""
function unicode_superscript_digits(s::AbstractString)
    stringreplace(
        s,
        "-" => "⁻",
        "0" => "⁰",
        "1" => "¹",
        "2" => "²",
        "3" => "³",
        "4" => "⁴",
        "5" => "⁵",
        "6" => "⁶",
        "7" => "⁷",
        "8" => "⁸",
        "9" => "⁹"
    )
end

function dec_exp(x::AbstractFloat)
    if x < zero(x)
        throw(DomainError("need nonnegative value"))
    end
    if iszero(x)
        return -Inf
    end
    if isinf(x) || isnan(x)
        return Inf
    end
    cmp = 1.0 # choose a regular float, even if input is a BigFloat
    if x < cmp
        return -dec_exp(one(x) / x) - 1
    end
    exp = -1
    while cmp <= x
        # increase cmp by 10 whilst making sure not to round up
        #cmp = prevfloat(cmp * 10)
        cmp *= 10
        exp += 1
    end
    return exp
end

function format_exponent(
    mime::String, n::Integer; unicode::Bool=false
)
    exps = string(n)
    out_exp = ""
    if mime == "text/html"
        out_exp = string(
            "&middot;10<sup>",
            exps,
            "</sup>"
        )
    elseif mime == "text/latex"
        out_exp = string(
            "\ensuremath{^\textrm{",
            exps,
            "}}"
        )
    else
        # assume "text/plain"
        if unicode
            out_exp = string(
                "·10",
                unicode_superscript_digits(exps)
            )
        else
            out_exp = string(
                "*10^",
                exps
            )
        end
    end
    return out_exp
end

function format_number(
    mime::String,
    val::AbstractFloat,
    err::AbstractFloat;
    unicode=false
)
    # check inputs
    if err < zero(err)
        throw(DomainError("negative errors are not supported"))
    end
    # initialize output string
    s = ""
    # handle sign
    if val < zero(val)
        if mime == "text/latex"
            minussign = "\ensuremath{-}" # proper minus sign, but not
                                         # beautiful
            minussign = "\textrm{-}" # technically a hyphen
            s = minussign
        else
            s = "-"
        end
        val = -val
    end
    # determine the decimal exponents (number of digits in front of
    # the decimal point minus one)
    de_val = dec_exp(val)
    de_err = dec_exp(err)
    # number of digits to output
    nd_max = 4
    nd_err = 1
    if err < 2 * 10.0 ^ de_err
        # error starts with the digit 1: add another digit of
        # uncertainty output
        nd_err += 1
    end
    nan_err = false
    n_err = 0
    if isinf(de_err) || isnan(err)
        nan_err = true
        nd_err = 0
        de_err = -1_000_000 # do not influence number of digits output
    else
        n_err = round(err * 10.0 ^ (nd_err - 1 - de_err), RoundNearest)
    end
    nd_val = min(nd_max, max(1, de_val - de_err + nd_err))
    nd_err = nd_val - (de_val - de_err)
    if nan_err
        nd_err = 0
    end
    @debug "digits in value and uncertainty" nd_val nd_err
    # now round and convert the numbers to integers
    n_val = round(val * 10.0 ^ (nd_val - 1 - de_val), RoundNearest)
    # this could be one digit more than intended due to rounding;
    # check
    if n_val >= 10 ^ nd_val
        @debug "n_val rounded up" n_val 10^nd_val nd_val
        nd_val += 1
        de_val += 1
    end
    if nd_err > 0 && n_err >= 10 ^ nd_err
        @debug "n_err rounded up" n_err 10^nd_err nd_err
        # keep the extra digit in n_err and output it
        nd_err += 1
    end
    if nd_val > nd_max
        # chop one digit off both value and error
        @debug "chopping a digit"
        n_val /= 10
        nd_val -=1
        de_val += 1
        n_err /= 10
        nd_err -=1
        de_err += 1
    end
    # assert that rounding did not produce too few digits
    @assert 10n_val >= 10 ^ nd_val
    @assert nan_err || nd_err <= 0 || 10n_err >= 10 ^ nd_err
    # decide whether to output the error/uncertainty
    showerr = nd_err > 0
    # decide whether to use exponent notation with 10 ^ de_val
    showexp = de_val < 0 || de_val > nd_max
    # get the digits as String type
    s_val = string(Int(n_val))
    s_err = string(Int(n_err))
    @debug (
        "value val and error err"
    ) s_val n_val nd_val de_val s_err n_err nd_err de_err
    @assert length(s_val) == nd_val
    @assert nd_err <= 0 || length(s_err) == nd_err
    trailing_zeros = 1 + de_val - nd_val
    if !showexp
        # format number without exponent
        for i = 1:trailing_zeros
            # insert trailing zeros
            s_val = string(s_val, "0")
            nd_val += 1
        end
        s = string(s, s_val[1:min(nd_val, de_val+1)])
        if nd_val > de_val + 1
            # we need to include the decimal point
            s = string(s, ".", s_val[de_val+2:nd_val])
        end
    else
        # format number for display with exponent
        if nd_val == 1
             s = string(s, s_val[1])
        else
            s = string(s, s_val[1], ".", s_val[2:nd_val])
        end
    end
    if showerr
        err_exp = de_err
        if !showexp
            for i = 1:trailing_zeros
                # insert trailing zeros
                s_err = string(s_err, "0")
                nd_err += 1
            end
        else
            # exponent notation moves the the decimal point
            err_exp -= de_val
        end
        if nan_err
            # format error as (Inf) or (NaN) or the like
            s = string(s, "(", err, ")")
        elseif err_exp + 1 > 0 && err_exp + 2 <= nd_err
            # decimal is needed
            s = string(
                s,
                "(",
                s_err[1:err_exp+1],
                ".",
                s_err[err_exp+2:nd_err],
                ")"
            )
        else
            s = string(s, "(", s_err, ")")
        end
    end
    if showexp
        s = string(s, format_exponent(mime, de_val; unicode = unicode))
    end
    return s
end
