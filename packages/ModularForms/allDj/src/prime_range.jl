# This file is part of the Julia package ModularForms.jl
#
# Copyright (c) 2018-2019: Lynn Engelberts and Alexandru Ghitza.


"""
    prime_range(n)

Return an array consisting of all primes up to and including `n`.
"""
function prime_range(n::Int)

   primes = fill(true, n)
   if n == 0
      return primes
   end

   primes[1] = false
   for p in 2:n
      primes[p] || continue
      for j in 2:div(n, p)
         primes[p*j] = false
       end
   end

   return findall(primes)
end
