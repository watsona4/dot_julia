# * BitFloats

module BitFloats

export Float80,  Inf80,  NaN80,
       Float128, Inf128, NaN128

import Base: !=, *, +, -, /, <, <=, ==, ^, abs, bswap, cos, decompose, eps, exp, exp2,
             exponent, exponent_half, exponent_mask, exponent_one, floatmax, floatmin,
             isequal, isless, issubnormal, ldexp, log, log10, log2, nextfloat, precision,
             promote_rule, reinterpret, rem, round, show, sign_mask, significand,
             significand_mask, sin, sqrt, trunc, typemax, typemin, uinttype, unsafe_trunc

import Base.Math: exponent_bits, exponent_raw_max, significand_bits

using Base: bswap_int, llvmcall, uniontypes

using Base.GMP: BITS_PER_LIMB, Limb

using Core: BuiltinInts

import BitIntegers

import Random: rand
using  Random: AbstractRNG, CloseOpen01, CloseOpen12, SamplerTrivial


# * definitions

primitive type Float80  <: AbstractFloat 80  end
primitive type Float128 <: AbstractFloat 128 end

const WBF = Union{Float80,Float128}

BitIntegers.@define_integers 80

uinttype(::Type{Float80}) = UInt80
uinttype(::Type{Float128}) = UInt128

const llvmvars = ((Float80, "x86_fp80", "i80", "f80"), (Float128, "fp128", "i128", "f128"))


# * traits

sign_mask(::Type{Float80})            = 0x8000_0000_0000_0000_0000 % UInt80
exponent_mask(::Type{Float80})        = 0x7fff_0000_0000_0000_0000 % UInt80
exponent_one(::Type{Float80})         = 0x3fff_8000_0000_0000_0000 % UInt80
exponent_half(::Type{Float80})        = 0x3ffe_8000_0000_0000_0000 % UInt80
significand_mask(::Type{Float80})     = 0x0000_ffff_ffff_ffff_ffff % UInt80
explicit_bit(::Type{Float80}=Float80) = 0x0000_8000_0000_0000_0000 % UInt80
# non-implicit most significand bit of significand is actually stored for Float80

sign_mask(::Type{Float128})           = 0x8000_0000_0000_0000_0000_0000_0000_0000
exponent_mask(::Type{Float128})       = 0x7fff_0000_0000_0000_0000_0000_0000_0000
exponent_one(::Type{Float128})        = 0x3fff_0000_0000_0000_0000_0000_0000_0000
exponent_half(::Type{Float128})       = 0x3ffe_0000_0000_0000_0000_0000_0000_0000
significand_mask(::Type{Float128})    = 0x0000_ffff_ffff_ffff_ffff_ffff_ffff_ffff

significand_bits(::Type{T}) where {T<:WBF} = trailing_ones(significand_mask(T))
exponent_bits(   ::Type{T}) where {T<:WBF} = sizeof(T)*8 - significand_bits(T) - 1
exponent_bias(   ::Type{T}) where {T<:WBF} = Int(exponent_one(T) >> significand_bits(T))
# exponent_bias is 16383 for both types
exponent_raw_max(::Type{T}) where {T<:WBF} = Int(exponent_mask(T) >> significand_bits(T))


eps(     ::Type{Float80})  = reinterpret(Float80,  0x3fc0_8000_0000_0000_0000 % UInt80)
floatmin(::Type{Float80})  = reinterpret(Float80,  0x0001_8000_0000_0000_0000 % UInt80)
floatmax(::Type{Float80})  = reinterpret(Float80,  0x7ffe_ffff_ffff_ffff_ffff % UInt80)
typemin( ::Type{Float80})  = -Inf80
typemax( ::Type{Float80})  =  Inf80

eps(     ::Type{Float128}) = reinterpret(Float128, 0x3f8f_0000_0000_0000_0000_0000_0000_0000)
floatmin(::Type{Float128}) = reinterpret(Float128, 0x0001_0000_0000_0000_0000_0000_0000_0000)
floatmax(::Type{Float128}) = reinterpret(Float128, 0x7ffe_ffff_ffff_ffff_ffff_ffff_ffff_ffff)
typemin( ::Type{Float128}) = -Inf128
typemax( ::Type{Float128}) =  Inf128

