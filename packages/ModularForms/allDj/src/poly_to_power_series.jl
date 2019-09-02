# This file is part of the Julia package ModularForms.jl
#
# Copyright (c) 2018-2019: Lynn Engelberts and Alexandru Ghitza.


"""
    poly_to_power_series(f, K, prec=10)

Convert the polynomial `f` over `K` to a relative power series 
to precision `prec` as a polynomial.

The power series has the same coefficient ring and variable 
name as f. The input polynomial f must be correct up to 
precision prec. 

# Arguments
' `f::PolyElem`: polynomial over K, correct up to prec
- `K`: base ring of the output
- `prec::Integer=10`: precision of the output

# Examples still missing
"""
function poly_to_power_series(f::PolyElem, K, prec::Int=10)

   #initialize
   varname = string(gen(parent(f)))
   R, q = PowerSeriesRing(K, prec, varname)

   if f == 0
      return R(0)
   end

   d = min(degree(f), prec-1)
   c = [coeff(f, i) for i in 0:d]
   power_series = R(c, d+1, prec, 0)

   return power_series
end


function poly_to_power_series(f::PolyElem, prec::Int=10)
   return poly_to_power_series(f, base_ring(f), prec)
end
