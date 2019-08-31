# https://github.com/FluxML/Flux.jl/pull/524

Base.prod(xs::TrackedArray; dims=:) = track(prod, xs; dims=dims)

@grad prod(xs; dims=:) = _prod(xs.data, prod(xs.data, dims=dims), dims)
_prod(xd, p, ::Colon) = p, Δ -> (nobacksies(:prod, ∇prod(xd, p, data(Δ)) ),)
_prod(xd, p, dims) = count(iszero, p) == 0 ?
  (p, Δ -> (nobacksies(:prod, p ./ xd .* data(Δ) ),)) :
  (p, Δ -> (nobacksies(:prod, mapslices(∇prod, xd; dims=dims) .* data(Δ)),))

function ∇prod(x, p=prod(x), Δ=1)
  numzero = count(iszero, x)
  if numzero == 0
    ∇ = p ./ x .* Δ
  elseif numzero > 1
    ∇ = zero(x)
  else
    ∇ = ∇prod_one(x, Δ)
  end
end
function ∇prod_one(x::Array, Δ)
  zloc = findfirst(iszero, x)
  ∇ = copy(x)
  ∇[zloc] = 1
  nonzero = prod(∇) * Δ
  ∇ .= 0
  ∇[zloc] = nonzero
  ∇
end
∇prod_one(x::AbstractArray, Δ) = ForwardDiff.gradient(y -> prod(y) * Δ, x)

Base.cumsum(xs::TrackedArray; dims=1) = track(cumsum, xs; dims=dims)

@grad cumsum(xs; dims=1) = _cumsum(xs.data, dims)
_cumsum(xd::Array, d) = cumsum(xd; dims=d), Δ -> (reverse(cumsum(reverse(Δ,dims=d),dims=d),dims=d),)
_cumsum(xd::AbstractArray, d) = cumsum(xd; dims=d), Δ -> (mapslices(reverse∘cumsum∘reverse,Δ, dims=d),)

Base.cumprod(xs::TrackedArray; dims=nothing) = track(cumprod, xs; dims=dims)

@grad cumprod(xs; dims=nothing) = _cumprod(xs.data, dims)
_cumprod(xd, ::Nothing, p = cumprod(xd)) = p, Δ -> (nobacksies(:cumprod, ∇cumprod(xd, p, data(Δ)) ),)
_cumprod(xd, d, p = cumprod(xd, dims=d)) = p, Δ -> (nobacksies(:cumprod, ∇cumprod_d(xd, Val(d), p, data(Δ)) ),)

function ∇cumprod(x::Vector, p, Δ)
  len = length(x)
  z = something(findfirst(iszero, x), len+1)
  ∇ = zero(x)
  @inbounds for i=1:z-1
    ixi = 1/x[i]
    for k=i:z-1
      ∇[i] += p[k] * Δ[k] * ixi
    end
  end
  @inbounds if z != len+1
    pk = z==1 ? one(p[1]) : p[z-1] # will be prod(x[j] for j=1:k if j!=z)
    ∇[z] += pk * Δ[z]
    for k=(z+1):len
      pk *= x[k]
      ∇[z] += pk * Δ[k]
    end
  end
  ∇
end
∇cumprod(x::AbstractVector, p, Δ) = vec(Δ' * ForwardDiff.jacobian(cumprod, x))
@noinline function ∇cumprod_d(x::AbstractArray{T,N}, ::Val{d}, p, Δ) where {T,N,d}
  ∇ = similar(x)
  for i in Iterators.product(ntuple(k -> k==d ? Ref(:) : axes(x,k), Val(N))...)
    copyto!(view(∇,i...), ∇cumprod(x[i...], p[i...], Δ[i...]))
  end
  ∇ # roughly mapslices(∇cumprod, x,p,Δ; dims=d) if that existed
end
