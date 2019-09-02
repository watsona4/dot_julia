### Source
###
### [3] Moré JJ, Garbow BS, Hillstrom KE: Testing unconstrained optimization software. ACM T Math Software. 1981
###

##########################
### Extended Rosenbrock
###
### Problem (21) from [3]
##########################

function extrosenbrock(x::AbstractArray, param::MatVecHolder)
    # TODO: we could do this without the xt storage holder
    n = length(x)
    jodd = 1:2:n-1
    jeven = 2:2:n

    xt = param.vec
    @. xt[jodd] = 10.0 * (x[jeven] - x[jodd]^2)
    @. xt[jeven] = 1.0 - x[jodd]

    return 0.5*sum(abs2, xt)
end

function extrosenbrock_gradient!(storage::AbstractArray,
                                 x::AbstractArray, param::MatVecHolder)
    n = length(x)
    jodd = 1:2:n-1
    jeven = 2:2:n
    xt = param.vec
    @. xt[jodd] = 10.0 * (x[jeven] - x[jodd]^2)
    @. xt[jeven] = 1.0 - x[jodd]

    @. storage[jodd] = -20.0 * x[jodd] * xt[jodd] - xt[jeven]
    @. storage[jeven] = 10.0 * xt[jodd]
end

function extrosenbrock_fun_gradient!(storage::AbstractArray,
                                     x::AbstractArray, param::MatVecHolder)
    n = length(x)
    jodd = 1:2:n-1
    jeven = 2:2:n
    xt = param.vec
    @. xt[jodd] = 10.0 * (x[jeven] - x[jodd]^2)
    @. xt[jeven] = 1.0 - x[jodd]

    @. storage[jodd] = -20.0 * x[jodd] * xt[jodd] - xt[jeven]
    @. storage[jeven] = 10.0 * xt[jodd]
    return 0.5*sum(abs2, xt)
end


function extrosenbrock_hessian!(storage,x,param)
    error("Hessian not implemented for Extended Rosenbrock")
end

function _extrosenbrockproblem(N::Int;
                               initial_x::AbstractArray{T} = repeat([-1.2,1]; inner = round(Int, N/2)),
                               name::AbstractString = "Extended Rosenbrock ($N)") where T
    @assert mod(N,2) == 0
    OptimizationProblem(name,
                        extrosenbrock,
                        extrosenbrock_gradient!,
                        extrosenbrock_fun_gradient!,
                        extrosenbrock_hessian!,
                        nothing, # Constraints
                        initial_x,
                        fill(T(1), length(initial_x)),
                        zero(T),
                        true,
                        false,
                        MatVecHolder(Array{T}(undef, 0,0),similar(initial_x)))
end

examples["Extended Rosenbrock"] = _extrosenbrockproblem(100)


##########################
### Extended Powell
###
### Problem (22) from [3]
##########################

function extpowell(x::AbstractArray, param::MatVecHolder)
    # TODO: we could do this without the xt storage holder
    n = length(x)
    j1 = 1:4:n-3;
    j2 = 2:4:n-2;
    j3 = 3:4:n-1;
    j4 = 4:4:n;

    xt = param.vec
    @. xt[j1] = x[j1] + 10*x[j2]
    @. xt[j2] = sqrt(5)*(x[j3]-x[j4])
    @. xt[j3] = (x[j2] - 2*x[j3])^2;
    @. xt[j4] = sqrt(10)*(x[j1]-x[j4])^2;

    return 0.5*sum(abs2, xt)
end



function extpowell_gradient!(storage::AbstractArray,
                             x::AbstractArray, param::MatVecHolder)
    # TODO: we could do this without the xt storage holder
    n = length(x)
    j1 = 1:4:n-3;
    j2 = 2:4:n-2;
    j3 = 3:4:n-1;
    j4 = 4:4:n;

    xt = param.vec
    @. xt[j1] = x[j1] + 10*x[j2]
    @. xt[j2] = sqrt(5)*(x[j3]-x[j4])
    @. xt[j3] = (x[j2] - 2*x[j3])^2;
    @. xt[j4] = sqrt(10)*(x[j1]-x[j4])^2;

    @. storage[j1] = xt[j1] + 2*sqrt(10)*(x[j1]-x[j4]).*xt[j4];
    @. storage[j2] = 10*xt[j1] + 2*(x[j2]-2*x[j3]).*xt[j3];
    @. storage[j3] = sqrt(5)*xt[j2] - 4*(x[j2]-2*x[j3]).*xt[j3];
    @. storage[j4] = -sqrt(5)*xt[j2] - 2*sqrt(10)*(x[j1]-x[j4]).*xt[j4];
