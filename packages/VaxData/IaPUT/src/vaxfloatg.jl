export VaxFloatG

primitive type VaxFloatG <: VaxFloat 64 end

VaxFloatG(x::UInt64) = reinterpret(VaxFloatG, ltoh(x))
function VaxFloatG(x::T) where T <: Real
    y = reinterpret(UInt64, convert(Float64, x))

    part1 = y & bmask32
    part2 = (y >>> 32) & bmask32

    if ENDIAN_BOM === 0x04030201
        vaxpart2 = part1
        ieeepart1 = part2
    else
        vaxpart2 = part2
        ieeepart1 = part1
    end

    e = reinterpret(Int64, ieeepart1 & IEEE_T_EXPONENT_MASK)

    if ieeepart1 & ~SIGN_BIT_64 === zero(UInt64)
        # ±0.0 becomes 0.0
        return zero(VaxFloatG)
    elseif e === IEEE_T_EXPONENT_MASK
        # Vax types don't support ±Inf or NaN
        throw(InexactError(:VaxFloatG, VaxFloatG, x))
    else
        e >>>= VAX_G_MANTISSA_SIZE
        m = ieeepart1 & VAX_G_MANTISSA_MASK

        if e === zero(Int64)
            m = (m << 1) | (vaxpart2 >>> 31)
            vaxpart2 <<= 1
            while m & VAX_G_HIDDEN_BIT === zero(UInt64)
                m = (m << 1) | (vaxpart2 >>> 31)
                vaxpart2 <<= 1
                e -= one(Int64)
            end
            m &= VAX_G_MANTISSA_MASK
        end

        e += one(Int64) + VAX_G_EXPONENT_BIAS - IEEE_T_EXPONENT_BIAS
        if e <= zero(Int64)
            # Silent underflow
            return zero(VaxFloatG)
        elseif e > (2*VAX_G_EXPONENT_BIAS - 1)
            # Overflow
            throw(InexactError(:VaxFloatG, VaxFloatG, x))
        else
            vaxpart = (ieeepart1 & SIGN_BIT_64) | (e << VAX_G_MANTISSA_SIZE) | m
        end
    end

    vaxpart_1 = vaxpart & bmask16
    vaxpart_2 = (vaxpart >>> 16) & bmask16

    vaxpart_3 = vaxpart2 & bmask16
    vaxpart_4 = (vaxpart2 >>> 16) & bmask16

    res = htol((vaxpart_3 << 48) |
          (vaxpart_4 << 32) |
          (vaxpart_1 << 16) |
          vaxpart_2)

    return reinterpret(VaxFloatG, res)
end

Base.typemax(::Type{VaxFloatG}) = VaxFloatG(0xffffffffffff7fff)
Base.floatmax(::Type{VaxFloatG}) = VaxFloatG(0xffffffffffff7fff)
Base.floatmin(::Type{VaxFloatG}) = VaxFloatG(0x0000000000000010)
Base.typemin(::Type{VaxFloatG}) = VaxFloatG(0x0000000000000010)

Base.zero(::Type{VaxFloatG}) = VaxFloatG(0x0000000000000000)
Base.one(::Type{VaxFloatG}) = VaxFloatG(0x0000000000004010)

function Base.convert(::Type{Float64}, x::VaxFloatG)
    y = reinterpret(UInt64, ltoh(x))

    vaxpart_1 = y & bmask16
    vaxpart_2 = (y >>> 16) & bmask16
    vaxpart1 = (vaxpart_1 << 16) | vaxpart_2

    vaxpart_3 = (y >>> 32) & bmask16
    vaxpart_4 = (y >>> 48) & bmask16
    vaxpart2 = (vaxpart_3 << 16) | vaxpart_4

    e = reinterpret(Int64, vaxpart1 & VAX_G_EXPONENT_MASK)
    if e === zero(Int64)
        if vaxpart1 & SIGN_BIT_64 === SIGN_BIT_64
            # Reserved floating-point reserved operand
            throw(InexactError(:convert, Float64, x))
        end

        # Dirty zero
        return zero(Float64)
    else
        e >>>= VAX_G_MANTISSA_SIZE

        e -= one(Int64) + VAX_G_EXPONENT_BIAS - IEEE_T_EXPONENT_BIAS
        if e > zero(Int64)
            ieeepart1 = vaxpart1  - ((UNO64 + VAX_G_EXPONENT_BIAS - IEEE_T_EXPONENT_BIAS) << IEEE_T_MANTISSA_SIZE)
            ieeepart2 = vaxpart2
        else
            # Subnormal result
            vaxpart1 = (vaxpart1 & (SIGN_BIT_64 | VAX_G_MANTISSA_MASK)) | VAX_G_HIDDEN_BIT
            ieeepart1 = (vaxpart1 & SIGN_BIT_64) | ((vaxpart1 & (VAX_G_HIDDEN_BIT | VAX_G_MANTISSA_MASK)) >>> (1 - e))
            ieeepart2 = (vaxpart1 << (31 + e)) | (vaxpart2 >>> (1 - e))
        end

        if ENDIAN_BOM === 0x04030201
            out1 = ieeepart2
            out2 = ieeepart1
        else
            out1 = ieeepart1
            out2 = ieeepart2
        end
    end

    res = (out2 << 32) | out1

    return reinterpret(Float64,res)
end
Base.convert(::Type{T},x::VaxFloatG) where T <: Union{Float16, Float32, BigFloat, Integer} = convert(T,convert(Float64,x))

Base.promote_rule(::Type{T},x::Type{VaxFloatG}) where T <: Union{AbstractVax, Float16, Float32, Float64, Integer} = Float64
Base.promote_rule(::Type{BigFloat},x::Type{VaxFloatG}) = BigFloat

Base.promote_type(::Type{VaxFloatG}, ::Type{VaxFloatG}) = Float64