const Inf80 = reinterpret(Float80,   0x7fff_8000_0000_0000_0000 % UInt80)
const NaN80 = reinterpret(Float80,   0x7fff_c000_0000_0000_0000 % UInt80)

const Inf128 = reinterpret(Float128, 0x7fff_0000_0000_0000_0000_0000_0000_0000)
const NaN128 = reinterpret(Float128, 0x7fff_8000_0000_0000_0000_0000_0000_0000)

precision(::Type{Float80})  = 64
precision(::Type{Float128}) = 113


# * float functions

function exponent(x::T) where T<:WBF
    @noinline throw1(x) = throw(DomainError(x, "Cannot be NaN or Inf."))
    @noinline throw2(x) = throw(DomainError(x, "Cannot be subnormal converted to 0."))
    xs = reinterpret(Unsigned, x) & ~sign_mask(T)
    xs >= exponent_mask(T) && throw1(x)
    k = Int(xs >> significand_bits(T))
    if k == 0 # x is subnormal
        xs == 0 && throw2(x)
        m = leading_zeros(xs) - exponent_bits(T)
        if x isa Float80
            m -= 1 # non-implicit bit
        end
        k = 1 - m
    end
    return k - exponent_bias(T)
end

function significand(x::T) where T<:WBF
    xu = reinterpret(Unsigned, x)
    xs = xu & ~sign_mask(T)
    xs >= exponent_mask(T) && return x # NaN or Inf
    if xs <= significand_mask(T) # x is subnormal
        xs == 0 && return x # +-0
        m = unsigned(leading_zeros(xs) - exponent_bits(T)) - (x isa Float80)
        xs <<= m
        xu = xs | (xu & sign_mask(T))
        if x isa Float80
            xu |= explicit_bit() # set non-implicit bit to 1
        end
    end
    xu = (xu & ~exponent_mask(T)) | exponent_one(T)
    return reinterpret(T, xu)
end

function squeezeimplicit(u::UInt80)
    s = ((u & significand_mask(Float80)) << 1) & significand_mask(Float80)
    ((u & ~significand_mask(Float80)) | s) >> 1
end

function unsqueezeimplicit(u::UInt80)
    e = (u & ~(significand_mask(Float80) >> 1)) << 1
    u = e | (u & (significand_mask(Float80) >> 1))
    iszero(exponent_mask(Float80) & u) ? # zero or subnormal
        u :
        u | explicit_bit()
end

squeezeimplicit(f::UInt128) = f
unsqueezeimplicit(f::UInt128) = f

function nextfloat(f::WBF, d::Integer)
    F = typeof(f)
    fumax = squeezeimplicit(reinterpret(Unsigned, F(Inf)))
    U = typeof(fumax)

    isnan(f) && return f
    fi = reinterpret(Signed, f)
    fneg = fi < 0
    fu = squeezeimplicit(unsigned(fi & typemax(fi)))

    dneg = d < 0
    da = Base.uabs(d)
    if da > typemax(U)
        fneg = dneg
        fu = fumax
    else
        du = da % U
        if fneg ⊻ dneg
            if du > fu
                fu = min(fumax, du - fu)
                fneg = !fneg
            else
                fu = fu - du
            end
        else
            if fumax - fu < du
                fu = fumax
            else
                fu = fu + du
            end
        end
    end
    fu = unsqueezeimplicit(fu)
    if fneg
        fu |= sign_mask(F)
    end
    reinterpret(F, fu)
end

# for Float80, left-most (non-implicit) bit of significand should be 0
function issubnormal(x::T) where {T<:WBF}
    y = reinterpret(Unsigned, x)
    (y & exponent_mask(T) == 0) & (y & significand_mask(T) != 0)
end

