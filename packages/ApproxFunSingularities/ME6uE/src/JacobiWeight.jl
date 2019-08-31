


export JacobiWeight, WeightedJacobi



"""
    JacobiWeight(β,α,s::Space)

weights a space `s` by a Jacobi weight, which on `-1..1`
is `(1+x)^β*(1-x)^α`.
For other domains, the weight is inferred by mapping to `-1..1`.
"""
struct JacobiWeight{S,DD,RR,T<:Real} <: WeightSpace{S,DD,RR}
    β::T
    α::T
    space::S
    function JacobiWeight{S,DD,RR,T}(β::T,α::T,space::S) where {S<:Space,DD,RR,T}
        if isa(space,JacobiWeight)
            new(β+space.β,α+space.α,space.space) else
            new(β,α,space)
        end
    end
end

const WeightedJacobi{D,R} = JacobiWeight{Jacobi{D,R},D,R,R}

JacobiWeight{S,DD,RR,T}(β,α,space::Space) where {S,DD,RR,T} =
    JacobiWeight{S,DD,RR,T}(convert(T,β)::T, convert(T,α)::T, convert(S,space)::S)

JacobiWeight(a::Number, b::Number, d::Space) =
    JacobiWeight{typeof(d),domaintype(d),rangetype(d),promote_type(eltype(a),eltype(b))}(a,b,d)
JacobiWeight(β::Number, α::Number, d::JacobiWeight) =  JacobiWeight(β+d.β,α+d.α,d.space)
JacobiWeight(a::Number, b::Number, d::IntervalOrSegment) = JacobiWeight(a,b,Space(d))
JacobiWeight(a::Number, b::Number, d) = JacobiWeight(a,b,Space(d))
JacobiWeight(a::Number, b::Number) = JacobiWeight(a,b,Chebyshev())

JacobiWeight(a::Number, b::Number,s::PiecewiseSpace) = PiecewiseSpace(JacobiWeight(a,b,components(s)))

WeightedJacobi(β,α,d::Domain) = JacobiWeight(β,α,Jacobi(β,α,d))
WeightedJacobi(β,α) = JacobiWeight(β,α,Jacobi(β,α))


Fun(::typeof(identity), S::JacobiWeight) =
    isapproxinteger(S.β) && isapproxinteger(S.α) ? Fun(x->x,S) : Fun(identity,domain(S))

order(S::JacobiWeight{Ultraspherical{Int,D,R},D,R}) where {D,R} = order(S.space)


spacescompatible(A::JacobiWeight,B::JacobiWeight) =
    A.β ≈ B.β && A.α ≈ B.α && spacescompatible(A.space,B.space)
spacescompatible(A::JacobiWeight,B::Space{DD,RR}) where {DD<:IntervalOrSegment,RR<:Real} =
    spacescompatible(A,JacobiWeight(0,0,B))
spacescompatible(B::Space{DD,RR},A::JacobiWeight) where {DD<:IntervalOrSegment,RR<:Real} =
    spacescompatible(A,JacobiWeight(0,0,B))

transformtimes(f::Fun{JW1},g::Fun{JW2}) where {JW1<:JacobiWeight,JW2<:JacobiWeight}=
            Fun(JacobiWeight(f.space.β+g.space.β,f.space.α+g.space.α,f.space.space),
                coefficients(transformtimes(Fun(f.space.space,f.coefficients),
                                            Fun(g.space.space,g.coefficients))))
transformtimes(f::Fun{JW},g::Fun) where {JW<:JacobiWeight} =
    Fun(f.space,coefficients(transformtimes(Fun(f.space.space,f.coefficients),g)))
transformtimes(f::Fun,g::Fun{JW}) where {JW<:JacobiWeight} =
    Fun(g.space,coefficients(transformtimes(Fun(g.space.space,g.coefficients),f)))

jacobiweight(β,α,x) = -1 ≤ x ≤ 1 ? (1+x)^β*(1-x)^α : zero(x)
jacobiweight(β,α,d::Domain) = Fun(JacobiWeight(β,α,ConstantSpace(d)),[1.])
jacobiweight(β,α) = jacobiweight(β,α,ChebyshevInterval())

