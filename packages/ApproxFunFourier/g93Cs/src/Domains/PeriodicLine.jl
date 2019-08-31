

export Line, PeriodicLine






## Periodic line

# angle is (false==0) and π (true==1)
# or ranges from (-1,1]
struct PeriodicLine{angle,T} <: PeriodicDomain{T}
    center::T
    L::Float64
    PeriodicLine{angle,T}(c,L) where {angle,T} = new{angle,T}(c,L)
    PeriodicLine{angle,T}(c) where {angle,T} = new{angle,T}(c,1.)
    PeriodicLine{angle,T}(d::PeriodicLine) where {angle,T} = new{angle,T}(d.center,d.L)
    PeriodicLine{angle,T}() where {angle,T} = new{angle,T}(0.,1.)
end

(::Type{PeriodicLine{a}})(c,L) where {a} = PeriodicLine{a,typeof(c)}(c,L)


PeriodicLine(c,a) = PeriodicLine{a/π,eltype(c)}(c,1.)
PeriodicLine() = PeriodicLine{false,Float64}(0.,1.)
PeriodicLine(b::Bool) = PeriodicLine{b,Float64}()

isambiguous(d::PeriodicLine) = isnan(d.center) && isnan(d.angle)
convert(::Type{Domain{T}},d::PeriodicLine{a}) where {a,T<:Number} = PeriodicLine{a,T}(d.center, d.L)
convert(::Type{PeriodicLine{T,TT}},::AnyDomain) where {T<:Number,TT} = PeriodicLine{T,TT}(NaN,NaN)
convert(::Type{IT},::AnyDomain) where {IT<:PeriodicLine} = PeriodicLine(NaN,NaN)

angle(d::PeriodicLine{a}) where {a}=a*π

reverseorientation(d::PeriodicLine{true})=PeriodicLine{false}(d.center,d.L)
reverseorientation(d::PeriodicLine{false})=PeriodicLine{true}(d.center,d.L)
reverseorientation(d::PeriodicLine{a}) where {a}=PeriodicLine{a-1}(d.center,d.L)

tocanonical(d::PeriodicLine{false},x) = real(2atan((x-d.center)/d.L))
fromcanonical(d::PeriodicLine{false},θ) = d.L*tan(θ/2) + d.center

tocanonical(d::PeriodicLine{a},x) where {a} = tocanonical(PeriodicLine{false,Float64}(0.,d.L),exp(-π*im*a)*(x-d.center))
fromcanonical(d::PeriodicLine{a},v::AbstractArray) where {a} =
    [fromcanonical(d,vk) for vk in v]
fromcanonical(d::PeriodicLine{a},x) where {a} =
    exp(π*im*a)*fromcanonical(PeriodicLine{false,Float64}(0.,d.L),x)+d.center


function invfromcanonicalD(d::PeriodicLine{false})
    @assert d.center==0  && d.L==1.0
    a=Fun(PeriodicSegment(),[1.,0,1])
end

mappoint(a::PeriodicLine{false},b::Circle,x) = b.radius*((a.L*im-(x-a.center))./(a.L*im+(x-a.center)))+b.center
function mappoint(b::Circle,a::PeriodicLine{false},x)
    y=(x-b.center)./b.radius
    a.center+a.L*im*(1-y)./(y+1)
end


# algebra
*(c::Number,d::PeriodicLine)=PeriodicLine(isapprox(d.center,0) ? d.center : c*d.center,angle(d)+angle(c))
*(d::PeriodicLine,c::Number)=c*d
for OP in (:+,:-)
    @eval begin
        $OP(c::Number,d::PeriodicLine{a,T}) where {a,T}=PeriodicLine{a,promote_type(eltype(c),T)}($OP(c,d.center),d.L)
        $OP(d::PeriodicLine{a,T},c::Number) where {a,T}=PeriodicLine{a,promote_type(eltype(c),T)}($OP(d.center,c),d.L)
    end
end


arclength(d::PeriodicLine) = Inf
leftendpoint(d::PeriodicLine)= -Inf
rightendpoint(d::PeriodicLine)= Inf
complexlength(d::PeriodicLine)=Inf

## vectorized

function convert(::Type{PeriodicLine},d::ClosedInterval)
    a,b=d.left,d.right
    @assert abs(a) == abs(b) == Inf

    if isa(a,Real) && isa(b,Real)
        if a==Inf
            @assert b==-Inf
            PeriodicLine(true)
        else
            @assert a==-Inf&&b==Inf
            PeriodicLine(false)
        end
    elseif abs(real(a)) < Inf
        @assert real(a)==real(b)
        @assert sign(imag(a))==-sign(imag(b))

        PeriodicLine(real(b),angle(b))
    elseif isnan(real(a)) && isnan(real(b))  # hack for -im*Inf
        PeriodicLine([imag(a)*im,imag(b)*im])
    elseif isnan(real(a))  # hack for -im*Inf
        PeriodicLine([real(b)+imag(a)*im,b])
    elseif isnan(real(b))  # hack for -im*Inf
        PeriodicLine([a,real(a)+imag(b)*im])
    elseif abs(imag(a)) < Inf
        @assert imag(a)==imag(b)
        @assert sign(real(a))==-sign(real(b))

        PeriodicLine(imag(b),angle(b))
    else
        @assert angle(b) == -angle(a)

        PeriodicLine(0.,angle(b))
    end
end
