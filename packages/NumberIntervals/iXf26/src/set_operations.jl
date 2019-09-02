
import IntervalArithmetic: ∩, ∪, entireinterval

export ∩, ∪, entireinterval

for f in (:∩, :∪)
    @eval $f(a::NumberInterval, b::NumberInterval) =
        NumberInterval($f(Interval(a), Interval(b)))
end

for f in (:entireinterval, )
    @eval $f(a::NumberInterval) = NumberInterval($f(Interval(a)))
end
