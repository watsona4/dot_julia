"""
    AbstractAutologisticModel

Abstract type representing autologistic models. All concrete subtypes should have the
following fields:

*   `responses::Array{Bool,2}` -- The binary observations. Rows are for nodes in the 
    graph, and columns are for independent (vector) observations.  It is a 2D array even if 
    there is only one observation.
*   `unary<:AbstractUnaryParameter` -- Specifies the unary part of the model.
*   `pairwise<:AbstractPairwiseParameter`  -- Specifies the pairwise part of the model 
    (including the graph).
*   `centering<:CenteringKinds` -- Specifies the form of centering used, if any.
*   `coding::Tuple{T,T} where T<:Real` -- Gives the numeric coding of the responses.
*   `labels::Tuple{String,String}` -- Provides names for the high and low states.
*   `coordinates<:SpatialCoordinates` -- Provides 2D or 3D coordinates for each vertex in 
    the graph.

This type has the following functions defined, considered part of the type's interface.
They cover most operations one will want to perform.  Concrete subtypes should not have to
define custom overrides unless more specialized or efficient algorithms exist for the 
subtype.

*   `getparameters` and `setparameters!`
*   `getunaryparameters` and `setunaryparameters!`
*   `getpairwiseparameters` and `setpairwiseparameters!`
*   `centeringterms`
*   `negpotential`, `pseudolikelihood`, and `loglikelihood`
*   `fullPMF`, `marginalprobabilities`, and `conditionalprobabilities`
*   `fit_pl!` and `fit_ml!`
*   `sample` and `oneboot`
*   `showfields`

# Examples
```jldoctest
julia> M = ALsimple(Graph(4,4));
julia> typeof(M)
ALsimple{CenteringKinds,Int64,Nothing}
julia> isa(M, AbstractAutologisticModel)
true
```
"""
abstract type AbstractAutologisticModel end

# === Getting/setting parameters ===============================================
"""
    getparameters(x)

A generic function for extracting the parameters from an autologistic model, a unary term,
or a pairwise term.  Parameters are always returned as an `Array{Float64,1}`.  If 
`typeof(x) <: AbstractAutologisticModel`, the returned vector is partitioned with the unary
parameters first.
"""
getparameters(M::AbstractAutologisticModel) = [getparameters(M.unary); getparameters(M.pairwise)]
"""
    getunaryparameters(M::AbstractAutologisticModel)

Extracts the unary parameters from an autologistic model. Parameters are always returned as
an `Array{Float64,1}`.
"""
getunaryparameters(M::AbstractAutologisticModel) = getparameters(M.unary)

"""
    getpairwiseparameters(M::AbstractAutologisticModel)

Extracts the pairwise parameters from an autologistic model. Parameters are always returned as
an `Array{Float64,1}`.
"""
getpairwiseparameters(M::AbstractAutologisticModel) = getparameters(M.pairwise)

"""
    setparameters!(x, newpars::Vector{Float64})

A generic function for setting the parameter values of an autologistic model, a unary term,
or a pairwise term.  Parameters are always passed as an `Array{Float64,1}`.  If 
`typeof(x) <: AbstractAutologisticModel`, the `newpars` is assumed partitioned with the
unary parameters first.
"""
function setparameters!(M::AbstractAutologisticModel, newpars::Vector{Float64})
    p, q = (length(getunaryparameters(M)), length(getpairwiseparameters(M)))
    @assert length(newpars) == p + q "newpars has wrong length"
    setparameters!(M.unary, newpars[1:p])
    setparameters!(M.pairwise, newpars[p+1:p+q])
    return newpars
end

"""
    setunaryparameters!(M::AbstractAutologisticModel, newpars::Vector{Float64})

Sets the unary parameters of autologistic model `M` to the values in `newpars`.
"""
function setunaryparameters!(M::AbstractAutologisticModel, newpars::Vector{Float64})
    setparameters!(M.unary, newpars)
end

