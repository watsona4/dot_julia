using RNGPool
using Random

setRNGs(1)

mutable struct CG <: AbstractRNG
  ctr::Int64
  nt::Int64
end

function myrand(cg::CG)
  rng::RNGPool.RNG = RNGPool.getRNG(cg.ctr)
  cg.ctr += 1
  cg.ctr > cg.nt && (cg.ctr = 1)
  v::Float64 = rand(rng)
  return v
end

println("Testing circular RNG with ", Threads.nthreads(), " threads")
const cg = CG(1, Threads.nthreads())
generator() = myrand(cg)
