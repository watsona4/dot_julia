
import IntervalArithmetic: radius, mid, mag, mig, sup, inf
export radius, mid, mag, mig, sup, inf

for f in (:radius, :mid, :mag, :mig, :sup, :inf)
    @eval $f(a::NumberInterval) = $f(Interval(a))
end