"""
    setpairwiseparameters!(M::AbstractAutologisticModel, newpars::Vector{Float64})

Sets the pairwise parameters of autologistic model `M` to the values in `newpars`.
"""
function setpairwiseparameters!(M::AbstractAutologisticModel, newpars::Vector{Float64})
    setparameters!(M.pairwise, newpars)
end
# ==============================================================================

# === Show Methods==============================================================
show(io::IO, m::AbstractAutologisticModel) = print(io, "$(typeof(m))")

function show(io::IO, ::MIME"text/plain", m::AbstractAutologisticModel)
    print(io, "Autologistic model of type $(typeof(m)), \n",
              "with $(size(m.unary,1)) vertices, $(size(m.unary, 2)) ",
              "$(size(m.unary,2)==1 ? "observation" : "observations") ", 
              "and fields:\n",
              showfields(m,2))
end

function showfields(m::AbstractAutologisticModel, leadspaces=0)
    return repeat(" ", leadspaces) * 
           "(**Autologistic.showfields not implemented for $(typeof(m))**)\n"
end
# ==============================================================================

"""
    centeringterms(M::AbstractAutologisticModel, kind::Union{Nothing,CenteringKinds}=nothing)

Returns an `Array{Float64,2}` of the same dimension as `M.unary`, giving the centering
adjustments for autologistic model `M`. `centeringterms(M,kind)` returns the centering
adjustment that would be used if centering were of type `kind`.

# Examples
```jldoctest
julia> G = makegrid8(2,2).G;
julia> X = [ones(4) [-2; -1; 1; 2]];
julia> M1 = ALRsimple(G, X, β=[-1.0, 2.0]);                 #-No centering (default)
julia> M2 = ALRsimple(G, X, β=[-1.0, 2.0], centering=expectation);  #-Centered model
julia> [centeringterms(M1) centeringterms(M2) centeringterms(M1, onehalf)]
4×3 Array{Float64,2}:
 0.0  -0.999909  0.5
 0.0  -0.995055  0.5
 0.0   0.761594  0.5
 0.0   0.995055  0.5
```
"""
function centeringterms(M::AbstractAutologisticModel, kind::Union{Nothing,CenteringKinds}=nothing) 
    k = kind==nothing ? M.centering : kind
    if k == none
        return fill(0.0, size(M.unary))
    elseif k == onehalf
        return fill(0.5, size(M.unary))
    elseif k == expectation
        lo, hi = M.coding
        α = M.unary[:,:] 
        num = lo*exp.(lo*α) + hi*exp.(hi*α)
        denom = exp.(lo*α) + exp.(hi*α)
        return num./denom
    else 
        error("centering kind not recognized")
    end
end


"""
    pseudolikelihood(M::AbstractAutologisticModel)

Computes the negative log pseudolikelihood for autologistic model `M`. Returns a `Float64`.

# Examples
```jldoctest
julia> X = [1.1 2.2
            1.0 2.0
            2.1 1.2
            3.0 0.3];
julia> Y = [0; 0; 1; 0];
julia> M3 = ALRsimple(makegrid4(2,2)[1], cat(X,X,dims=3), Y=cat(Y,Y,dims=2), 
                      β=[-0.5, 1.5], λ=1.25, centering=expectation);
julia> pseudolikelihood(M3)
12.333549445795818
```
"""
function pseudolikelihood(M::AbstractAutologisticModel)
    out = 0.0
    Y = makecoded(M)
    mu = centeringterms(M)
    lo, hi = M.coding

    # Loop through observations
    for j = 1:size(Y)[2]
        y = Y[:,j];                     #-Current observation's values.
        α = M.unary[:,j]                #-Current observation's unary parameters.
        μ = mu[:,j]                     #-Current observation's centering terms.
        Λ = M.pairwise[:,:,j]           #-Current observation's assoc. matrix.
        s = α + Λ*(y - μ)               #-(λ-weighted) neighbour sums + unary.
        logPL = sum(y.*s - log.(exp.(lo*s) + exp.(hi*s)))
        out = out - logPL               #-Subtract this rep's log PL from total.
    end

    return out

end

