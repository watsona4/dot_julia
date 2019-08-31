

export Line




## Standard interval



# angle is π*a where a is (false==0) and (true==1)
# or ranges from (-1,1].  We use 1 as 1==true.

"""
    Line{a}(c)

represents the line at angle `a` in the complex plane, centred at `c`.
"""
struct Line{angle,T<:Number} <: SegmentDomain{T}
    center::T
    α::Float64
    β::Float64

    #TODO get this inner constructor working again.
    Line{angle,T}(c,α,β) where {angle,T} = new{angle,T}(c,α,β)
    Line{angle,T}(c) where {angle,T} = new{angle,T}(c,-1.,-1.)
    Line{angle,T}() where {angle,T} = new{angle,T}(zero(T),-1.,-1.)
end

const RealLine{T} = Union{Line{false,T},Line{true,T}}

Line{a}(c,α,β) where {a} = Line{a,typeof(c)}(c,α,β)
Line{a}(c::Number) where {a} = Line{a,typeof(c)}(c)
Line{a}() where {a} = Line{a,Float64}()

angle(d::Line{a}) where {a} = a*π

reverseorientation(d::Line{true}) = Line{false}(d.center,d.β,d.α)
reverseorientation(d::Line{false}) = Line{true}(d.center,d.β,d.α)
reverseorientation(d::Line{a}) where {a} = Line{a-1}(d.center,d.β,d.α)

# ensure the angle is always in (-1,1]
Line(c,a,α,β) = Line{mod(a/π-1,-2)+1,typeof(c)}(c,α,β)
Line(c,a) = Line(c,a,-1.,-1.)
# true is negative orientation, false is positive orientation
# this is because false==0 and we take angle=0
Line(b::Bool) = Line{b}()
Line() = Line(false)


isambiguous(d::Line)=isnan(d.center)
convert(::Type{Domain{T}},d::Line{a}) where {a,T<:Number} = Line{a,T}(d.center, d.α, d.β)
convert(::Type{Line{a,T}},::AnyDomain) where {a,T<:Number} = Line{a,T}(NaN)
convert(::Type{IT},::AnyDomain) where {IT<:Line}=Line(NaN,NaN)

## Map interval


##TODO non-1 alpha,beta

isempty(::Line) = false

function line_tocanonical(α,β,x)
    @assert α==β==-1. || α==β==-.5

    if α==β==-1.
        2x/(1+sqrt(1+4x^2))
    elseif α==β==-.5
        x/sqrt(1 + x^2)
    end
end

function line_tocanonicalD(α,β,x)
    @assert α==β==-1. || α==β==-.5

    if α==β==-1.
        2/(1+4x^2+sqrt(1+4x^2))
    elseif α==β==-0.5
        (1 + x^2)^(-3/2)
    end
end
function line_fromcanonical(α,β,x)
    #TODO: why is this consistent?
    if α==β==-1.
        x/(1-x^2)
    else
        x*(1 + x)^α*(1 - x)^β
    end
end
function line_fromcanonicalD(α,β,x)
    if α==β==-1.
        (1+x^2)/(1-x^2)^2
    else
        (1 - (β-α)x - (β+α+1)x^2)*(1+x)^(α-1)*(1-x)^(β-1)
    end
end

function line_invfromcanonicalD(α,β,x)
    if α==β==-1.
        (1-x^2)^2/(1+x^2)
    else
        1/(1 - (β-α)x - (β+α+1)x^2)*(1+x)^(1-α)*(1-x)^(1-β)
    end
end


tocanonical(d::Line,x) = line_tocanonical(d.α,d.β,cis(-angle(d)).*(x-d.center))
tocanonical(d::Line{false},x) = line_tocanonical(d.α,d.β,x-d.center)
tocanonical(d::Line{true},x) = line_tocanonical(d.α,d.β,d.center-x)

tocanonicalD(d::Line,x) = cis(-angle(d)).*line_tocanonicalD(d.α,d.β,cis(-angle(d)).*(x-d.center))
tocanonicalD(d::Line{false},x) = line_tocanonicalD(d.α,d.β,x-d.center)
tocanonicalD(d::Line{true},x) = -line_tocanonicalD(d.α,d.β,d.center-x)

