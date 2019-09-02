# This file is part of Kpax3. License is MIT.

# normalized distance between a generic partition 'a' and the partition
# {{1, ..., v}}
function distsjlower(n::Vector{T},
                     k::Int,
                     v::Real;
                     β::Real=3.0) where T <: Real
  w = v^β

  z = 0.0
  for g in 1:k
    z += n[g]^β
  end

  (w - z) / (w - v)
end

# normalized distance between a generic partition 'a' and the partition
# {{1}, ..., {v}}
function distsjupper(n::Vector{T},
                     k::Int,
                     v::Real;
                     β::Real=3.0) where T <: Real
  w = v^β

  z = 0.0
  for g in 1:k
    z += n[g]^β
  end

  (z - v) / (w - v)
end

# normalized distance between partition 'a' and partition 'b'
function distsj(a::Vector{Int},
                na::Vector{T},
                ka::Int,
                b::Vector{Int},
                nb::Vector{T},
                kb::Int,
                v::Int;
                β::Real=3.0) where T <: Real
  w = v^β

  count = zeros(Float64, ka, kb)
  for i in 1:v
    count[a[i], b[i]] += 1.0
  end

  za = 0.0
  zb = 0.0
  zab = 0.0

  for g in 1:ka
    za += na[g]^β
  end

  for g in 1:kb
    zb += nb[g]^β
  end

  for g in 1:kb, h in 1:ka
    zab += count[h, g]^β
  end

  (za + zb - 2 * zab) / (w - v)
end
