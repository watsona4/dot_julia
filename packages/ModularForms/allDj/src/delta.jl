# This file is part of the Julia package ModularForms.jl
#
# Copyright (c) 2018-2019: Lynn Engelberts and Alexandru Ghitza.


#This file contains the functions delta_poly and delta_qexp which return the 
#q-expansion of delta (the weight 12 level 1 cusp form) as a polynomial or 
#powerseries (respectively). Moreover, this file contains the function 
#delta_k_qexp, which returns the q-expansion of the normalised generator for 
#(one of the six) one-dimensional spaces of cusp forms of weight k and level 1. 


"""
    delta_poly(prec=10, var="q", K=ZZ)

Return the q-expansion of the normalized cusp form of weight 12 to 
precision `prec` as a polynomial over `K` in the variable `var`. 

# Arguments
- `prec::Integer=10`: precision of the output 
- `var::String="q"`: variable name
- `K=ZZ`: base ring of the output

# Examples still missing
"""
function delta_poly(prec::Int=10, var::String="q", K=ZZ)

   R, q = PolynomialRing(ZZ, var)
   delta = q*eta_qexp(24, prec-1, q) 
   RR, q = PolynomialRing(K, var)

   return RR(delta)
end



"""
    delta_qexp(prec=10, var="q", K=ZZ)

Return the q-expansion of the normalized cusp form of weight 12 to 
precision `prec` as a power series over `K` in the variable `var`. 

# Arguments
- `prec::Integer=10`: precision of the output 
- `var::String="q"`: variable name
- `K=ZZ`: base ring of the output

# Examples still missing
"""
function delta_qexp(prec::Int=10, var::String="q", K=ZZ) 
	
   delta = delta_poly(prec, var, K)
   power_series = poly_to_power_series(delta, prec)

   return power_series 
end



"""
    delta_k_qexp(k, prec=10, var="q")

Return the q-expansion of the unique normalized eigenform of weight 
`k` and level 1 for k in {12, 16, 18, 20, 22, 26} as a power series 
to precision `prec` in `var` over ZZ.

These eigenforms are the normalized generators for the six 
one-dimensional spaces of cusp forms of level 1.  

# Arguments
- `k::Integer`: weight of the unique normalized eigenform
- `prec::Integer=10`: precision of the output 
- `var::String="q"`: variable name

# Examples still missing
"""
function delta_k_qexp(k::Int, prec::Int=10, var::String="q")

   if k == 12
      return delta_qexp(prec, var, ZZ)
   elseif k in [16, 18, 20, 22, 26]
      return delta_qexp(prec, var) * eisenstein_series_qexp(k-12, prec, ZZ, var, "integral") 
   else
      error("k must be one of 12, 16, 18, 20, 22, 26")
   end

end