fromcanonical(d::Line,x) = cis(angle(d))*line_fromcanonical(d.α,d.β,x)+d.center
fromcanonical(d::Line{false},x) = line_fromcanonical(d.α,d.β,x)+d.center
fromcanonical(d::Line{true},x) = -line_fromcanonical(d.α,d.β,x)+d.center

fromcanonicalD(d::Line,x) = cis(angle(d))*line_fromcanonicalD(d.α,d.β,x)
fromcanonicalD(d::Line{false},x) = line_fromcanonicalD(d.α,d.β,x)
fromcanonicalD(d::Line{true},x) = -line_fromcanonicalD(d.α,d.β,x)

invfromcanonicalD(d::Line,x) = cis(-angle(d))*line_invfromcanonicalD(d.α,d.β,x)
invfromcanonicalD(d::Line{false},x) = line_invfromcanonicalD(d.α,d.β,x)
invfromcanonicalD(d::Line{true},x) = -line_invfromcanonicalD(d.α,d.β,x)






==(d::Line{a},m::Line{a}) where {a} = d.center == m.center && d.β == m.β &&d.α == m.α



# algebra
*(c::Real,d::Line{false}) = Line{sign(c)>0 ? false : true}(isapprox(d.center,0) ? d.center : c*d.center,d.α,d.β)
*(c::Real,d::Line{true}) = Line{sign(c)>0 ? true : false}(isapprox(d.center,0) ? d.center : c*d.center,d.α,d.β)
*(c::Number,d::Line) = Line(isapprox(d.center,0) ? d.center : c*d.center,angle(d)+angle(c),d.α,d.β)
*(d::Line,c::Number) = c*d
for OP in (:+,:-)
    @eval begin
        $OP(c::Number,d::Line{a}) where {a} = Line{a}($OP(c,d.center),d.α,d.β)
        $OP(d::Line{a},c::Number) where {a} = Line{a}($OP(d.center,c),d.α,d.β)
    end
end






# algebra
arclength(d::Line) = Inf
leftendpoint(d::Line) = -Inf
rightendpoint(d::Line) = Inf
complexlength(d::Line) =Inf

## vectorized


function convert(::Type{Line},d::ClosedInterval)
    a,b=d.left,d.right
    @assert abs(a) == abs(b) == Inf

    if isa(a,Real) && isa(b,Real)
        if a==Inf
            @assert b==-Inf
            Line(true)
        else
            @assert a==-Inf&&b==Inf
            Line(false)
        end
    elseif abs(real(a)) < Inf
        @assert real(a)==real(b)
        @assert sign(imag(a))==-sign(imag(b))

        Line(real(b),angle(b))
    elseif isnan(real(a)) && isnan(real(b))  # hack for -im*Inf
        Line([imag(a)*im,imag(b)*im])
    elseif isnan(real(a))  # hack for -im*Inf
        Line([real(b)+imag(a)*im,b])
    elseif isnan(real(b))  # hack for -im*Inf
        Line([a,real(a)+imag(b)*im])
    elseif abs(imag(a)) < Inf
        @assert imag(a)==imag(b)
        @assert sign(real(a))==-sign(real(b))

        Line(imag(b),angle(b))
    else
        @assert angle(b) == -angle(a)

        Line(0.,angle(b))
    end
end



issubset(a::IntervalOrSegment, b::Line) = leftendpoint(a)∈b && rightendpoint(a)∈b
issubset(a::Ray{angle}, b::Line{angle}) where angle = leftendpoint(a) ∈ b
issubset(a::Ray{true}, b::Line{false}) = true
issubset(a::Ray{false}, b::Line{true}) = true

function intersect(a::Union{Interval,Segment,Ray},b::Line)
    @assert a ⊆ b
    a
end

function union(a::Union{Interval,Segment,Ray},b::Line)
    @assert a ⊆ b
    b
end

intersect(b::Line,a::Union{Interval,Segment,Ray}) = intersect(a,b)
union(b::Line,a::Union{Interval,Segment,Ray}) = union(a,b)


function setdiff(b::Line,a::Segment)
    @assert a ⊆ b
    if leftendpoint(a)>rightendpoint(a)
        b\reverseorientation(a)
    else
        Ray([leftendpoint(b),leftendpoint(a)]) ∪ Ray([rightendpoint(a),rightendpoint(b)])
    end
end