function ldexp(x::T, e::Integer) where T<:WBF
    xu = reinterpret(Unsigned, x)
    xs = xu & ~sign_mask(T)
    xs >= exponent_mask(T) && return x # NaN or Inf
    k = Int(xs >> significand_bits(T))
    if k == 0 # x is subnormal
        xs == 0 && return x # +-0
        m = leading_zeros(xs) - exponent_bits(T) - (x isa Float80)
        ys = xs << unsigned(m)
        xu = ys | (xu & sign_mask(T))
        k = 1 - m
        # underflow, otherwise may have integer underflow in the following n + k
        e < -50000 && return flipsign(T(0.0), x)
    end
    # For cases where e of an Integer larger than Int make sure we properly
    # overflow/underflow; this is optimized away otherwise.
    if e > typemax(Int)
        return flipsign(T(Inf), x)
    elseif e < typemin(Int)
        return flipsign(T(0.0), x)
    end
    n = e % Int
    k += n
    # overflow, if k is larger than maximum possible exponent
    if k >= exponent_raw_max(T)
        return flipsign(T(Inf), x)
    end
    if k > 0 # normal case
        xu = (xu & ~exponent_mask(T)) | (rem(k, uinttype(T)) << significand_bits(T))
        if x isa Float80
            xu |= explicit_bit() # was
        end
        return reinterpret(T, xu)
    else # subnormal case
        expo = significand_bits(T) - (x isa Float80)
        if k <= -expo # underflow
            # overflow, for the case of integer overflow in n + k
            e > 50000 && return flipsign(T(Inf), x)
            return flipsign(T(0.0), x)
        end
        k += expo # k > 0
        z = T(2.0)^-expo
        xu = (xu & ~exponent_mask(T)) | (rem(k, uinttype(T)) << significand_bits(T))
        x isa Float80 && (xu |= explicit_bit())
        return z*reinterpret(T, xu)
    end
end


# * conversions

# ** signedness

reinterpret(::Type{Unsigned}, x::Float80)  = reinterpret(UInt80, x)
reinterpret(::Type{Unsigned}, x::Float128) = reinterpret(UInt128, x)
reinterpret(::Type{Signed},   x::Float80)  = reinterpret(Int80, x)
reinterpret(::Type{Signed},   x::Float128) = reinterpret(Int128, x)

Signed(  x::WBF) = Int(x)
Unsigned(x::WBF) = UInt(x)

trunc(::Type{Signed},   x::WBF) = trunc(Int, x)
trunc(::Type{Integer},  x::WBF) = trunc(Int, x)
trunc(::Type{Unsigned}, x::WBF) = trunc(UInt, x)


# ** from ints

# unsafe_trunc & F(::T)
for (F, f, i) = llvmvars
    for T = uniontypes(BuiltinInts)
        s = 8*sizeof(T)

        # T -> F
        itofp = T <: Signed ? :sitofp : :uitofp
        @eval begin
            (::Type{$F})(x::$T) = llvmcall(
                $"""
                %y = $itofp i$s %0 to $f
                %mi = bitcast $f %y to $i
                ret $i %mi
                """,
                $F, Tuple{$T}, x)

            promote_rule(::Type{$F}, ::Type{$T}) = $F
        end
        T === Bool && continue

        # F -> T
        fptoi = T <: Signed ? :fptosi : :fptoui
        @eval unsafe_trunc(::Type{$T}, x::$F) = llvmcall(
            $"""
            %x = bitcast $i %0 to $f
            %y = $fptoi $f %x to i$s
            ret i$s %y
            """,
            $T, Tuple{$F}, x)
    end
end

# trunc & T(::F)
for Tf in (Float80, Float128)
    for Ti in Base.BitInteger_types
        Ti == Int128 && continue
        @eval begin
            function trunc(::Type{$Ti},x::$Tf)
                # unlike in Base, these expressions can't be computed at compile time,
                # this segfaults otherwise
                if $Tf(typemin($Ti)) - one($Tf) < x < $Tf(typemax($Ti)) + one($Tf)
                    return unsafe_trunc($Ti, x)
                else
                    throw(InexactError(:trunc, $Ti, x))
                end
            end

            function (::Type{$Ti})(x::$Tf)
                if $Tf(typemin($Ti)) <= x < $Tf(typemax($Ti)) + one($Tf) && (round(x, RoundToZero) == x)
                    return unsafe_trunc($Ti, x)
                else
                    throw(InexactError($(Expr(:quote,Ti.name.name)), $Ti, x))
                end
            end
        end
    end

    Ti = Int128
    @eval begin
        function trunc(::Type{$Ti},x::$Tf)
            if $Tf(typemin($Ti)) <= x < $Tf(typemax($Ti))
                return unsafe_trunc($Ti,x)
            else
                throw(InexactError(:trunc, $Ti, x))
            end
        end

        function (::Type{$Ti})(x::$Tf)
            if ($Tf(typemin($Ti)) <= x < $Tf(typemax($Ti))) && (round(x, RoundToZero) == x)
                return unsafe_trunc($Ti,x)
            else
                throw(InexactError($(Expr(:quote,Ti.name.name)), $Ti, x))
            end
        end
    end