end

function extpowell_fun_gradient!(storage::AbstractArray,
                                 x::AbstractArray, param::MatVecHolder)
    # TODO: we could do this without the xt storage holder
    n = length(x)
    j1 = 1:4:n-3;
    j2 = 2:4:n-2;
    j3 = 3:4:n-1;
    j4 = 4:4:n;

    xt = param.vec
    @. xt[j1] = x[j1] + 10*x[j2]
    @. xt[j2] = sqrt(5)*(x[j3]-x[j4])
    @. xt[j3] = (x[j2] - 2*x[j3])^2;
    @. xt[j4] = sqrt(10)*(x[j1]-x[j4])^2;

    @. storage[j1] = xt[j1] + 2*sqrt(10)*(x[j1]-x[j4]).*xt[j4];
    @. storage[j2] = 10*xt[j1] + 2*(x[j2]-2*x[j3]).*xt[j3];
    @. storage[j3] = sqrt(5)*xt[j2] - 4*(x[j2]-2*x[j3]).*xt[j3];
    @. storage[j4] = -sqrt(5)*xt[j2] - 2*sqrt(10)*(x[j1]-x[j4]).*xt[j4];
    return 0.5*sum(abs2, xt)
end

function extpowell_hessian!(storage,x,param)
    error("Hessian not implemented for Extended Powell")
end

function _extpowellproblem(N::Int;
                           initial_x::AbstractArray{T} = repeat(float([3,-1,0,1]); inner = round(Int, N/4)),
                           name::AbstractString = "Extended Powell ($N)") where T
    @assert mod(N,4) == 0
    OptimizationProblem(name,
                        extpowell,
                        extpowell_gradient!,
                        extpowell_fun_gradient!,
                        extpowell_hessian!,
                        nothing, # Constraints
                        initial_x,
                        fill(zero(T), length(initial_x)),
                        zero(T),
                        true,
                        false,
                        MatVecHolder(Array{T}(undef, 0,0),similar(initial_x)))
end

examples["Extended Powell"] = _extpowellproblem(100)



##########################
### Penalty function I
###
### Problem (23) from [3]
### Default alpha = sqrt(1e-5)
##########################

function penfunI(x::AbstractArray, param)
    # TODO: we could do this without the xt storage holder
    xt = param.xt
    @. xt = param.alpha*(x-one(eltype(x)))

    xtend = sum(abs2,x)-0.25
    return 0.5*(sum(abs2, xt) + abs2(xtend)) # TODO: make 0.25 a parameter
end

function penfunI_gradient!(storage::AbstractArray,
                           x::AbstractArray, param)
    # TODO: we could do this without the xt storage holder
    xt = param.xt
    @. xt = param.alpha*(x-one(eltype(x)))

    xtend = sum(abs2,x)-0.25
    @. storage = param.alpha*xt + 2.0*xtend*x
end

function penfunI_fun_gradient!(storage::AbstractArray,
                               x::AbstractArray, param)
    # TODO: we could do this without the xt storage holder
    xt = param.xt
    @. xt = param.alpha*(x-one(eltype(x)))

    xtend = sum(abs2,x)-0.25
    @. storage = param.alpha*xt + 2.0*xtend*x
    return 0.5*(sum(abs2, xt) + abs2(xtend)) # TODO: make 0.25 a parameter
end


function penfunI_hessian!(storage,x,param)
    error("Hessian not implemented for Penalty Function I")
end

function _penfunIproblem(N::Int;
                         initial_x::AbstractArray{T} = collect(float(1:N)),
                         alpha::T = sqrt(1e-5),
                         name::AbstractString = "Penalty Function I ($N)") where T
    if N == 100
        # Calculated numerically to high precision |g(x)|<1e-15
        fsol = 0.00045124548840214817
        xsol = fill(0.05000949719895305, N)
    elseif N == 200
        # Calculated numerically to high precision |g(x)|<1e-15
        fsol = 0.000930530019118627
        xsol = fill(0.03536498146451683, N)
    else
        fsol  = NaN
        xsol = fill(NaN, N)
    end

    OptimizationProblem(name,
                        penfunI,
                        penfunI_gradient!,
                        penfunI_fun_gradient!,
                        penfunI_hessian!,
                        nothing, # Constraints
                        initial_x,
                        xsol,
                        fsol,
                        true,
                        false,
                        ParaboloidStruct(Array{T}(undef, 0,0),Array{T}(undef, 0),
                                         similar(initial_x), alpha))