weight(sp::JacobiWeight,x) = jacobiweight(sp.β,sp.α,real(tocanonical(sp,x)))
dimension(sp::JacobiWeight) = dimension(sp.space)


Base.first(f::Fun{JW}) where {JW<:JacobiWeight} = space(f).β>0 ? zero(cfstype(f)) : f(leftendpoint(domain(f)))
Base.last(f::Fun{JW}) where {JW<:JacobiWeight} = space(f).α>0 ? zero(cfstype(f)) : f(rightendpoint(domain(f)))

setdomain(sp::JacobiWeight,d::Domain)=JacobiWeight(sp.β,sp.α,setdomain(sp.space,d))

# we assume that points avoids singularities


##TODO: paradigm for same space
function coefficients(f::AbstractVector,sp1::JacobiWeight{SJ1,DD},sp2::JacobiWeight{SJ2,DD}) where {SJ1,SJ2,DD<:IntervalOrSegment}
    β,α=sp1.β,sp1.α
    c,d=sp2.β,sp2.α

    if isapprox(c,β) && isapprox(d,α)
        # remove wrapper spaces and then convert
        coefficients(f,sp1.space,sp2.space)
    else
        # go back to default
        defaultcoefficients(f,sp1,sp2)
    end
end
coefficients(f::AbstractVector,sp::JacobiWeight{SJ,DD},
             S2::SubSpace{S,IT,DD,RR}) where {SJ,S,IT,DD<:IntervalOrSegment,RR<:Real} = subspace_coefficients(f,sp,S2)
coefficients(f::AbstractVector,S2::SubSpace{S,IT,DD,RR},
             sp::JacobiWeight{SJ,DD}) where {SJ,S,IT,DD<:IntervalOrSegment,RR<:Real} = subspace_coefficients(f,S2,sp)
#TODO: it could be possible that we want to JacobiWeight a SumSpace....
coefficients(f::AbstractVector,sp::JacobiWeight{SJ,DD},S2::SumSpace{SV,DD,RR}) where {SJ,SV,DD<:IntervalOrSegment,RR<:Real} =
    sumspacecoefficients(f,sp,S2)
coefficients(f::AbstractVector,sp::JacobiWeight{SJ,Segment{Vec{2,TT}}},S2::TensorSpace{SV,TTT,DD}) where {SJ,TT,SV,TTT,DD<:EuclideanDomain{2}} =
    coefficients(f,sp,JacobiWeight(0,0,S2))

coefficients(f::AbstractVector,sp::JacobiWeight{SJ,DD},S2::Space{DD,RR}) where {SJ,DD<:IntervalOrSegment,RR<:Real} =
    coefficients(f,sp,JacobiWeight(0,0,S2))
coefficients(f::AbstractVector,sp::ConstantSpace{DD},ts::JacobiWeight{SJ,DD}) where {SJ,DD<:IntervalOrSegment} =
    f.coefficients[1]*ones(ts).coefficients
coefficients(f::AbstractVector,S2::Space{DD,RR},sp::JacobiWeight{SJ,DD}) where {SJ,DD<:IntervalOrSegment,RR<:Real} =
    coefficients(f,JacobiWeight(0,0,S2),sp)


"""
`increase_jacobi_parameter(f)` multiplies by `1-x^2` on the unit interval.
`increase_jacobi_parameter(-1,f)` multiplies by `1+x` on the unit interval.
`increase_jacobi_parameter(+1,f)` multiplies by `1-x` on the unit interval.
On other domains this is accomplished by mapping to the unit interval.
"""
increase_jacobi_parameter(f) = Fun(f,JacobiWeight(f.space.β+1,f.space.α+1,space(f).space))
increase_jacobi_parameter(s,f) = s==-1 ? Fun(f,JacobiWeight(f.space.β+1,f.space.α,space(f).space)) :
                                       Fun(f,JacobiWeight(f.space.β,f.space.α+1,space(f).space))



function canonicalspace(S::JacobiWeight)
    if isapprox(S.β,0) && isapprox(S.α,0)
        canonicalspace(S.space)
    else
        #TODO: promote singularities?
        JacobiWeight(S.β,S.α,canonicalspace(S.space))
    end
