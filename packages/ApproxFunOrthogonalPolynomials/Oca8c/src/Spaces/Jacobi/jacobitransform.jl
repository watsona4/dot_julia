
points(S::Jacobi, n) = points(Chebyshev(domain(S)), n)

struct JacobiTransformPlan{T,CPLAN,CJT} <: AbstractTransformPlan{T}
    chebplan::CPLAN
    cjtplan::CJT
end

JacobiTransformPlan(chebplan::CPLAN, cjtplan::CJT) where {CPLAN,CJT} =
    JacobiTransformPlan{eltype(chebplan),CPLAN,CJT}(chebplan, cjtplan)

plan_transform(S::Jacobi, v::AbstractVector) =
    JacobiTransformPlan(plan_transform(Chebyshev(), v), plan_icjt(v, S.a, S.b))
*(P::JacobiTransformPlan, vals::AbstractVector) = P.cjtplan*(P.chebplan*vals)


struct JacobiITransformPlan{T,CPLAN,CJT} <: AbstractTransformPlan{T}
    ichebplan::CPLAN
    icjtplan::CJT
end

JacobiITransformPlan(chebplan::CPLAN, cjtplan::CJT) where {CPLAN,CJT} =
    JacobiITransformPlan{eltype(chebplan),CPLAN,CJT}(chebplan, cjtplan)



plan_itransform(S::Jacobi, v::AbstractVector) =
    JacobiITransformPlan(plan_itransform(Chebyshev(), v), plan_cjt(v, S.a, S.b))
*(P::JacobiITransformPlan, cfs::AbstractVector) = P.ichebplan*(P.icjtplan*cfs)


function coefficients(f::AbstractVector,a::Jacobi,b::Chebyshev)
    if domain(a) == domain(b) && (!isapproxinteger(a.a-0.5) || !isapproxinteger(a.b-0.5))
        cjt(f,a.a,a.b)
    else
        defaultcoefficients(f,a,b)
    end
end
function coefficients(f::AbstractVector,a::Chebyshev,b::Jacobi)
    isempty(f) && return f
    if domain(a) == domain(b) && (!isapproxinteger(b.a-0.5) || !isapproxinteger(b.b-0.5))
        icjt(f,b.a,b.b)
    else
        defaultcoefficients(f,a,b)
    end
end

function coefficients(f::AbstractVector,a::Jacobi,b::Jacobi)
    if domain(a) == domain(b) && (!isapproxinteger(a.a-b.a) || !isapproxinteger(a.b-b.b))
        jjt(f,a.a,a.b,b.a,b.b)
    else
        defaultcoefficients(f,a,b)
    end
end
