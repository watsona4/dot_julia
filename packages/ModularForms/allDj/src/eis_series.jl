# This file is part of the Julia package ModularForms.jl
#
# Copyright (c) 2018-2019: Lynn Engelberts and Alexandru Ghitza.


"""
    eisenstein_series_qexp(k, prec=10, K=QQ, var="q", normalization="linear")

Return the q-expansion of the normalized weight `k` Eisenstein series 
on the modular group to precision `prec` as a power series in the ring 
`K` in variable `var`, using the given `normalization`. 

Three normalizations are available: "linear" (default), "constant", 
and "integral". If the normalization is "linear" then the linear 
coefficient is 1. If it is "constant" then the series will be 
normalized to have constant term 1. If the normalization is "integral"
then the series will be normalized to have integer coefficients and no 
common factors. 
Note: To prevent errors, the output will be in the ring QQ if the 
normalization is "linear" or "constant".

# Arguments
- `k::Integer`: even positive integer, weight of the Eisenstein series
- `prec::Integer=10`: precision of the output 
- `K=ZZ`: base ring of the output 
- `var::String="q"`: variable name
- `normalization::String="linear"`: normalization to use

# Examples still missing
"""
function eisenstein_series_qexp(k::Int, prec::Int=10, K=QQ, var::String="q", normalization::String="linear") 

   #error handling with regard to input ring
   if normalization != "integral"
      K = QQ
   end

   #initialise
   R, q = PowerSeriesRing(K, prec, var)   	#need to change prec?
   qexp = R(0)

   #error handling
   if k%2 != 0 || k<2
      error("k must be an even positive integer")
   end
   if prec <= 0
      error("prec must be a positive integer")
   end

   poly = eisenstein_series_poly(k, prec, var)

   if normalization == "integral"
      return poly_to_power_series(poly, prec)
   end

   qexp = poly_to_power_series(poly, QQ, prec)
   if normalization == "linear" 
      return qexp*1//coeff(qexp, 1)
   elseif normalization == "constant"
      return qexp*1//coeff(qexp, 0)
   else	
      error("normalization must be one of 'linear', 'constant', 'integral'")
   end

end



"""
    eisenstein_series_poly(k, prec=10, var="q")

Return the q-expansion of the weight `k` Eisenstein series up to
precision `prec` as a polynomial over ZZ of degree prec-1 in the 
variable `var`. The polynomial is normalized to have integer 
coefficients and no common factors. 

The algorithm is taken from the SageMath implementation of 
eisenstein_series_poly. 

# Arguments
- `k::Integer`: even positive integer, weight of the Eisenstein series
- `prec::Integer=10`: precision of the output
- `var::String="q"`: variable name

# Examples still missing
"""
function eisenstein_series_poly(k::Int, prec::Int=10, var::String="q")
   a0 = -bernoulli(k) // 2k
   if a0 > 0
      d = ZZ(a0.den)
      n = ZZ(a0.num)
   else
      d = -ZZ(a0.den)
      n = -ZZ(a0.num)
   end
   val = fill(d, prec)
   val[1] = ZZ(n)
   expt = k - 1
   for p in prime_range(prec-1)
      ppow = p
      mult = ZZ(p)^expt
      term = mult * mult
      last = mult
      while ppow < prec
         ind = ppow
         term_m1 = term - 1
         last_m1 = last - 1
         while ind < prec
            val[ind+1] *= term_m1
            val[ind+1], r = fdivrem(val[ind+1], last_m1)
            ind += ppow
         end
         ppow *= p
         last = term
         term *= mult
      end
   end

   R, q = PolynomialRing(ZZ, var)
   return R(val)
end
