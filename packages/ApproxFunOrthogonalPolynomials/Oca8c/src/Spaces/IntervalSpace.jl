export continuity



Space(d::IntervalOrSegment) = Chebyshev(d)
Space(d::FullSpace{<:Real}) = Chebyshev(Line())

Fun(::typeof(identity), d::IntervalOrSegment{T}) where {T<:Number} =
    Fun(Chebyshev(d), [mean(d), complexlength(d)/2])


## Calculus



# the default domain space is higher to avoid negative ultraspherical spaces
Integral(d::IntervalOrSegment,n::Integer) = Integral(Ultraspherical(1,d),n)