function pslik!(θ::Vector{Float64}, M::AbstractAutologisticModel)
    setparameters!(M, θ)
    return pseudolikelihood(M)
end

"""
    oneboot(M::AbstractAutologisticModel; 
        start=zeros(length(getparameters(M))),
        verbose::Bool=false,
        kwargs...
    )

Performs one parametric bootstrap replication from autologistic model `M`: draw a
random sample from `M`, use that sample as the responses, and re-fit the model.  Returns
a named tuple `(:sample, :estimate, :convergence)`, where `:sample` holds the random
sample, `:estimate` holds the parameter estimates, and `:convergence` holds a `bool`
indicating whether or not the optimization converged.  The parameters of `M` remain
unchanged by calling `oneboot`.

# Arguments
- `start`: starting parameter values to use for optimization
- `verbose`: should progress information be written to the console?
- `kwargs...`: extra keyword arguments that are passed to `optimize()` or `sample()`, as
  appropriate.

# Examples
```jldoctest
julia> G = makegrid4(4,3).G;
julia> model = ALRsimple(G, ones(12,1), Y=[fill(-1,4); fill(1,8)]);
julia> theboot = oneboot(model, method=Gibbs, burnin=250);
julia> fieldnames(typeof(theboot))
(:sample, :estimate, :convergence)```
"""
function oneboot(M::AbstractAutologisticModel; 
                 start=zeros(length(getparameters(M))),
                 verbose::Bool=false,
                 kwargs...)

    oldY = M.responses;
    oldpar = getparameters(M)
    optimargs, sampleargs = splitkw(kwargs)
    yboot = sample(M; verbose=verbose, sampleargs...)
    M.responses = makebool(yboot, M.coding)
    thisfit = fit_pl!(M; start=start, verbose=verbose, kwargs...)
    M.responses = oldY
    setparameters!(M, oldpar)

    return (sample=yboot, estimate=thisfit.estimate, convergence=thisfit.convergence)
end

"""
    oneboot(M::AbstractAutologisticModel, params::Vector{Float64};
        start=zeros(length(getparameters(M))),
        verbose::Bool=false,
        kwargs...
    )

Computes one bootstrap replicate using model `M`, but using parameters `params` for 
generating samples, instead of `getparameters(M)`.
"""
function oneboot(M::AbstractAutologisticModel, params::Vector{Float64};
                 start=zeros(length(getparameters(M))),
                 verbose::Bool=false,
                 kwargs...)
    oldpar = getparameters(M)
    out = oneboot(M; start=start, verbose=verbose, kwargs...)
    setparameters!(M, oldpar)
    return out
end

