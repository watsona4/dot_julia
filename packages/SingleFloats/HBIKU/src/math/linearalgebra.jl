import LinearAlgebra: *, exp!, iszero, isone,
    isdiag, issymmetric, ishermitian,
    isposdef, isposdef!, istril, istriu,
    dot, norm, normalize,
    rank, cond, opnorm, norm, det, tr,
    transpose, adjoint, inv, pinv,
    lu, lu!, qr, qr!, schur, schur!,
    cholesky, cholesky!, hessenberg, hessenberg!, factorize,
    eigvals, eigvals!, svdvals, svdvals!, svd,
    sqrt, exp, log,
    sin, cos, tan, csc, sec, cot,
    asin, acos, atan, acsc, asec, acot,
    sinh, cosh, tanh, csch, sech, coth,
    asinh, acosh, atanh, acsch, asech, acoth


norm(a::Vector{Single32}) = reinterpret(Single32, norm(reinterpret(Float64, a)))

normalize(a::Vector{Single32}) = reinterpret(Single32, normalize(reinterpret(Float64, a)))

dot(a::Vector{Single32}, b::Vector{Single32}) =
    reinterpret(Single32, dot(reinterpret(Float64, a), reinterpret(Float64, b)))


(*)(a::Matrix{Single32}, b::Matrix{Single32}) =
    reinterpret(Single32, reinterpret(Float64,a) * reinterpret(Float64,b))

exp!(x::Array{Complex{Single32},2}) = Complex{Single32}.(LinearAlgebra.exp!(Complex{Float64}.(x)))

for Op in (:iszero, :isone, :isdiag, :issymmetric, :ishermitian,
           :isposdef, :isposdef!, :istril, :istriu)
    @eval $Op(x::Matrix{Single32}) = $Op(reinterpret(Float64,x))
end

for Op in (:rank, :cond, :opnorm)
    @eval $Op(x::Array{Single32,2}) =
        reinterpret(Single32, $Op(reinterpret(Float64,x)))
end

for Op in (:norm, :det, :tr)
    @eval $Op(x::Matrix{Single32}) =
        reinterpret(Single32, $Op(reinterpret(Float64,x)))
end

for Op in (:transpose, :adjoint, :inv, :pinv)
    @eval $Op(x::Matrix{Single32}) =
        reinterpret(Single32, ($Op(reinterpret(Float64,x))))
end

function LinearAlgebra.lu(x::Matrix{Single32})
    result = lu(reinterpret(Float64,x))
    return LinearAlgebra.LU{Single32,Array{Single32,2}}(result)
end

#=
function LinearAlgebra.qr(x::Matrix{Single32})
    result = qr(reinterpret(Float64,x))
    if typeof(result) <: LinearAlgebra.QRCompactWY
        LinearAlgebra.QRCompactWY{Single32,Array{Single32,2}}(result)
    else
        LinearAlgebra.QR{Single32,Array{Single32,2}}(result)
    end
end
=#

#=
for Op in (:lu, :lu!, :qr, :qr!, :schur, :schur!)
    @eval $Op(x::Array{Single32,2}) = Single32.($Op(Float64.(x)))
end

for Op in (:cholesky, :cholesky!, :hessenberg, :hessenberg!, :factorize)
    @eval $Op(x::Array{Single32,2}) = Single32.($Op(Float64.(x)))
end
=#

for Op in (:svdvals, :svdvals!)
    @eval $Op(x::Array{Single32,2}) = reinterpret(Single32,($Op(reinterpret(Float64,x))))
end


for Op in (:eigvals, :eigvals!)
    @eval $Op(x::Array{Single32,2}) = (Complex{Single32}).($Op(reinterpret(Float64,x)))
end

for Op in (:sqrt, :exp, :log,
           :sin, :cos, :tan, :csc, :sec, :cot,
           :asin, :acos, :atan, :acsc, :asec, :acot,
           :sinh, :cosh, :tanh, :csch, :sech, :coth,
           :asinh, :acosh, :atanh, :acsch, :asech, :acoth)
    @eval $Op(x::Array{Single32,2}) = Single32.($Op(Float64.(x)))
end