end


# ** from floats

for (F, f, i) = llvmvars
    for (S, s) = ((Float32, :float), (Float64, :double))
        @eval begin
            (::Type{$F})(x::$S) = llvmcall(
                $"""
                %y = fpext $s %0 to $f
                %yi = bitcast $f %y to $i
                ret $i %yi
                """,
                $F, Tuple{$S}, x)

            (::Type{$S})(x::$F) = llvmcall(
                $"""
                %x = bitcast $i %0 to $f
                %y = fptrunc $f %x to $s
                ret $s %y
                """,
                $S, Tuple{$F}, x)

            promote_rule(::Type{$F}, ::Type{$S}) = $F
        end
    end
    @eval begin
        (::Type{$F})(x::Float16) = $F(Float32(x))
        (::Type{Float16})(x::$F) = Float16(Float32(x))
        promote_rule(::Type{$F}, ::Type{Float16}) = $F
    end
end


# ** Float80 <-> Float128

promote_rule(::Type{Float128}, ::Type{Float80}) = Float128

if false # unimplemented by llvm
    @eval begin
        (::Type{Float128})(x::Float80) = llvmcall(
            """
            %x = bitcast i80 %0 to x86_fp80
            %y = fpext x86_fp80 %x to fp128
            %yi = bitcast fp128 %y to i128
            ret i128 %yi
            """,
            Float128, Tuple{Float80}, x)

        (::Type{Float80})(x::Float128) = llvmcall(
            """
            %x = bitcast i128 %0 to fp128
            %y = fptrunc fp128 %x to x86_fp80
            %yi = bitcast x86_fp80 %y to i80
            ret i80 %yi
            """,
            Float80, Tuple{Float128}, x)
    end
else
    function (::Type{Float128})(x::Float80)
        u = reinterpret(Unsigned, x)
        se = ((u & ~significand_mask(Float80)) % UInt128) << 48
        u &= significand_mask(Float80) >> 1 # >> 1 for explicit bit
        reinterpret(Float128, se | ((u % UInt128) << 49))
    end

    function (::Type{Float80})(x::Float128)
        u = reinterpret(Unsigned, x)
        se = ((u & ~significand_mask(Float128)) >> 48) % UInt80
        v = ((u & significand_mask(Float128)) >> 49) % UInt80
        if se & exponent_mask(Float80) != 0
            v |= explicit_bit()
        end
        reinterpret(Float80, se | v)
    end
end


# ** BigFloat

function (::Type{BigFloat})(x::WBF; precision::Integer=Base.MPFR.DEFAULT_PRECISION[])
    if isnan(x)
        BigFloat(NaN, precision=precision)
    elseif isinf(x)
        BigFloat(x < 0 ? -Inf : Inf, precision=precision)
    elseif iszero(x)
        BigFloat(x < 0 ? -0.0 : 0.0, precision=precision)
    else
        z = BigFloat(precision=precision)
        z.exp = exponent(x) + 1
        z.sign = x >= zero(x) ? 1 : -1
        y = significand(x)
        nlimbs = div(precision + BITS_PER_LIMB-1, BITS_PER_LIMB)
        mask = ~(Limb(0)) << mod(BITS_PER_LIMB - precision, BITS_PER_LIMB)

        if x isa Float80
            u = reinterpret(Unsigned, y) % UInt64
            n = nlimbs - div(64, BITS_PER_LIMB) + 1
        else
            u = reinterpret(Unsigned, y) % UInt128
            u = (u << 16) >> 1
            u |= sign_mask(Float128) # explicit 1 for the msb
            n = nlimbs - div(128, BITS_PER_LIMB) + 1
        end

        for i = 1:nlimbs
            l = (u >> ((i-n) * BITS_PER_LIMB)) % Limb
            i == 1 && (l &= mask)
            GC.@preserve z unsafe_store!(z.d, l, i)
        end
        z
    end
end