"""
    fit_pl!(M::AbstractAutologisticModel;
        start=zeros(length(getparameters(M))), 
        verbose::Bool=false,
        nboot::Int = 0,
        kwargs...)

Fit autologistic model `M` using maximum pseudolikelihood. 

# Arguments
- `start`: initial value to use for optimization.
- `verbose`: should progress information be printed to the console?
- `nboot`: number of samples to use for parametric bootstrap error estimation.
  If `nboot=0` (the default), no bootstrap is run.
- `kwargs...` extra keyword arguments that are passed on to `optimize()` or `sample()`,
  as appropriate.

# Examples
```jldoctest
julia> Y=[[fill(-1,4); fill(1,8)] [fill(-1,3); fill(1,9)] [fill(-1,5); fill(1,7)]];
julia> model = ALRsimple(makegrid4(4,3).G, ones(12,1,3), Y=Y);
julia> fit = fit_pl!(model, start=[-0.4, 1.1]);
julia> summary(fit)
name          est     se   p-value   95% CI
parameter 1   -0.39
parameter 2    1.1
```
"""
function fit_pl!(M::AbstractAutologisticModel;
                 start=zeros(length(getparameters(M))), 
                 verbose::Bool=false,
                 nboot::Int = 0,
                 kwargs...)

    originalparameters = getparameters(M)
    npar = length(originalparameters)
    ret = ALfit()  
    ret.kwargs = kwargs
    optimargs, sampleargs = splitkw(kwargs)

    opts = Options(; optimargs...)
    if verbose 
        println("-- Finding the maximum pseudolikelihood estimate --")
        println("Calling Optim.optimize with BFGS method...")
    end
    out = try
        optimize(θ -> pslik!(θ,M), start, BFGS(), opts)
    catch err
        err
    end
    ret.optim = out
    if typeof(out)<:Exception || !converged(out)
        setparameters!(M, originalparameters)
        @warn "Optim.optimize did not succeed. Model parameters have not been changed."
        ret.convergence = false
        return ret
    else
        setparameters!(M, out.minimizer)
        ret.estimate = out.minimizer
        ret.convergence = true
    end

    if verbose
        println("-- Parametric bootstrap variance estimation --")
        if nboot == 0
            println("nboot==0. Skipping the bootstrap. Returning point estimates only.")
        end
    end

    if nboot > 0
        if length(workers()) > 1
            if verbose
                println("Attempting parallel bootstrap with $(length(workers())) workers.")
            end
            n, m = size(M.responses)
            bootsamples = SharedArray{Float64}(n, m, nboot)
            bootestimates = SharedArray{Float64}(npar, nboot)
            convresults = SharedArray{Bool}(nboot)
            @sync @distributed for i = 1:nboot
                bootout = oneboot(M; start=start, kwargs...)
                bootsamples[:,:,i] = bootout.sample
                bootestimates[:,i] = bootout.estimate
                convresults[i] = bootout.convergence
            end                    
            addboot!(ret, Array(bootsamples), Array(bootestimates), Array(convresults))
        else
            if verbose print("bootstrap iteration 1") end
            bootresults = Array{NamedTuple{(:sample, :estimate, :convergence)}}(undef,nboot)
            for i = 1:nboot
                bootresults[i] = oneboot(M; start=start, kwargs...)
                if verbose print(mod(i,10)==0 ? i : "|") end
            end
            if verbose print("\n") end
            addboot!(ret, bootresults)
        end
    end

    return ret
             
end


# TODO: consider if the main line of linear algebra can be sped up.  
"""
    negpotential(M::AbstractAutologisticModel)

Returns an m-vector of `Float64` negpotential values, where m is the number of observations
found in `M.responses`.

# Examples
```jldoctest
julia> M = ALsimple(makegrid4(3,3).G, ones(9));
julia> f = fullPMF(M);
julia> exp(negpotential(M)[1])/f.partition ≈ exp(loglikelihood(M))
true
```
"""
function negpotential(M::AbstractAutologisticModel)
    Y = makecoded(M)
    m = size(Y,2)
    out = Array{Float64}(undef, m)
    α = M.unary[:,:]
    μ = centeringterms(M)
    for j = 1:m
        Λ = M.pairwise[:,:,j]
        out[j] = Y[:,j]'*α[:,j] - Y[:,j]'*Λ*μ[:,j]  + Y[:,j]'*Λ*Y[:,j]/2
    end
    return out
end


