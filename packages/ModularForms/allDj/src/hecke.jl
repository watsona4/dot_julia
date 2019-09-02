# This file is part of the Julia package ModularForms.jl
#
# Copyright (c) 2018-2019: Lynn Engelberts and Alexandru Ghitza.


#This file contains the functions hecke_operator_on_basis and hecke_operator_on_qexp. 



"""
    hecke_operator_on_basis(B, n, k) 

Compute the matrix of the Hecke operator T_`n` of weight `k`
relative to the given basis `B` of q-expansions for a space of 
modular forms. 

# Arguments
- `B::Array`: array of q-expansions
- `n::Integer`: integer >=1 
- `k::Integer`: weight 

# Examples still missing
"""
function hecke_operator_on_basis(B::Array{fmpz_rel_series,1}, n::Int, k::Int)

   #error handling
   if n < 1
      error("n (=$n) must be a positive integer")
   end
   if isa(B, Array) == false
      error("B (=$B) must be an array")
   end

   #construct dxd matrix
   ring = base_ring(B[1])
   d = length(B)			#check if this is always correct
   S = MatrixSpace(ring, d, d)
   matrix = S()

   #compute Tn(f) to precision d+1 for each element f of B
   for j in 1:d
      f = B[j]
      T_f = hecke_operator_on_qexp(f, n, k, d+1)
      #check if cusp form
      if d == dim_Sk(k)
         for i in 1:d
            #Tn for the jth element of B corresponds to the jth row
            matrix[j,i] = coeff(T_f,i)
         end
      else
         for i in 0:d-1
            #Tn for the jth element of B corresponds to the jth row
            matrix[j,i+1] = coeff(T_f,i)
         end		
      end
   end

   return matrix

end



"""
    divisors(n)

Return an array consisting of all divisors of `n` if n is 
nonzero, raise an error otherwise. 
"""
function divisors(n::Int)

   #error handling
   if n == 0
      error("n must be nonzero")
   end

   n = abs(n)
   array = [div for div in 1:n if n%div == 0]
   return array

end



""" 
    hecke_operator_on_qexp(f, n, k, prec=nothing)

Compute the image of the q-expansion `f` of a modular form under
the Hecke operator T_`n` of weight `k`. Return a power series to
precision `prec`. 

# Arguments
- `f::RelSeriesElem`: q-expansion
- `n::Integer`: integer >=1 
- `k::Integer`: weight 
- `prec::Integer=nothing`: precision of the output

# Examples still missing
"""
function hecke_operator_on_qexp(f::fmpz_rel_series, n::Int, k::Int, prec::Union{Int, Nothing}=nothing)

   max_prec = Int(ceil(f.prec / Int(n)))	#check if works also for n nonprime 
   if prec == nothing
      prec = max_prec
   elseif prec > max_prec
      error("desired precision is too high given precision of f")
   end

   R, q = PowerSeriesRing(base_ring(f), prec, "q")
   T_p = R(0)	

   l = k-1
   for m in 0:prec-1		#start with 0 to deal with all modular forms
      sum = 0
      array = divisors(gcd(n,m)) 	#check if there is a quicker method
      for i in 1:length(array)
         d = array[i]
         if (m*n)%(d*d) == 0
            index = (m*n)//(d*d)
            sum += d^l * coeff(f, Int(index))
         end
      end
      T_p += sum*q^m
   end
	
   return T_p

end