end

function union_rule(A::ConstantSpace,B::JacobiWeight{P}) where P<:PolynomialSpace
    # we can convert to a space that contains contants provided
    # that the parameters are integers
    # when the parameters are -1 we keep them
    if isapproxinteger(B.β) && isapproxinteger(B.α)
        JacobiWeight(min(B.β,0.),min(B.α,0.),B.space)
    else
        NoSpace()
    end
end


## Algebra

function /(c::Number,f::Fun{JW}) where JW<:JacobiWeight
    g=c/Fun(space(f).space,f.coefficients)
    Fun(JacobiWeight(-f.space.β,-f.space.α,space(g)),g.coefficients)
end

function ^(f::Fun{JW}, k::AbstractFloat) where JW<:JacobiWeight
    S=space(f)
    g=Fun(S.space,coefficients(f))^k
    Fun(JacobiWeight(k*S.β,k*S.α,space(g)),coefficients(g))
end

function *(f::Fun{JW1},g::Fun{JW2}) where {JW1<:JacobiWeight,JW2<:JacobiWeight}
    @assert domainscompatible(f,g)
    fβ,fα=f.space.β,f.space.α
    gβ,gα=g.space.β,g.space.α
    m=(Fun(space(f).space,f.coefficients).*Fun(space(g).space,g.coefficients))
    if isapprox(fβ+gβ,0)&&isapprox(fα+gα,0)
        m
    else
        Fun(JacobiWeight(fβ+gβ,fα+gα,space(m)),m.coefficients)
    end
end


/(f::Fun{JW1},g::Fun{JW2}) where {JW1<:JacobiWeight,JW2<:JacobiWeight}=f*(1/g)

# O(min(m,n)) Ultraspherical conjugated inner product

function conjugatedinnerproduct(sp::Ultraspherical,u::AbstractVector{S},v::AbstractVector{V}) where {S,V}
    λ=order(sp)
    if λ==1
        mn = min(length(u),length(v))
        if mn > 0
            return dotu(u[1:mn],v[1:mn])*π/2
        else
            return zero(promote_type(eltype(u),eltype(v)))
        end
    else
        T,mn = promote_type(S,V),min(length(u),length(v))
        if mn > 1
            wi = sqrt(convert(T,π))*gamma(λ+one(T)/2)/gamma(λ+one(T))
            ret = u[1]*wi*v[1]
            for i=2:mn
              wi *= (i-2one(T)+2λ)/(i-one(T)+λ)*(i-2one(T)+λ)/(i-one(T))
              ret += u[i]*wi*v[i]
            end
            return ret
        elseif mn > 0
            wi = sqrt(convert(T,π))*gamma(λ+one(T)/2)/gamma(λ+one(T))
            return u[1]*wi*v[1]
        else
            return zero(promote_type(eltype(u),eltype(v)))
        end
    end
end

function conjugatedinnerproduct(::Chebyshev,u::AbstractVector,v::AbstractVector)
    mn = min(length(u),length(v))
    if mn > 1
        return (2u[1]*v[1]+dotu(u[2:mn],v[2:mn]))*π/2
    elseif mn > 0
        return u[1]*v[1]*π
    else
        return zero(promote_type(eltype(u),eltype(v)))
    end
end


function bilinearform(f::Fun{JacobiWeight{Ultraspherical{LT,D,R},D,R,TT}},g::Fun{Ultraspherical{LT,D,R}}) where {LT,D,R,TT}
    d = domain(f)
    @assert d == domain(g)
    λ = order(space(f).space)
    if order(space(g)) == λ && f.space.β == f.space.α == λ-0.5
        return complexlength(d)/2*conjugatedinnerproduct(Ultraspherical(λ,d),f.coefficients,g.coefficients)
    else
        return defaultbilinearform(f,g)
    end
end

function bilinearform(f::Fun{Ultraspherical{LT,D,R}},
                    g::Fun{JacobiWeight{Ultraspherical{LT,D,R},D,R,TT}}) where {LT,D,R,TT}
    d = domain(f)
    @assert d == domain(g)
    λ = order(space(f))
    if order(space(g).space) == λ && g.space.β == g.space.α == λ-0.5
        return complexlength(d)/2*conjugatedinnerproduct(Ultraspherical(λ,d),f.coefficients,g.coefficients)
    else
        return defaultbilinearform(f,g)
    end