"""
    fullPMF(M::AbstractAutologisticModel; 
        indices=1:size(M.unary,2), 
        force::Bool=false
    )

Compute the PMF of an AbstractAutologisticModel, and return a `NamedTuple` `(:table, :partition)`.

For an AbstractAutologisticModel with ``n`` variables and ``m`` observations, `:table` is a
``2^n×(n+1)×m`` array of `Float64`. Each page of the 3D array holds a probability table for 
an observation.  Each row of the table holds a specific configuration of the responses, with
the corresponding probability in the last column.  In the ``m=1`` case,  `:table` is a 2D 
array.

Output `:partition` is a vector of normalizing constant (a.k.a. partition function) values.
In the ``m=1`` case, it is a scalar `Float64`.

# Arguments
- `indices`: indices of specific observations from which to obtain the output. By 
  default, all observations are used.
- `force`: calling the function with ``n>20`` will throw an error unless 
  `force=true`. 

# Examples
```jldoctest
julia> M = ALRsimple(Graph(3,0),ones(3,1));
julia> pmf = fullPMF(M);
julia> pmf.table
8×4 Array{Float64,2}:
 -1.0  -1.0  -1.0  0.125
 -1.0  -1.0   1.0  0.125
 -1.0   1.0  -1.0  0.125
 -1.0   1.0   1.0  0.125
  1.0  -1.0  -1.0  0.125
  1.0  -1.0   1.0  0.125
  1.0   1.0  -1.0  0.125
  1.0   1.0   1.0  0.125
julia> pmf.partition
 8.0
```
"""
function fullPMF(M::AbstractAutologisticModel; indices=1:size(M.unary,2), 
                 force::Bool=false)
    n, m = size(M.unary)
    nc = 2^n
    if n>20 && !force
        error("Attempting to tabulate a PMF with more than 2^20 configurations."
              * "\nIf you really want to do this, set force=true.")
    end
    if minimum(indices)<1 || maximum(indices)>m 
        error("observation index out of bounds")
    end
    lo = M.coding[1]
    hi = M.coding[2]
    T = zeros(nc, n+1, length(indices))
    configs = zeros(nc,n)
    partition = zeros(m)
    for i in 1:n
        inner = [repeat([lo],Int(nc/2^i)); repeat([hi],Int(nc/2^i))]
        configs[:,i] = repeat(inner , 2^(i-1) )
    end
    for i in 1:length(indices)
        r = indices[i]
        T[:,1:n,i] = configs
        α = M.unary[:,r]
        Λ = M.pairwise[:,:,r]
        μ = centeringterms(M)[:,r]
        unnormalized = mapslices(v -> exp.(v'*α - v'*Λ*μ + v'*Λ*v/2), configs, dims=2)
        partition[i] = sum(unnormalized)
        T[:,n+1,i] = unnormalized / partition[i]
    end
    if length(indices)==1
        T  = dropdims(T,dims=3)
        partition = partition[1]
    end
    return (table=T, partition=partition)
end

"""
    loglikelihood(M::AbstractAutologisticModel; 
        force::Bool=false
    )

Compute the natural logarithm of the likelihood for autologistic model `M`.  This will throw
an error for models with more than 20 vertices, unless `force=true`.

# Examples
```jldoctest
julia> model = ALRsimple(makegrid4(2,2)[1], ones(4,2,3), centering = expectation,
                         coding = (0,1), Y = repeat([true, true, false, false],1,3));
julia> setparameters!(model, [1.0, 1.0, 1.0]);
julia> loglikelihood(model)
-11.86986109487605
```
"""
function loglikelihood(M::AbstractAutologisticModel; force::Bool=false)
    parts = fullPMF(M, force=force).partition
    return sum(negpotential(M) .- log.(parts))
end

function negloglik!(θ::Vector{Float64}, M::AbstractAutologisticModel; force::Bool=false)
    setparameters!(M,θ)
    return -loglikelihood(M, force=force)
end

"""
    fit_ml!(M::AbstractAutologisticModel;
        start=zeros(length(getparameters(M))),
        verbose::Bool=false,
        force::Bool=false,
        kwargs...
    )

Fit autologistic model `M` using maximum likelihood. Will fail for models with more than 
20 vertices, unless `force=true`.  Use `fit_pl!` for larger models.

# Arguments
- `start`: initial value to use for optimization.
- `verbose`: should progress information be printed to the console?
- `force`: set to `true` to force computation of the likelihood for large models.
- `kwargs...` extra keyword arguments that are passed on to `optimize()`.

# Examples
```jldoctest
julia> G = makegrid4(4,3).G;
julia> model = ALRsimple(G, ones(12,1), Y=[fill(-1,4); fill(1,8)]);
julia> mle = fit_ml!(model);
julia> summary(mle)
name          est      se      p-value   95% CI
parameter 1   0.0791   0.163   0.628       (-0.241, 0.399)
parameter 2   0.425    0.218   0.0511    (-0.00208, 0.852)
```
"""
function fit_ml!(M::AbstractAutologisticModel;
                 start=zeros(length(getparameters(M))),
                 verbose::Bool=false,
                 force::Bool=false,
                 kwargs...)

    originalparameters = getparameters(M)
    npar = length(originalparameters)
    ret = ALfit()  
    ret.kwargs = kwargs
    opts = Options(; kwargs...)
    if verbose
        println("Calling Optim.optimize with BFGS method...")
    end

    out = try
        optimize(θ -> negloglik!(θ,M,force=force), start, BFGS(), opts)
    catch err
        err
    end
    ret.optim = out
    if typeof(out)<:Exception || !converged(out)
        setparameters!(M, originalparameters)
        @warn "Optim.optimize did not succeed. Model parameters have not been changed."
        ret.convergence = false
        return ret
    end
    
    if verbose
        println("Approximating the Hessian at the MLE...")
    end
    H = hess(θ -> negloglik!(θ,M), out.minimizer)
    if verbose
        println("Getting standard errors...")
    end
    Hinv = inv(H)
    SE = sqrt.(diag(Hinv))
    
    pvals = zeros(npar)
    CIs = [(0.0, 0.0) for i=1:npar]
    for i = 1:npar
        N = Normal(0,SE[i])
        pvals[i] = 2*(1 - cdf(N, abs(out.minimizer[i])))
        CIs[i] = out.minimizer[i] .+ (quantile(N,0.025), quantile(N,0.975))
    end

    setparameters!(M, out.minimizer)
    ret.estimate = out.minimizer
    ret.se = SE
    ret.pvalues = pvals
    ret.CIs = CIs
    ret.Hinv = Hinv
    ret.convergence = true
    if verbose
        println("...completed successfully.")
    end
    return ret
end


"""
    marginalprobabilities(M::AbstractAutologisticModel;
        indices=1:size(M.unary,2), 
        force::Bool=false
    )

Compute the marginal probability that variables in autologistic model `M` takes the high
state. For a model with n vertices and m observations, returns an n-by-m array 
(or an n-vector if  m==1). The [i,j]th element is the marginal probability of the high state
in the ith variable at the jth observation.  

This function computes the exact marginals. For large models, approximate the marginal 
probabilities by sampling, e.g. `sample(M, ..., average=true)`.

# Arguments
- `indices`: used to return only the probabilities for certain observations.  
- `force`: the function will throw an error for n > 20 unless `force=true`.

# Examples
```jldoctest
julia> M = ALsimple(Graph(3,0), [[-1.0; 0.0; 1.0] [-1.0; 0.0; 1.0]])
julia> marginalprobabilities(M)
3×2 Array{Float64,2}:
 0.119203  0.119203
 0.5       0.5
 0.880797  0.880797
```
"""
function marginalprobabilities(M::AbstractAutologisticModel; indices=1:size(M.unary,2), 
                               force::Bool=false)
    n, m = size(M.unary)
    nc = 2^n
    if n>20 && !force
        error("Attempting to tabulate a PMF with more than 2^20 configurations."
              * "\nIf you really want to do this, set force=true.")
    end
    if minimum(indices)<1 || maximum(indices)>m 
        error("observation index out of bounds")
    end
    hi = M.coding[2]
    out = zeros(n,length(indices))

    tbl = fullPMF(M).table

    for j = 1:length(indices)
        r = indices[j]
        for i = 1:n
            out[i,j] = sum(mapslices(x -> x[i]==hi ? x[n+1] : 0.0, tbl[:,:,r], dims=2))
        end
    end
    if length(indices) == 1
        return vec(out)
    end
    return out
end



# TODO: look for speed gains
"""
    conditionalprobabilities(M::AbstractAutologisticModel; vertices=1:size(M.unary)[1], 
                             indices=1:size(M.unary,2))

Compute the conditional probability that variables in autologistic model `M` take the high
state, given the current values of all of their neighbors. If `vertices` or `indices` are
provided, the results are only computed for the desired variables & observations.  
Otherwise results are computed for all variables and observations.

# Examples
```jldoctest
julia> Y = [ones(9) zeros(9)];
julia> G = makegrid4(3,3).G;
julia> model = ALsimple(G, ones(9,2), Y=Y, λ=0.5);    #-Variables on a 3×3 grid, 2 obs.
julia> conditionalprobabilities(model, vertices=5)    #-Cond. probs. of center vertex.
1×2 Array{Float64,2}:
 0.997527  0.119203

julia> conditionalprobabilities(model, indices=2)     #-Cond probs, 2nd observation.
9×1 Array{Float64,2}:
 0.5
 0.26894142136999516
 0.5
 0.26894142136999516
 0.11920292202211756
 0.26894142136999516
 0.5
 0.26894142136999516
 0.5
```
"""
function conditionalprobabilities(M::AbstractAutologisticModel; vertices=1:size(M.unary,1), 
                                  indices=1:size(M.unary,2))
    n, m = size(M.unary)
    if minimum(vertices)<1 || maximum(vertices)>n 
        error("vertices index out of bounds")
    end
    if minimum(indices)<1 || maximum(indices)>m 
        error("observation index out of bounds")
    end
    out = zeros(Float64, length(vertices), length(indices))
    Y = makecoded(M)
    μ = centeringterms(M)
    lo, hi = M.coding
    adjlist = M.pairwise.G.fadjlist

    for j = 1:length(indices)
        r = indices[j]
        for i = 1:length(vertices)
            v = vertices[i]
            # get neighbor sum
            ns = 0.0
            for ix in adjlist[v]
                ns = ns + M.pairwise[v,ix,r] * (Y[ix,r] - μ[ix,r])
            end
            # get cond prob
            loval = exp(lo*(M.unary[v,r] + ns))
            hival = exp(hi*(M.unary[v,r] + ns))
            if hival == Inf
                out[i,j] = 1.0
            else
                out[i,j] = hival / (loval + hival)
            end
        end
    end
    return out
end


"""
    sample(M::AbstractAutologisticModel, k::Int = 1;
        method::SamplingMethods = Gibbs,
        indices = 1:size(M.unary,2), 
        average::Bool = false, 
        config = nothing, 
        burnin::Int = 0,
        skip::Int = 0,
        verbose::Bool = false
    )

Draws `k` random samples from autologistic model `M`. For a model with `n` vertices in
its graph, the return value is:

- When `average=false`, an `n` × `length(indices)` × `k` array, with singleton dimensions
  dropped. This array holds the random samples.
- When `average=true`, an `n`  × `length(indices)` array, with singleton dimensions dropped.
  This array holds the estimated marginal probabilities of observing the "high" level at 
  each vertex.

# Arguments
- `method`: a member of the enum [`SamplingMethods`](@ref), specifying which sampling
  method will be used.  The default is Gibbs sampling.  Where feasible, it is recommended 
  to use one of the perfect sampling alternatives. See [`SamplingMethods`](@ref) for more.
- `indices`: gives the indices of the observation to use for sampling. If the model has 
  more than one observation, then `k` samples are drawn for each observation's parameter 
  settings. Use `indices` to restrict the samples to a subset of observations. 
- `average`: controls the form of the output. When `average=true`, the return value is the 
  proportion of "high" samples at each vertex. (Note that this is **not** actually the
  arithmetic average of the samples, unless the coding is (0,1). Rather, it is an estimate of 
  the probability of getting a "high" outcome.)  When `average=false`, the full set of
  samples is returned. 
- `config`: allows a starting configuration of the random variables to be provided. Only
  used if `method=Gibbs`. Any vector of the correct length, with two unique values, can be 
  used as `config`. By default a random configuration is used.
- `burnin`: specifies the number of initial samples to discard from the results.  Only used
  if `method=Gibbs`.
- `skip`: specifies how many samples to throw away between returned samples.  Only used 
  if `method=Gibbs`. 
- `verbose`: controls output to the console.  If `true`, intermediate information about 
  sampling progress is printed to the console. Otherwise no output is shown.

# Examples
```jldoctest
julia> M = ALsimple(Graph(4,4));
julia> M.coding = (-2,3);
julia> r = sample(M,10);
julia> size(r)
(4, 10)
julia> sort(unique(r))
2-element Array{Float64,1}:
 -2.0
  3.0
```
"""
function sample(M::AbstractAutologisticModel, k::Int = 1; method::SamplingMethods = Gibbs, 
                indices=1:size(M.unary,2), average::Bool = false, config = nothing, 
                burnin::Int = 0, skip::Int = 0, verbose::Bool = false)
                #NOTE: if keyword argument list changes in future, need to update the tuple
                #      samplenames inside splitkw() to match. 
    
    # Create storage object 
    n, m = size(M.unary)
    nidx = length(indices)
    if k < 1 
        error("k must be positive") 
    end
    if  minimum(indices) < 1 || maximum(indices) > m 
        error("indices must be between 1 and the number of observations")
    end
    if burnin < 0 
        error("burnin must be nonnegative") 
    end
    if average
        out = zeros(Float64, n, nidx)
    else
        out = zeros(Float64, n, nidx, k)
    end
    if method ∈ (perfect_read_once, perfect_reuse_samples, perfect_reuse_seeds) && any(M.pairwise .< 0) 
        @warn "The chosen pefect sampling method isn't theoretically justified for\n" * 
              "negative pairwise values. Samples might still be similar to Gibbs sampling\n" *
              "draws. Consider the pefect_bounding_chain method."
    end

    # Call the sampling function for each index. Give details if verbose=true.
    for i = 1:nidx
        if verbose
            println("== Sampling observation $(indices[i]) ==")
        end
        out[:,i,:] = sample_one_index(M, k, method=method, 
                                      index=indices[i], average=average,
                                      config=config, burnin=burnin, skip=skip, verbose=verbose)
    end

    # Return
    if average
        if nidx==1
            out = dropdims(out,dims=2)
        end
    else
        if nidx==1 && k==1
            out = dropdims(out,dims=(2,3))
        elseif nidx==1
            out = dropdims(out,dims=2)
        elseif k == 1
            out = dropdims(out,dims=3)
        end
    end
    return out

end

function sample_one_index(M::AbstractAutologisticModel, k::Int = 1; 
                     method::SamplingMethods = Gibbs, index::Int = 1, average::Bool = false, 
                     config = nothing, burnin::Int = 0, skip::Int = 0, verbose::Bool = false)
    lo = Float64(M.coding[1])
    hi = Float64(M.coding[2])
    Λ = M.pairwise[:,:,index]   
    α = M.unary[:,index]
    μ = centeringterms(M)[:,index]
    n = length(α)
    adjlist = M.pairwise.G.fadjlist
    if method == Gibbs
        if config == nothing
            Y = rand([lo, hi], n)
        else
            Y = vec(makecoded(makebool(config, M.coding), M.coding))
        end
        return gibbssample(lo, hi, Y, Λ, adjlist, α, μ, n, k, average, burnin, skip, verbose)
    elseif method == perfect_reuse_samples
        return cftp_reuse_samples(lo, hi, Λ, adjlist, α, μ, n, k, average, verbose)
    elseif method == perfect_reuse_seeds
        return cftp_reuse_seeds(lo, hi, Λ, adjlist, α, μ, n, k, average, verbose)
    elseif method == perfect_bounding_chain
        return cftp_bounding_chain(lo, hi, Λ, adjlist, α, μ, n, k, average, verbose)
    elseif method == perfect_read_once
        return cftp_read_once(lo, hi, Λ, adjlist, α, μ, n, k, average, verbose)
    end
end

"""
    makecoded(M::AbstractAutologisticModel)

A convenience method for `makecoded(M.responses, M.coding)`.  Use it to retrieve a model's
responses in coded form.

# Examples
```jldoctest
julia> M = ALRsimple(Graph(4,3), rand(4,2), Y=[true, false, false, true], coding=(-1,1));
julia> makecoded(M)
4×1 Array{Float64,2}:
  1.0
 -1.0
 -1.0
  1.0
```
"""
function makecoded(M::AbstractAutologisticModel)
    return makecoded(M.responses, M.coding)
end
