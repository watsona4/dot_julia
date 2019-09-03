###############################################################################
#################### Submatrix from the proportional terms ####################
###############################################################################
function (method::SemiDiscretization)(A::CyclicVector{<:AbstractMatrix}, rst::AbstractResult{d}) where d
   fill(SubMX(subMxRange(0, d), exp(A[1] * method.Δt)), rst.n_steps)
end
function (method::SemiDiscretization)(A::Vector{<:AbstractMatrix}, rst::AbstractResult{d}) where d
    SubMX.((subMxRange(0, d),), exp.(A .* method.Δt))
end

###############################################################################
###################### Submatrix from the delayed terms #######################
###############################################################################
#τ discretisation
function (method::SemiDiscretization)(τ::Real, rst::AbstractResult{d}) where d
    r = rOfDelay(τ, method)
    τerr = τ - r * method.Δt
    ranges = [subMxRange(r - k, d) for k in 0:methodorder(method)]
    return (τerr, ranges)
end
function (method::SemiDiscretization)(τs::Vector{<:Real}, rst::AbstractResult{d}) where d
    rs = rOfDelay.(τs, Ref(method))
    τerrs = τs .- rs .* method.Δt
    rangess = [[subMxRange(r - k, d) for k in 0:methodorder(method)] for r in rs]
    return (τerrs, rangess)
end

###############################################################################
# To distinguish between B as a constant matrix vs B as a function matrix

function (method::SemiDiscretization{<:NumericSD})(τ::Real, B::DelayMX{d,dT,<:AbstractMatrix}, rst::AbstractResult) where {d,dT}
    (τerr, ranges) = method(τ, rst)
    MXs = [[QuadGK.quadgk((t -> (exp(rst.A_avgs[i] * (method.Δt - t)) * lagr_el0(methodorder(method), k, τerr, method.Δt, t))), 0.0, method.Δt)[1] * B.MX for k in 0:methodorder(method)] for i in 1:rst.n_steps]
    # SubMX.((ranges,), MXs)
    # TODO: this is for 1.0
    SubMX.(Ref(ranges), MXs)
end
function (method::SemiDiscretization{<:NumericSD})(τs::Vector{<:Real}, B::DelayMX{d,dT,<:AbstractMatrix}, rst::AbstractResult) where {d,dT}
    (τerrs, rangess) = method(τs, rst)
    MXs = [[QuadGK.quadgk((t -> (exp(rst.A_avgs[i] * (method.Δt - t)) * lagr_el0(methodorder(method), k, τerrs[i], method.Δt, t))), 0.0, method.Δt)[1] * B.MX for k in 0:methodorder(method)] for i in 1:rst.n_steps]
    SubMX.(rangess, MXs)
end
function (method::SemiDiscretization{<:NumericSD})(τ::Real, B::DelayMX{d,dT,<:Function}, rst::AbstractResult) where {d,dT}
    (τerr, ranges) = method(τ, rst)
    MXs = [[QuadGK.quadgk((t -> (exp(rst.A_avgs[i] * (rst.ts[i + 1] - t)) * B(t) * lagr_el0(methodorder(method), k, τerr, method.Δt, t-rst.ts[i]))), rst.ts[i], rst.ts[i + 1])[1] for k in 0:methodorder(method)] for i in 1:rst.n_steps]
    # SubMX.((ranges,), MXs)
    # TODO: this is for 1.0
    SubMX.(Ref(ranges), MXs)
end
function (method::SemiDiscretization{<:NumericSD})(τs::Vector{<:Real}, B::DelayMX{d,dT,<:Function}, rst::AbstractResult) where {d,dT}
    (τerrs, rangess) = method(τs, rst)
    MXs = [[QuadGK.quadgk((t -> (exp(rst.A_avgs[i] * (rst.ts[i + 1] - t)) * B(t) * lagr_el0(methodorder(method), k, τerrs[i], method.Δt, t-rst.ts[i]))), rst.ts[i], rst.ts[i + 1])[1] for k in 0:methodorder(method)] for i in 1:rst.n_steps]
    SubMX.(rangess, MXs)
end

###############################################################################
# To distinguish between τ as constant vs τ as function
function (method::SemiDiscretization{<:NumericSD})(B::DelayMX{d,<:Real,mT}, rst::AbstractResult) where {d,mT}
    method(B.τ.τ, B, rst)
    # rest=method(B.τ.τ, B, rst)
    # println(typeof(rest))
    # rest
end

function (method::SemiDiscretization{<:NumericSD})(B::DelayMX{d,<:Function,mT}, rst::AbstractResult) where {d,mT}
    τis = [quadgk(B.τ, rst.ts[i], rst.ts[i + 1])[1] / method.Δt for i in 1:rst.n_steps]
    method(τis, B, rst)
    # rest=method(τis, B, rst)
    # println(typeof(rest))
    # rest
end

###############################################################################
###################### Submatrix from the additive terms ######################
###############################################################################
function (method::SemiDiscretization)(c::Additive{d,<:AbstractArray{<:Real}}, rst::AbstractResult{d}) where d
    Vs = SubV.([SVector{d}(vec(quadgk(t -> exp(rst.A_avgs[i] * (method.Δt - t)), zero(method.Δt), method.Δt)[1] * c.V)) for i in 1:rst.n_steps])
end
function (method::SemiDiscretization)(c::Additive{d,<:Function}, rst::AbstractResult{d}) where d
    Vs = SubV.([SVector{d}(vec(quadgk(t -> exp(rst.A_avgs[i] * (rst.ts[i + 1] - t)) * c(t), rst.ts[i], rst.ts[i + 1])[1])) for i in 1:rst.n_steps])
end
function (method::SemiDiscretization)(c::Additive{d,<:Array{<:Nothing}}, rst::AbstractResult) where d
    Vs = fill(SubV(@SArray zeros(d)),length(rst.ts)-1)
end
