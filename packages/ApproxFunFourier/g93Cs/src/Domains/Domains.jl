
###### Periodic domains

abstract type PeriodicDomain{T} <: Domain{T} end

isperiodic(::PeriodicDomain) = true

canonicaldomain(::PeriodicDomain) = PeriodicSegment()


points(d::PeriodicDomain{T},n::Integer) where {T} =
    fromcanonical.(Ref(d), fourierpoints(real(eltype(T)),n))

fourierpoints(n::Integer) = fourierpoints(Float64,n)
fourierpoints(::Type{T},n::Integer) where {T<:Number} = convert(T,π)*collect(0:2:2n-2)/n

function indomain(x, d::PeriodicDomain{T}) where T
    y=tocanonical(d,x)
    if !isapprox(fromcanonical(d,y),x)
        return false
    end

    l=arclength(d)
    if isinf(l)
        abs(imag(y))<20eps(T)
    else
        abs(imag(y))/l<20eps(T)
    end
end




first(d::PeriodicDomain) = fromcanonical(d,0)
last(d::PeriodicDomain) = fromcanonical(d,2π)


rand(d::PeriodicDomain,k...) = fromcanonical.(Ref(d),2π*rand(k...)-π)
checkpoints(d::PeriodicDomain) = fromcanonical.(Ref(d),[1.223972,3.14,5.83273484])
boundary(d::PeriodicDomain) = EmptyDomain()

for op in (:rdirichlet,:ldirichlet,:lneumann,:rneumann,:ivp,:bvp)
    @eval $op(::PeriodicDomain) = error("Periodic domains do not have boundaries")
end


struct AnyPeriodicDomain <: PeriodicDomain{UnsetNumber} end
isambiguous(::AnyPeriodicDomain)=true

convert(::Type{D},::AnyDomain) where {D<:PeriodicDomain} = AnyPeriodicDomain()


include("PeriodicSegment.jl")
include("Circle.jl")
include("PeriodicLine.jl")
include("PeriodicCurve.jl")
include("Disk.jl")
