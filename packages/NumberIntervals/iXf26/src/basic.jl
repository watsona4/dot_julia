
import Base: -, +, *, /, ^, abs, abs2, sqrt, exp, exp2, expm1, exp10, log, log2,
    log1p, log10, sin, sinpi, cos, cospi, tan, asin, acos, atan, sinh, cosh,
    asinh, acosh, tanh, atanh, inv, floor, ceil, min, max, round, trunc, eps
export -, +, *, /, ^, abs, abs2, sqrt, exp, exp2, expm1, exp10, log, log2,
    log1p, log10, sin, sinpi, cos, cospi, tan, asin, acos, atan, sinh, cosh,
    asinh, acosh, tanh, atanh, inv, floor, ceil, min, max, round, trunc, eps

for f in (:-, :abs, :abs2, :sqrt, :exp, :exp2, :expm1, :exp10, :log, :log2,
          :log1p, :log10, :sin, :sinpi, :cos, :cospi, :tan, :asin, :acos, :atan,
          :sinh, :cosh, :asinh, :acosh, :tanh, :atanh, :inv, :floor, :ceil,
          :round, :trunc, :eps)
    @eval $f(a::NumberInterval) = NumberInterval($f(Interval(a)))
end

for f in (:+, :-, :*, :/, :^, :atan, :min, :max)
    @eval $f(a::NumberInterval, b::NumberInterval) =
        NumberInterval($f(Interval(a), Interval(b)))
end

# specialization necessary to avoid ambiguity
for t in (:Integer, :AbstractFloat, :Rational)
    @eval ^(a::NumberInterval, n::$t) = NumberInterval(Interval(a)^n)
end

round(a::NumberInterval, mode) = NumberInterval(round(Interval(a), mode))

eps(::Type{NumberInterval{T}}) where T = NumberInterval(eps(Interval{T}))