end

function bilinearform(f::Fun{JacobiWeight{Ultraspherical{LT,D,R},D,R,TT1}},
                    g::Fun{JacobiWeight{Ultraspherical{LT,D,R},D,R,TT2}}) where {LT,D,R,TT1,TT2}
    d = domain(f)
    @assert d == domain(g)
    λ = order(space(f).space)
    if order(space(g).space) == λ && f.space.β+g.space.β == f.space.α+g.space.α == λ-0.5
        return complexlength(domain(f))/2*conjugatedinnerproduct(Ultraspherical(λ,d),f.coefficients,g.coefficients)
    else
        return defaultbilinearform(f,g)
    end
end

function linebilinearform(f::Fun{JacobiWeight{Ultraspherical{LT,D,R},D,R,TT}},g::Fun{Ultraspherical{LT,D,R}}) where {LT,D,R,TT}
    d = domain(f)
    @assert d == domain(g)
    λ = order(space(f).space)
    if order(space(g)) == λ && f.space.β == f.space.α == λ-0.5
        return arclength(d)/2*conjugatedinnerproduct(Ultraspherical(λ,d),f.coefficients,g.coefficients)
    else
        return defaultlinebilinearform(f,g)
    end
end

function linebilinearform(f::Fun{Ultraspherical{LT,D,R}},g::Fun{JacobiWeight{Ultraspherical{LT,D,R},D,R,TT}}) where {LT,D,R,TT}
    d = domain(f)
    @assert d == domain(g)
    λ = order(space(f))
    if order(space(g).space) == λ &&  g.space.β == g.space.α == λ-0.5
        return arclength(d)/2*conjugatedinnerproduct(Ultraspherical(λ,d),f.coefficients,g.coefficients)
    else
        return defaultlinebilinearform(f,g)
    end
end

function linebilinearform(f::Fun{JacobiWeight{Ultraspherical{LT,D,R},D,R,TT1}},g::Fun{JacobiWeight{Ultraspherical{LT,D,R},D,R,TT2}}) where {LT,D,R,TT1,TT2}
    d = domain(f)
    @assert d == domain(g)
    λ = order(space(f).space)
    if order(space(g).space) == λ &&  f.space.β+g.space.β == f.space.α+g.space.α == λ-0.5
        return arclength(d)/2*conjugatedinnerproduct(Ultraspherical(λ,d),f.coefficients,g.coefficients)
    else
        return defaultlinebilinearform(f,g)
    end
end


function bilinearform(f::Fun{JacobiWeight{J,DD,RR,TT}},g::Fun{J}) where {J<:Jacobi,DD<:IntervalOrSegment,RR,TT}
    @assert domain(f) == domain(g)
    if f.space.β == f.space.space.a == g.space.a && f.space.α == f.space.space.b == g.space.b
        return complexlength(domain(f))/2*conjugatedinnerproduct(g.space,f.coefficients,g.coefficients)
    else
        return defaultbilinearform(f,g)
    end
end

function bilinearform(f::Fun{J},
                      g::Fun{JacobiWeight{J,DD,RR,TT}}) where {J<:Jacobi,DD<:IntervalOrSegment,RR,TT}
    @assert domain(f) == domain(g)
    if g.space.β == g.space.space.a == f.space.a && g.space.α == g.space.space.b == f.space.b
        return complexlength(domain(f))/2*conjugatedinnerproduct(f.space,f.coefficients,g.coefficients)
    else
        return defaultbilinearform(f,g)
    end
end

function bilinearform(f::Fun{JacobiWeight{J,DD,RR,TT}},
                      g::Fun{JacobiWeight{J,DD,RR,TT}}) where {J<:Jacobi,DD<:IntervalOrSegment,RR,TT}
    @assert domain(f) == domain(g)
    if f.space.β + g.space.β == f.space.space.a == g.space.space.a && f.space.α + g.space.α == f.space.space.b == g.space.space.b
        return complexlength(domain(f))/2*conjugatedinnerproduct(f.space.space,f.coefficients,g.coefficients)
    else
        return defaultbilinearform(f,g)
    end
