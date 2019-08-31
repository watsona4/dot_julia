export VaxFloatD

primitive type VaxFloatD <: VaxFloat 64 end

VaxFloatD(x::UInt64) = reinterpret(VaxFloatD, ltoh(x))
function VaxFloatD(x::T) where T <: Real
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
        return zero(VaxFloatD)
    elseif e === IEEE_T_EXPONENT_MASK
        # Vax types don't support ±Inf or NaN
        throw(InexactError(:VaxFloatD, VaxFloatD, x))
    else
        e >>>= IEEE_T_MANTISSA_SIZE
        m = ieeepart1 & IEEE_T_MANTISSA_MASK

        if e === zero(Int64)
            m = (m << 1) | (vaxpart2  >>> 31)
            vaxpart2 <<= 1
            while m & IEEE_T_HIDDEN_BIT === zero(UInt64)
                m = (m << 1) | (vaxpart2  >>> 31)
                vaxpart2 <<= 1
                e -= one(Int64)
            end
            m &= IEEE_T_MANTISSA_MASK
        end

        e += one(Int64) + VAX_D_EXPONENT_BIAS - IEEE_T_EXPONENT_BIAS
        if e <= zero(Int64)
            # Silent underflow
            return zero(VaxFloatD)
        elseif e > (2*VAX_D_EXPONENT_BIAS - 1)
            # Overflow
            throw(InexactError(:VaxFloatD, VaxFloatD, x))
        else
            vaxpart = (ieeepart1 & SIGN_BIT_64) |
                (e << VAX_D_MANTISSA_SIZE) |
                (m <<  (VAX_D_MANTISSA_SIZE - IEEE_T_MANTISSA_SIZE)) |
                (vaxpart2 >>> (32 - (VAX_D_MANTISSA_SIZE - IEEE_T_MANTISSA_SIZE)))
            vaxpart2 <<= (VAX_D_MANTISSA_SIZE - IEEE_T_MANTISSA_SIZE)
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

    return reinterpret(VaxFloatD, res)
end

Base.typemax(::Type{VaxFloatD}) = VaxFloatD(0xffffffffffff7fff)
Base.floatmax(::Type{VaxFloatD}) = VaxFloatD(0xffffffffffff7fff)
Base.typemin(::Type{VaxFloatD}) = VaxFloatD(0x0000000000000080)
Base.floatmin(::Type{VaxFloatD}) = VaxFloatD(0x0000000000000080)

Base.zero(::Type{VaxFloatD}) = VaxFloatD(0x0000000000000000)
Base.one(::Type{VaxFloatD}) = VaxFloatD(0x0000000000004080)

function Base.convert(::Type{Float64}, x::VaxFloatD)
    y = reinterpret(UInt64, ltoh(x))

    vaxpart_1 = y & bmask16
    vaxpart_2 = (y >>> 16) & bmask16
    vaxpart1 = (vaxpart_1 << 16) | vaxpart_2

    vaxpart_3 = (y >>> 32) & bmask16
    vaxpart_4 = (y >>> 48) & bmask16
    vaxpart2 = (vaxpart_3 << 16) | vaxpart_4

    if vaxpart1 & VAX_D_EXPONENT_MASK === zero(UInt64)
        if vaxpart1 & SIGN_BIT_64 === SIGN_BIT_64
            # Reserved floating-point reserved operand
            throw(InexactError(:convert, Float64, x))
        end

        # Dirty zero
        return zero(Float64)
    else
        ieeepart1 = ((vaxpart1 & SIGN_BIT_64) |
                     ((vaxpart1 & ~SIGN_BIT_64) >>>
                      (VAX_D_MANTISSA_SIZE - IEEE_T_MANTISSA_SIZE))) -
                     ((UNO64 + VAX_D_EXPONENT_BIAS - IEEE_T_EXPONENT_BIAS) << IEEE_T_MANTISSA_SIZE)
        ieeepart2 = (vaxpart1 << (32 - (VAX_D_MANTISSA_SIZE - IEEE_T_MANTISSA_SIZE))) |
                    (vaxpart2 >>> (VAX_D_MANTISSA_SIZE - IEEE_T_MANTISSA_SIZE))

        if ENDIAN_BOM === 0x04030201
            out1 = ieeepart2
            out2 = ieeepart1
        else
            out1 = ieeepart1
            out2 = ieeepart2
        end
    end

    res = (out2 << 32) | (out1 & bmask32)

    return reinterpret(Float64,res)
end
Base.convert(::Type{T},x::VaxFloatD) where T <: Union{Float16,Float32, BigFloat, Integer} = convert(T,convert(Float64,x))

Base.promote_rule(::Type{T},x::Type{VaxFloatD}) where T <: Union{AbstractVax, Float16, Float32, Float64, Integer} = Float64
Base.promote_rule(::Type{BigFloat},x::Type{VaxFloatD}) = BigFloat

Base.promote_type(::Type{VaxFloatD}, ::Type{VaxFloatD}) = Float64

