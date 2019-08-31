export Disk,𝔻

# T is Real or Complex
# TT is (Real,Real) or Complex
"""
    Disk(c,r)

represents the disk centred at `c` with radius `r`.
"""
struct Disk{T} <: Domain{T}
    center::T
    radius::Float64
end

Disk(c,r) = Disk{typeof(c)}(c,r)
Disk(c::Real,r) = Disk(complex(c),r)
Disk(c::Integer,r) = Disk(float(c),r)
Disk(c::Complex{<:Integer},r) = Disk(float(c),r)

Disk() = Disk(Vec(0.,0.),1.)
Disk(::AnyDomain) = Disk(NaN,(NaN,NaN))

const 𝔻 = Disk()

isambiguous(d::Disk) = isnan(d.radius) && all(isnan,d.center)

polar(r,θ) = Vec(r*cos(θ),r*sin(θ))
ipolar(x,y) = Vec(sqrt(abs2(x)+abs2(y)), atan(y,x))
polar(rθ::Vec) = polar(rθ...)
ipolar(xy::Vec) = ipolar(xy...)

fromcanonical(D::Disk{T},xy::Vec) where {T<:Vec} = Vec((D.radius.*xy .+ D.center)...)
tocanonical(D::Disk{T},x,y) where {T<:Vec} = Vec((xy .- D.center)./D.radius)

checkpoints(d::Disk) = [fromcanonical(d,Vec(.1,.2243)),fromcanonical(d,Vec(-.212423,-.3))]

# function points(d::Disk,n,m,k)
#     ptsx=0.5*(1-gaussjacobi(n,1.,0.)[1])
#     ptst=points(PeriodicSegment(),m)
#
#     Float64[fromcanonical(d,x,t)[k] for x in ptsx, t in ptst]
# end


boundary(d::Disk) = Circle(d.center,d.radius)
