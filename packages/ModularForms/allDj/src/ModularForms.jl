# This file is part of the Julia package ModularForms.jl
#
# Copyright (c) 2018-2019: Lynn Engelberts and Alexandru Ghitza.


"""
   ModularForms

A Julia package for computing with modular forms.

"""
module ModularForms

using Nemo

export delta_poly
export delta_qexp
export delta_k_qexp
export eisenstein_series_poly
export eisenstein_series_qexp
export eta_quotient
export hecke_operator_on_basis
export hecke_operator_on_qexp 
export poly_to_power_series
export prime_range
export dim_Sk
export dim_Mk
export victor_miller_basis

include("delta.jl")
include("eis_series.jl")
include("eta_quotient.jl")
include("hecke.jl")
include("poly_to_power_series.jl")
include("prime_range.jl")
include("vm_basis.jl")

export func

"""
    func(x)

Return func
""" 
func(x) = 2x + 1 

end # module
