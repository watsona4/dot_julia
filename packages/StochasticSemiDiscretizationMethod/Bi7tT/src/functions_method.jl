for T in union(InteractiveUtils.subtypes(ItoIsometryMethod))
    @eval (::$T)(val1::Real,val2::Real) = val1 * val2
end
function (iim::Trapezoidal)(f1::AbstractVector{<:Real},f2::AbstractVector{<:Real})
    sum(f1 .* f2 .* iim) * iim.dt
end
function (iim::Trapezoidal{k})(f::Function,t0::Real,t1::Real) where k
    toFunctionMXelements(f.(t0:iim.dt:(t1+100eps(t1))),iim)
end
###############################################################################
############## Submatrix from the stochastic proportional terms ###############
###############################################################################
# TODO: increase the performance for constant matrices!
function (method::SemiDiscretization)(A::stCoeffMX{d,<:ProportionalMX}, rst::AbstractResult{d}) where d
    stSubMX.(Ref(A.nID),
        Ref([subMxRange(0, d)]),
        [[rst.itoisometrymethod(t->exp(rst.A_avgs[i]*(t1-t))*A(t)*exp(rst.A_avgs[i]*(t-rst.ts[i])),rst.ts[i],t1)]
          for (i,t1) in enumerate(rst.ts[2:end])])
end
# function (method::SemiDiscretization)(A::stCoeffMX{<:ProportionalMX{<:AbstractMatrix}}, rst::AbstractResult)
#     ... function body ...
# end
# function (method::SemiDiscretization)(A::stCoeffMX{<:ProportionalMX{<:Function}}, rst::AbstractResult)
#     ... function body ...
# end

###############################################################################
################# Submatrix from the stochastic delayed terms #################
###############################################################################
# TODO: increase the performance for constant matrices!
function (method::SemiDiscretization{<:NumericSD})(τ::Real, B::stCoeffMX{d,<:DelayMX}, rst::AbstractResult{d}) where {d,T}
    (τerr, ranges) = method(τ, rst)
    MXs = [[rst.itoisometrymethod((t -> (exp(rst.A_avgs[i] * (rst.ts[i + 1] - t)) * B(t) * lagr_el0(methodorder(method), k, τerr, rst.ts[i + 1], t))), rst.ts[i], rst.ts[i + 1]) for k in 0:methodorder(method)] for i in 1:rst.n_steps]
    stSubMX.(Ref(B.nID),Ref(ranges), MXs)
end
function (method::SemiDiscretization{<:NumericSD})(τs::Vector{<:Real}, B::stCoeffMX{d,<:DelayMX}, rst::AbstractResult{d}) where {d,T}
    (τerrs, rangess) = method(τs, rst)
    MXs = [[rst.itoisometrymethod((t -> (exp(rst.A_avgs[i] * (rst.ts[i + 1] - t)) * B(t) * lagr_el0(methodorder(method), k, τerrs[i], rst.ts[i + 1], t))), rst.ts[i], rst.ts[i + 1]) for k in 0:methodorder(method)] for i in 1:rst.n_steps]
    stSubMX.(Ref(B.nID),rangess, MXs)
end
###############################################################################
# To distinguish between τ as constant vs τ as function
function (method::SemiDiscretization{<:NumericSD})(B::stCoeffMX{d,<:DelayMX{d,<:Real,T}}, rst::AbstractResult{d}) where {d,T}
    method(B.cMX.τ.τ, B, rst)
end

function (method::SemiDiscretization{<:NumericSD})(B::stCoeffMX{d,<:DelayMX{d,<:Function,T}}, rst::AbstractResult{d}) where {d,T}
    τis = [quadgk(B.cMX.τ, rst.ts[i], rst.ts[i + 1])[1] / method.Δt for i in 1:rst.n_steps]
    method(τis, B, rst)
end

###############################################################################
################ Subvectors from the stochastic additive terms ################
###############################################################################
# TODO: increase the performance for constant matrices and vectors!
function (method::SemiDiscretization{<:NumericSD})(σV::stAdditive{d,Additive{d,T}}, rst::AbstractResult{d}) where {d,T}
    [stSubV(σV.nID, rst.itoisometrymethod((t -> (exp(rst.A_avgs[i] * (rst.ts[i + 1] - t)) * σV(t))), rst.ts[i], rst.ts[i + 1])) for i in 1:rst.n_steps]
end
