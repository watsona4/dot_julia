# This file is part of the Julia package ModularForms.jl
#
# Copyright (c) 2018-2019: Lynn Engelberts and Alexandru Ghitza.


"""
    eta_quotient(g, prec=10)

Return the eta-quotient relative to the given collection of integers
`g` as a power series up to precision `prec`. 

The input g is an array of pairs [[t_1,r_1], [t_2,r_2], ..., [t_s,r_s]] 
where each t_j is a positive integer and each r_j a nonnegative integer. 
An error is thrown if the sum of t_j*r_j for j in {1, ..., s} does not
equal 24, as the function only applies to eta-quotients that are cusp
forms. The output is a cusp form of integral weight.  

# Arguments
- `g::Array{Array}`: an array of pairs, collection of integers
- `prec::Integer=10`: precision of the output

# Examples still missing
""" 
function eta_quotient(g::Array{Array{Int,1},1}, prec::Int=10)

   R, q = PolynomialRing(ZZ, "q")
   poly = R(1)		#product
   sum = 0 		#error handling
   s = length(g)
   for i in 1:s
      t = g[i][1]
      r = g[i][2]
      poly = poly * eta_qexp(r, prec, q^t)	#check prec
      sum += t*r 
   end

   if sum != 24
      error("sum of t_j*r_j for all j must equal 24 if it is a cusp form")
   end

   poly = q * poly
   power_series = poly_to_power_series(poly, prec)

   return power_series

end