end

examples["Penalty Function I"] = _penfunIproblem(100)



##########################
### Trigonometric function
###
### Problem (26) from [3]
##########################

function trigonometric(x::AbstractArray, param)
    # TODO: we could do this without the xt storage holder
    n = length(x)
    xt = param.vec
    scos = sum(cos,x)
    @. xt = n + (1:n)*(one(eltype(x)) - cos(x)) - sin(x) - scos

    return 0.5*sum(abs2, xt)
end

function trigonometric_gradient!(storage::AbstractArray,
                                 x::AbstractArray, param)
    # TODO: we could do this without the xt storage holder
    n = length(x)
    xt = param.vec
    scos = sum(cos,x)
    @. xt = n + (1:n)*(one(eltype(x)) - cos(x)) - sin(x) - scos

    sxt = sum(xt)
    @. storage = sxt*sin(x) + xt * ((1:n)*sin(x) - cos(x))
end

function trigonometric_fun_gradient!(storage::AbstractArray,
                                     x::AbstractArray, param)
    # TODO: we could do this without the xt storage holder
    n = length(x)
    xt = param.vec
    scos = sum(cos,x)
    @. xt = n + (1:n)*(one(eltype(x)) - cos(x)) - sin(x) - scos

    sxt = sum(xt)
    @. storage = sxt*sin(x) + xt * ((1:n)*sin(x) - cos(x))
    return 0.5*sum(abs2, xt)
end

function trigonometric_hessian!(storage,x,param)
    error("Hessian not implemented for Trigonometric Function")
end

function _trigonometricproblem(N::Int;
                               initial_x::AbstractArray{T} = ones(N)/N,
                               alpha::T = sqrt(1e-5),
                               name::AbstractString = "Trigonometric ($N)") where T
    OptimizationProblem(name,
                        trigonometric,
                        trigonometric_gradient!,
                        trigonometric_fun_gradient!,
                        trigonometric_hessian!,
                        nothing, # Constraints
                        initial_x,
                        fill(T(0), length(initial_x)),
                        zero(T),
                        true,
                        false,
                        MatVecHolder(Array{T}(undef, 0,0),similar(initial_x)))
end

examples["Trigonometric"] = _trigonometricproblem(100)


##########################################################################
###
### Beale (2D)
###
### Problem 5 in [3]
###
### Sum-of-squares objective, non-convex with g'*inv(H)*g == 0 at the
### initial position.
###
##########################################################################

### General utilities for sum-of-squares functions
# TODO: Update the other problems that are not Beale to use sumsq as well?

# Requires f(x) and J(x) computes the values and jacobian at x of a set of functions, and
# that H(x, i) computes the hessian of the ith function

sumsq_obj(f, x) = sum(f(x).^2)

function sumsq_gradient!(g::AbstractVector, f, J, x::AbstractVector)
    copyto!(g, sum((2.0 .* f(x)) .* J(x), dims = 1))
end

function sumsq_hessian!(h::AbstractMatrix, f, J, H, x::AbstractVector)
    fx = f(x)
    Jx = J(x)
    htmp = 2.0 .* (Jx' * Jx)
    for i = 1:length(fx)
        htmp += (2.0 * fx[i]) * H(x, i)
    end
    copyto!(h, htmp)
end

const beale_y = [1.5, 2.25, 2.625]

beale_f(x) = [beale_y[i] - x[1]*(1-x[2]^i) for i = 1:3]
beale_J(x) = hcat([-(1-x[2]^i) for i = 1:3],
                  [i*x[1]*x[2]^(i-1) for i = 1:3])
function beale_H(x, i)
    od = i*x[2]^(i-1)
    d2 = i > 1 ? i*(i-1)*x[1]*x[2]^(i-2) : zero(x[2])
    [0 od; od d2]
end

beale(x::AbstractVector) = sumsq_obj(beale_f, x)

function beale_gradient!(g::AbstractVector, x::AbstractVector)
    sumsq_gradient!(g, beale_f, beale_J, x)
end

function beale_hessian!(h::AbstractMatrix, x::AbstractVector)
    sumsq_hessian!(h, beale_f, beale_J, beale_H, x)
end

examples["Beale"] = OptimizationProblem("Beale",
                                        beale,
                                        beale_gradient!,
                                        nothing,
                                        beale_hessian!,
                                        nothing, # Constraints
                                        [1.0, 1.0],
                                        [3.0, 0.5],
                                        beale([3.0, 0.5]),
                                        true,
                                        true)