# alternative for Float128, useful to compare accuracy
function BigFloat_mpfr(x::Float128)
    z = BigFloat()
    ccall((:mpfr_set_float128, :libmpfr), Int32, (Ref{BigFloat}, Float128, Int32), z, x, Base.MPFR.ROUNDING_MODE[])
    if isnan(x) && signbit(x) != signbit(z)
        z.sign = -z.sign
    end
    return z
end

function Float128(x::BigFloat)
    ispos = x.sign == 1
    if isnan(x)
        NaN128
    elseif iszero(x) # should not be necessary (i.e. it works in the else branch too)
       x.sign * zero(Float128)
    else
        expo = x.exp - 1 # exponent bias for mpfr is -1
        # comparing x > floatmax(Float128) allocates a BigFloat, so we look at
        # expo to check for infinity
        if expo > 16383 || isinf(x)
            return x.sign * Inf128
        end
        e = Int(expo + exponent_bias(Float128))
        @assert e <= Int(0x7fff)
        n = ((x.prec-1) >> ( 6 - (BITS_PER_LIMB === 32))) + 1 # should be the number of limbs
        @assert n >= 1
        GC.@preserve x if BITS_PER_LIMB === 64
            u = (unsafe_load(x.d, n) % UInt128) << 64
            if n > 1
                u |= unsafe_load(x.d, n-1)
            end
        else
            u = zero(UInt128)
            shift = 96
            while n > 0 && shift >= 0
                u |= (unsafe_load(x.d, n) % UInt128) << shift
                n -= 1
                shift -= 32
            end
        end
        if e <= 0 # subnormal
            u >>= -e
            e = 0
        else
            u <<= 1 # remove explicit bit
        end
        u >>= exponent_bits(Float128) + 1
        u |= UInt128(e) << significand_bits(Float128)
        u |= sign_mask(Float128) * !ispos
        reinterpret(Float128, u)
    end
end

# doesn't work properly :(
# Float128_mpfr(x::BigFloat) =
#    ccall((:mpfr_get_float128, :libmpfr), Float128, (Ref{BigFloat}, Int32), x, Base.MPFR.ROUNDING_MODE[])

Float80(x::BigFloat) = Float80(Float128(x))


# ** round

for (F, f, i, fn) = llvmvars
    # TODO: can be broken for Float128
    for (mode, llvmfun) = ((:ToZero, :trunc), (:Down, :floor),
                           (:Up, :ceil), (:Nearest, :rint))
        fun = "@llvm.$llvmfun.$fn"
        @eval round(x::$F, r::$(RoundingMode{mode})) = llvmcall(
            ($"""declare $f $fun($f %Val)""",
             $"""
             %x = bitcast $i %0 to $f
             %y = call $f $fun($f %x)
             %z = bitcast $f %y to $i
             ret $i %z
             """), $F, Tuple{$F}, x)
    end
end


# * comparisons

for (F, f, i) = llvmvars
    for (op, fop) = ((:(==), :oeq), (:!=, :une), (:<, :olt), (:<=, :ole))
        @eval $op(x::$F, y::$F) = llvmcall(
            $"""
            %x = bitcast $i %0 to $f
            %y = bitcast $i %1 to $f
            %b = fcmp $fop $f %x, %y
            %c = zext i1 %b to i8
            ret i8 %c
            """,
            Bool, Tuple{$F,$F}, x, y)
    end

    # adapted from fpislt in intrinsics.cpp
    # could as well be written in Julia
    @eval fpislt(x::$F, y::$F) = llvmcall(
        $"""
        ; %xi = %0
        ; %yi = %1
        %xf = bitcast $i %0 to $f
        %yf = bitcast $i %1 to $f
        %c11 = fcmp ord $f %xf, %xf ; !isnan(xf)
        %c12 = fcmp uno $f %yf, %yf ; isnan(yf)
        %c1  = or i1 %c11, %c12
        %c21 = fcmp ord $f %xf, %yf ; !(isnan(xf) | isnan(yf))
        %c2211 = icmp sge $i %0, 0 ; xi >= 0
        %c2212 = icmp slt $i %0, %1 ; xi < yi
        %c221 = and i1 %c2211, %c2212
        %c2221 = icmp slt $i %0, 0 ; xi < 0
        %c2222 = icmp ugt $i %0, %1 ; unsigned(xi) > unsigned(yi)
        %c222 = and i1 %c2221, %c2222
        %c22 = or i1 %c221, %c222
        %c2 = and i1 %c21, %c22
        %c = or i1 %c1, %c2
        %cbool = zext i1 %c to i8
        ret i8 %cbool
        """,
        Bool, Tuple{$F,$F}, x, y)
