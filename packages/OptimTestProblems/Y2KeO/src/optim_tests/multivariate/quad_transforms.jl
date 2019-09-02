## These problems are quadratics and transformed quadratics.
# They correspond to Problems A-C in
# Hans De Sterck - Steepest descent preconditioning for nonlinear GMRES optimization


function quad(x::Vector, param)
    mat = param.mat
    xt = x-param.vec
    return 0.5*dot(xt, mat*xt)
end

function quad_gradient!(storage::Vector, x::Vector, param)
    mat = param.mat
    xt = x-param.vec
    storage .= mat*xt
end

function quad_fun_gradient!(storage::Vector, x::Vector, param)
    mat = param.mat
    xt = x-param.vec
    storage .= mat*xt
    return 0.5*dot(xt, mat*xt)
end

function quad_hessian!(storage::Matrix, x::Vector, param)
    storage .= param.mat
end

struct MatVecHolder{Tv <: AbstractVector,
                    Tm <: AbstractArray}
    mat::Tm
    vec::Tv
end

function _quadraticproblem(N::Int; mat::AbstractArray{T,2} = sparse(Diagonal(float(1:N))),
                           x0::AbstractVector{T} = ones(N),
                           initial_x::AbstractVector{T} = zeros(N),
                           name::AbstractString = "Quadratic Diagonal ($N)") where T <: Number
    # Note that _quadraticproblem is a special case of
    # _paraboloidproblem, where param.alpha = 0.0
    OptimizationProblem(name,
                        quad,
                        quad_gradient!,
                        quad_fun_gradient!,
                        quad_hessian!,
                        nothing, # Constraints
                        initial_x,
                        x0,
                        zero(T),
                        true,
                        true,
                        MatVecHolder(mat, x0))
end

examples["Quadratic Diagonal"] = _quadraticproblem(100)

#######################
# Paraboloid. Similar to Rosenbrock
#######################

struct ParaboloidStruct{T, Tm <: AbstractArray{T,2},
                           Tv <: AbstractArray{T}} <: Any where T<:Number
    mat::Tm
    vec::Tv
    xt::Tv
    alpha::T
end

function paraboloid(x::AbstractArray, param::ParaboloidStruct)
    mat = param.mat
    xt = param.xt
    @. xt = x - param.vec
    xt[2:end] .-= param.alpha*xt[1]^2

    return 0.5*dot(xt, mat*xt)
end

function paraboloid_gradient!(storage::AbstractArray, x::AbstractArray, param::ParaboloidStruct)
    mat = param.mat
    xt = param.xt

    @. xt = x - param.vec
    xt[2:end] .-= param.alpha*xt[1]^2

    storage .= mat*xt
    storage[1] -= 2.0*param.alpha*xt[1]*sum(storage[2:end])
end


function paraboloid_fun_gradient!(storage::AbstractArray, x::AbstractArray, param::ParaboloidStruct)
    mat = param.mat
    xt = param.xt

    @. xt = x - param.vec
    xt[2:end] .-= param.alpha*xt[1]^2

    storage .= mat*xt
    storage[1] -= 2.0*param.alpha*xt[1]*sum(storage[2:end])

    return 0.5*dot(xt, mat*xt)
end

function paraboloid_hessian!(storage,x,param)
    error("Hessian not implemented for Paraboloid")
end

function _paraboloidproblem(N::Int; mat::AbstractArray{T,2} = sparse(Diagonal(float(1:N))),
                            x0::AbstractVector{T} = ones(N),
                            initial_x::AbstractVector{T} = zeros(N),
                            alpha::T = 10.0,
                            name::AbstractString = "Paraboloid Diagonal ($N)") where T <: Number
    OptimizationProblem(name,
                        paraboloid,
                        paraboloid_gradient!,
                        paraboloid_fun_gradient!,
                        paraboloid_hessian!,
                        nothing, # Constraints
                        initial_x,
                        x0, # x0 means the solution ...
                        zero(T),
                        true,
                        false,
                        ParaboloidStruct(mat, x0, similar(x0), alpha))
end

examples["Paraboloid Diagonal"] = _paraboloidproblem(100)

function _randommatrix(N::Int, scaling::Bool=true)
    F = qr(randn(N,N))
    if scaling
        retval = F.Q'*sparse(Diagonal(float(1:N)))*F.Q
    else
        retval = F.Q'*F.Q
    end
    retval
end

guardseed(0) do
examples["Paraboloid Random Matrix"] = _paraboloidproblem(100;
                                                          name = "Paraboloid Random Matrix (100)",
                                                          mat = _randommatrix(100))
end
