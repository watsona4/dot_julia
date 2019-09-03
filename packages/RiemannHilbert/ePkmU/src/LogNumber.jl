

# represents s*log(ε) + c as ε -> 0
struct LogNumber <: Number
    s::ComplexF64
    c::ComplexF64
end


@inline logpart(z::Number) = zero(z)
@inline finitepart(z::Number) = z

@inline logpart(l::LogNumber) = l.s
@inline finitepart(l::LogNumber) = l.c


Base.promote_rule(::Type{LogNumber}, ::Type{<:Number}) = LogNumber
Base.convert(::Type{LogNumber}, z::LogNumber) = z
Base.convert(::Type{LogNumber}, z::Number) = LogNumber(0, z)

==(a::LogNumber, b::LogNumber) = logpart(a) == logpart(b) && finitepart(a) == finitepart(b)
Base.isapprox(a::LogNumber, b::LogNumber; opts...) = ≈(logpart(a), logpart(b); opts...) && ≈(finitepart(a), finitepart(b); opts...)

(l::LogNumber)(ε) = logpart(l)*log(ε) + finitepart(l)

for f in (:+, :-)
    @eval begin
        $f(a::LogNumber, b::LogNumber) = LogNumber($f(a.s, b.s), $f(a.c, b.c))
        $f(l::LogNumber, b::Number) = LogNumber(l.s, $f(l.c, b))
        $f(a::Number, l::LogNumber) = LogNumber($f(l.s), $f(a, l.c))
    end
end

-(l::LogNumber) = LogNumber(-l.s, -l.c)

for Typ in (:Bool, :Number)
    @eval begin
        *(l::LogNumber, b::$Typ) = LogNumber(l.s*b, l.c*b)
        *(a::$Typ, l::LogNumber) = LogNumber(a*l.s, a*l.c)
    end
end
/(l::LogNumber, b::Number) = LogNumber(l.s/b, l.c/b)

function exp(l::LogNumber)::ComplexF64
    if real(l.s) > 0
        0.0+0.0im
    elseif real(l.s) < 0
        Inf+Inf*im
    elseif real(l.s) == 0 && imag(l.s) == 0
        log(l.c)
    else
        NaN + NaN*im
    end
end

# This is a relative version of dual number, in the sense that its realpart*(1+epsilon)
struct RiemannDual{T} <: Number
    realpart::T
    epsilon::T
end

RiemannDual(x, y) = RiemannDual(promote(x, y)...)

RiemannDual(x::Dual) = RiemannDual(realpart(x), epsilon(x))
Dual(x::RiemannDual) = Dual(realpart(x), epsilon(x))
dual(x::RiemannDual) = Dual(x)

# the relative perturbation
realpart(r::RiemannDual) = r.realpart
epsilon(r::RiemannDual) = r.epsilon
undirected(r::RiemannDual) = undirected(realpart(r))
isinf(r::RiemannDual) = isinf(realpart(r))

in(x::RiemannDual, d::Domain) = realpart(x) ∈ d
in(x::RiemannDual, d::TypedEndpointsInterval{:closed,:closed}) = realpart(x) ∈ d

for f in (:-,)
    @eval $f(x::RiemannDual) = RiemannDual($f(realpart(x)),$f(epsilon(x)))
end

for f in (:sqrt,)
    @eval $f(x::RiemannDual) = RiemannDual($f(dual(x)))
end

for f in (:+, :-, :*)
    @eval $f(x::RiemannDual, y::RiemannDual) = RiemannDual($f(dual(x),dual(y)))
    for Typ in (:Bool, :Number)
        @eval begin
            $f(x::RiemannDual, p::$Typ) = RiemannDual($f(dual(x),p))
            $f(p::$Typ, x::RiemannDual) = RiemannDual($f(p,dual(x)))
        end
    end
end

for OP in (:*, :+, :-, :/)
    @eval begin
        $OP(a::Directed{s}, b::RiemannDual) where {s} = Directed{s}($OP(a.x,b))
        $OP(a::RiemannDual, b::Directed{s}) where {s} = Directed{s}($OP(a,b.x))
    end
end

function inv(z::RiemannDual)
    realpart(z) == 0 && return RiemannDual(Inf, inv(epsilon(z)))
    RiemannDual(inv(dual(z)))
end

/(z::RiemannDual, x::RiemannDual) = z*inv(x)
/(z::RiemannDual, x::Number) = z*inv(x)
/(x::Number, z::RiemannDual) = x*inv(z)


# loses sign information
for f in (:real, :imag, :abs)
    @eval $f(z::RiemannDual) = $f(realpart(z))
end

function log(z::RiemannDual)
    @assert realpart(z) == 0 || isinf(realpart(z))
    LogNumber(realpart(z) == 0 ? 1 : -1, log(abs(epsilon(z))) + im*angle(epsilon(z)))
end

function atanh(z::RiemannDual)
    if realpart(z) ≈ 1
        LogNumber(-0.5,log(2)/2  - log(abs(epsilon(z)))/2 - im/2*angle(-epsilon(z)))
    elseif realpart(z) ≈ -1
        LogNumber(0.5,-log(2)/2  + log(abs(epsilon(z)))/2 + im/2*angle(epsilon(z)))
    else
        error("Not implemented")
    end
end





log1p(z::RiemannDual) = log(z+1)

SingularIntegralEquations.HypergeometricFunctions.speciallog(x::RiemannDual) =
    (s = sqrt(x); 3(atanh(s)-realpart(s))/realpart(s)^3)


Base.show(io::IO, x::RiemannDual) = show(io, Dual(x))
Base.show(io::IO, x::LogNumber) = print(io, "($(logpart(x)))log ε + $(finitepart(x))")

# # (s*log(M) + c)*(p*M
# function /(l::LogNumber, b::RiemannDual)
#     @assert isinf(realpart(b))
#     LogNumber(l.s/b, l.c/b)