end


function linebilinearform(f::Fun{JacobiWeight{J,DD,RR,TT}},g::Fun{J}) where {J<:Jacobi,DD<:IntervalOrSegment,RR,TT}
    @assert domain(f) == domain(g)
    if f.space.β == f.space.space.a == g.space.a && f.space.α == f.space.space.b == g.space.b
        return arclength(domain(f))/2*conjugatedinnerproduct(g.space,f.coefficients,g.coefficients)
    else
        return defaultlinebilinearform(f,g)
    end
end

function linebilinearform(f::Fun{J},g::Fun{JacobiWeight{J,DD,RR,TT}}) where {J<:Jacobi,DD<:IntervalOrSegment,RR,TT}
    @assert domain(f) == domain(g)
    if g.space.β == g.space.space.a == f.space.a && g.space.α == g.space.space.b == f.space.b
        return arclength(domain(f))/2*conjugatedinnerproduct(f.space,f.coefficients,g.coefficients)
    else
        return defaultlinebilinearform(f,g)
    end
end

function linebilinearform(f::Fun{JacobiWeight{J,DD,RR,TT}}, g::Fun{JacobiWeight{J,DD,RR,TT}}) where {J<:Jacobi,DD<:IntervalOrSegment,RR,TT}
    @assert domain(f) == domain(g)
    if f.space.β + g.space.β == f.space.space.a == g.space.space.a && f.space.α + g.space.α == f.space.space.b == g.space.space.b
        return arclength(domain(f))/2*conjugatedinnerproduct(f.space.space,f.coefficients,g.coefficients)
    else
        return defaultlinebilinearform(f,g)
    end
end


function Derivative(S::WeightedJacobi{DDD,RR}) where {DDD<:IntervalOrSegment,RR}
    if S.β>0 && S.β>0 && S.β==S.space.b && S.α==S.space.a
        ConcreteDerivative(S,1)
    else
        jacobiweightDerivative(S)
    end
end

bandwidths(D::ConcreteDerivative{WeightedJacobi{DDD,RR}}) where {DDD<:IntervalOrSegment,RR} = 1,0
rangespace(D::ConcreteDerivative{WeightedJacobi{DDD,RR}}) where {DDD<:IntervalOrSegment,RR} =
    WeightedJacobi(domainspace(D).β-1,domainspace(D).α-1,domain(D))

getindex(D::ConcreteDerivative{WeightedJacobi{DDD,RR}},k::Integer,j::Integer) where {DDD<:IntervalOrSegment,RR} =
    j==k-1 ? eltype(D)(-4(k-1)./complexlength(domain(D))) : zero(eltype(D))




for (Func,Len,Sum) in ((:DefiniteIntegral,:complexlength,:sum),(:DefiniteLineIntegral,:arclength,:linesum))
    ConcFunc = Meta.parse("Concrete"*string(Func))

    @eval begin
        function getindex(Σ::$ConcFunc{JacobiWeight{Jacobi{D,R},D,R,TT},T},k::Integer) where {D<:IntervalOrSegment,R,T,TT}
            dsp = domainspace(Σ)

            if dsp.β == dsp.space.b && dsp.α == dsp.space.a
                # TODO: copy and paste
                k == 1 ? convert(T,$Sum(Fun(dsp,[one(T)]))) : zero(T)
            else
                convert(T,$Sum(Fun(dsp,[zeros(T,k-1);1])))
            end
        end

        function bandwidths(Σ::$ConcFunc{JacobiWeight{Jacobi{D,R},D,R,TT}}) where {D<:IntervalOrSegment,R,TT}
            β,α = domainspace(Σ).β,domainspace(Σ).α
            if domainspace(Σ).β == domainspace(Σ).space.b && domainspace(Σ).α == domainspace(Σ).space.a
                0,0  # first entry
            else
                0,∞
            end
        end
    end
end


