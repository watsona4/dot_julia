@inline function _sampleSignedBernoulli(rng)
  return 2*(rand(rng) < 0.5) - 1
end

## A modified version of the algorithm (attributed to S. Vempala) in
## Wästlund, J., 1999. Functions arising by coin flipping. Technical Report,
## KTH, Stockholm.
##
## Specifically, I modified the algorithm so that the calls to f() and the
## sampling of the Bernoulli r.v.s occurs in tandem, so as to avoid the
## infinite expected running time of the initial pass of the original algorithm.
##
## This is also more efficient in terms of calls to f() than the version
## described in
## Flajolet, P., Pelletier, M. and Soria, M., 2011, January. On Buffon machines
## and numbers. In Proc. 22nd ACM-SIAM symposium on Discrete algorithms.
function _wastlundSqrt(f::F, rng::RNG) where
  {F<:Function, RNG<:AbstractRNG}
  flips::Int64 = 0
  x::Bool = f(); flips += 1
  x && (return true, flips)
  s::Int64 = _sampleSignedBernoulli(rng)
  while s > 0
    x = f(); flips += 1
    x && (return true, flips)
    s += _sampleSignedBernoulli(rng) + _sampleSignedBernoulli(rng)
  end
  return false, flips
end
