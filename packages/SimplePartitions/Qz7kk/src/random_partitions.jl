# RANDOM PARTITIONS

export RandomPartition

# This is a work in process. We'll use the Chinese Restaurant
# Process to generate a random partition of an n-set. We
# hope that the probability we generate a given partition
# is precisely 1/bell(n). We're using ideas from this website:
# http://djalil.chafai.net/blog/2012/05/03/generating-uniform-random-partitions/


# using SimpleTools

"""
`RandomPartition(n)` creates a random partition of {1,2,...,n}. The probability
we see any particular partition is (nearly?) `1/bell(n)`.

THIS IS A WORK IN PROGRESS. It doesn't seem to be working to give the same
probability to all `n`-element partitions.
"""
function RandomPartition(n::Int)
  nn = 10n
  wts = zeros(nn)
  for j=1:nn
    J = BigInt(j)
    wts[j] = Float64(BigInt(J)^n) / Float64(factorial(J))
  end
  k = random_choice(wts)
  d = Dict{Int,Int}()
  for i=1:n
    c = mod(rand(Int),n)+1
    d[i] = c
  end
  return Partition(d)
end


function RP_test(n::Int,reps::Int)
  d = Dict{Partition{Int},Int}()
  for i=1:reps
    P = RandomPartition(n)
    if haskey(d,P)
      d[P]+=1
    else
      d[P]=1
    end
  end
  for P in keys(d)
    println(d[P]/reps,"\t",P)
  end
  println("Goal = ", Float64(1/bell(n)))
  return d
end
