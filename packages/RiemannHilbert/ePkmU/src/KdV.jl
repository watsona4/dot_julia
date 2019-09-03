module KdV
using ApproxFun, LinearAlgebra
export ReflectionCoefficient, tFun

struct ReflectionCoefficient{VM, VP} <: Function
    V₋::VM
    V₊::VP
    ReflectionCoefficient{VM, VP}(V₋::VM, V₊::VP) where {VM,VP} = new{VM,VP}(V₋, V₊)
end

function ReflectionCoefficient(V, a=-6.0, x₀=0.0, b=6.0)
    d₋, d₊ = a .. x₀ , x₀ .. b
    V₋,V₊ = Fun(V, d₋), Fun(V, d₊)
    ReflectionCoefficient{typeof(V₋),typeof(V₊)}(V₋,V₊)
end

# ψ'' + (V(x) + k^2) ψ = 0
function (R::ReflectionCoefficient)(k)
    k == 0 && return -one(ComplexF64)

    a,x₀ = endpoints(domain(R.V₋))
    b = rightendpoint(domain(R.V₊))
    D = Derivative()
    V₋,V₊ = R.V₋, R.V₊
    ψ = [ivp(); D^2  + (V₋ + k^2)] \ [exp(-im*k*a), -im*k*(exp(-im*k*a)), 0.0]

    F = qr([rdirichlet(space(V₊)); rneumann(); D^2  + (V₊ + k^2)])
    ϕ₊ = F \ [exp(im*k*b), im*k*(exp(im*k*b)), 0.0]
    ϕ₋ = F \ [exp(-im*k*b), -im*k*(exp(-im*k*b)), 0.0]

    a,b = [ϕ₋(x₀) ϕ₊(x₀);
           ϕ₋'(x₀) ϕ₊'(x₀) ] \ [ψ(x₀); ψ'(x₀)]
    b/a 
end

# use multiple threads since reflection coefficient is slow
function tvalues(f, d, n)
    p = points(d, n)
    F = similar(p, ComplexF64)
    Threads.@threads for k=1:length(p)
        F[k] = f(p[k])
    end
    F
end

tFun(f, d::Space, n) = Fun(d, transform(d,tvalues(f,d,n)))
tFun(f, d, n) = tFun(f, Space(d), n)

function quickinv(F)
    A = Array(F)
    V = values.(pad.(A, maximum(ncoefficients.(A))))
    Vi = [inv([V[k,j][p] for k=1:2, j=1:2]) for p=1:length(V[1,1])]
    Fun(Fun([Fun(sp,transform(sp,[Vi[p][k,j] for p=1:length(Vi)])) for k=1:2, j=1:2]), space(F))
end
end # module