end

isless(x::T, y::T) where {T<:WBF} = fpislt(x, y)

# implements Base.fpiseq
isequal(x::T, y::T) where {T<:WBF} =
    (isnan(x) & isnan(y)) | (reinterpret(Unsigned, x) === reinterpret(Unsigned, y))


# * arithmetic

for (F, f, i, fn) = llvmvars
    for (op, fop) = ((:*, :fmul), (:/, :fdiv), (:+, :fadd), (:-, :fsub), (:rem, :frem))
        @eval $op(x::$F, y::$F) = llvmcall(
            $"""
            %x = bitcast $i %0 to $f
            %y = bitcast $i %1 to $f
            %m = $fop $f %x, %y
            %mi = bitcast $f %m to $i
            ret $i %mi
            """, $F, Tuple{$F,$F}, x, y)
    end
    for (op, fop) = (:abs => :fabs, :log2 => :log2, :exp2 => :exp2, :sqrt => :sqrt,
                     :sin => :sin, :cos => :cos, :exp => :exp, :log => :log, :log10 => :log10)
        if F === Float128 && op ∈ (:log2, :exp2, :sqrt, :sin, :cos, :exp, :log, :log10)
            @eval $op(x::$F) = $F($op(big(x)))
        else
            @eval $op(x::$F) = llvmcall(
                ($"""declare $f  @llvm.$fop.$fn($f %Val)""",
                 $"""
                 %x = bitcast $i %0 to $f
                 %y = call $f @llvm.$fop.$fn($f %x)
                 %z = bitcast $f %y to $i
                 ret $i %z
                 """), $F, Tuple{$F}, x)
        end
    end
    F == Float128 && continue # broken
    @eval ^(x::$F, y::$F) = llvmcall(
        ($"""declare $f @llvm.pow.$fn($f %Val, $f %Power)""",
         $"""
         %x = bitcast $i %0 to $f
         %y = bitcast $i %1 to $f
         %m = call $f @llvm.pow.$fn($f %x, $f %y)
         %mi = bitcast $f %m to $i
         ret $i %mi
         """), $F, Tuple{$F,$F}, x, y)
end

^(x::Float128, y::Float128) = Float128(big(x)^big(y))

^(x::WBF, n::Integer) = x^(oftype(x, n))
-(x::F) where {F<:WBF} = F(-0.0) - x


# * hashing

# could return UInt64 instead of Int128 for Float80
function decompose(x::WBF)::Tuple{Int128,Int,Int}
    T = typeof(x)
    isnan(x) && return 0, 0, 0
    isinf(x) && return ifelse(x < 0, -1, 1), 0, 0
    n = reinterpret(Unsigned, x)
    s = (n & significand_mask(T)) % Int128
    e = ((n & exponent_mask(T)) >> significand_bits(T)) % Int
    if T === Float128 # add explicit bit
        s |= Int128(e != 0) << significand_bits(T)
    end
    d = ifelse(signbit(x), -1, 1)
    # for Float80, significand_bits(T) includes the explicit bit
    E = exponent_bias(T) + significand_bits(T) - (T === Float80)
    s, e - E + (e == 0), d
end


# * rand

rand(rng::AbstractRNG, ::SamplerTrivial{CloseOpen12{Float80}}) =
    reinterpret(Float80, rand(rng, UInt64) | exponent_one(Float80) | explicit_bit())

rand(rng::AbstractRNG, ::SamplerTrivial{CloseOpen12{Float128}}) =
    reinterpret(Float128, rand(rng, UInt128) & significand_mask(Float128) | exponent_one(Float128))

rand(rng::AbstractRNG, ::SamplerTrivial{CloseOpen01{T}}) where {T<:WBF} =
    rand(rng, CloseOpen12(T)) - one(T)


# * misc

bswap(x::WBF) = bswap_int(x)

show(io::IO, x::WBF) =
    if isnan(x)
        print(io, "NaN", sizeof(x)*8)
    elseif isinf(x)
        print(io, x > 0 ? "" : '-',  "Inf", sizeof(x)*8)
    else
        show(io, BigFloat(x, precision=precision(x)))
    end


end # module