## <: IntervalOrSegment avoids a julia bug
function Multiplication(f::Fun{JacobiWeight{C,DD,RR,TT}}, S::Jacobi) where {C<:ConstantSpace,DD<:IntervalOrSegmentDomain,RR,TT}
    # this implements (1+x)*P and (1-x)*P special case
    # see DLMF (18.9.6)
    d=domain(f)
    if ((space(f).β==1 && space(f).α==0 && S.b >0) ||
                        (space(f).β==0 && space(f).α==1 && S.a >0))
        ConcreteMultiplication(f,S)
    elseif isapproxinteger(space(f).β) && space(f).β ≥ 1 && S.b >0
        # decrement β and multiply again
        M=Multiplication(f.coefficients[1]*jacobiweight(1.,0.,d),S)
        MultiplicationWrapper(f,Multiplication(jacobiweight(space(f).β-1,space(f).α,d),rangespace(M))*M)
    elseif isapproxinteger(space(f).α) && space(f).α ≥ 1 && S.a >0
        # decrement α and multiply again
        M=Multiplication(f.coefficients[1]*jacobiweight(0.,1.,d),S)
        MultiplicationWrapper(f,Multiplication(jacobiweight(space(f).β,space(f).α-1,d),rangespace(M))*M)
    else
# default JacobiWeight
        M=Multiplication(Fun(space(f).space,f.coefficients),S)
        rsp=JacobiWeight(space(f).β,space(f).α,rangespace(M))
        MultiplicationWrapper(f,SpaceOperator(M,S,rsp))
    end
end

Multiplication(f::Fun{JacobiWeight{C,DD,RR,TT}},
               S::Union{Ultraspherical,Chebyshev}) where {C<:ConstantSpace,DD<:IntervalOrSegmentDomain,RR,TT} =
    MultiplicationWrapper(f,Multiplication(f,Jacobi(S))*Conversion(S,Jacobi(S)))

function rangespace(M::ConcreteMultiplication{JacobiWeight{C,DD,RR,TT},J}) where {J<:Jacobi,C<:ConstantSpace,DD<:IntervalOrSegmentDomain,RR,TT}
    S=domainspace(M)
    if space(M.f).β==1
        # multiply by (1+x)
        Jacobi(S.b-1,S.a,domain(S))
    elseif space(M.f).α == 1
        # multiply by (1-x)
        Jacobi(S.b,S.a-1,domain(S))
    else
        error("Not implemented")
    end
end

bandwidths(::ConcreteMultiplication{JacobiWeight{C,DD,RR,TT},J}) where {J<:Jacobi,C<:ConstantSpace,DD<:IntervalOrSegmentDomain,RR,TT} = 1,0


function getindex(M::ConcreteMultiplication{JacobiWeight{C,DD,RR,TT},J},k::Integer,j::Integer) where {J<:Jacobi,C<:ConstantSpace,DD<:IntervalOrSegmentDomain,RR,TT}
    @assert ncoefficients(M.f)==1
    a,b=domainspace(M).a,domainspace(M).b
    c=M.f.coefficients[1]
    if space(M.f).β==1
        @assert space(M.f).α==0
        # multiply by (1+x)
        if j==k
            c*2(k+b-1)/(2k+a+b-1)
        elseif k > 1 && j==k-1
            c*(2k-2)/(2k+a+b-3)
        else
            zero(eltype(M))
        end
    elseif space(M.f).α == 1
        @assert space(M.f).β==0
        # multiply by (1-x)
        if j==k
            c*2(k+a-1)/(2k+a+b-1)
        elseif k > 1 && j==k-1
            -c*(2k-2)/(2k+a+b-3)
        else
            zero(eltype(M))
        end
    else
        error("Not implemented")
    end
end


# We can exploit the special multiplication to construct a Conversion


for FUNC in (:maxspace_rule,:union_rule,:hasconversion)
    @eval function $FUNC(A::WeightedJacobi{DD},B::Jacobi) where DD<:IntervalOrSegment
        if A.β==A.α+1 && A.space.b>0
            $FUNC(Jacobi(A.space.b-1,A.space.a,domain(A)),B)
        elseif A.α==A.β+1 && A.space.a>0
            $FUNC(Jacobi(A.space.b,A.space.a-1,domain(A)),B)
        else
            $FUNC(A,JacobiWeight(0.,0.,B))
        end
    end
end
