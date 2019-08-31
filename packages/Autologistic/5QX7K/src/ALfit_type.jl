"""
	ALfit

A type to hold estimation output for autologistic models.  Fitting functions return an 
object of this type.

Depending on the fitting method, some fields might not be set.  Fields that are not used
are set to `nothing` or to zero-dimensional arrays.  The fields are:

* `estimate`: A vector of parameter estimates.
* `se`: A vector of standard errors for the estimates.
* `pvalues`: A vector of p-values for testing the null hypothesis that the parameters equal
  zero (one-at-a time hypothesis tests).
* `CIs`: A vector of 95% confidence intervals for the parameters (a vector of 2-tuples).
* `optim`: the output of the call to `optimize` used to get the estimates.
* `Hinv` (used by `fit_ml!`): The inverse of the Hessian matrix of the objective function, 
  evaluated at the estimate.
* `nboot` (`fit_pl!`): number of bootstrap samples to use for error estimation.
* `kwargs` (`fit_pl!`): holds extra keyword arguments passed in the call to the fitting
  function.
* `bootsamples` (`fit_pl!`): the bootstrap samples.
* `bootestimates` (`fit_pl!`): the bootstrap parameter estimates.
* `convergence`: either a Boolean indicating optimization convergence ( for `fit_ml!`), or
  a vector of such values for the optimizations done to estimate bootstrap replicates.

The empty constructor `ALfit()` will initialize an object with all fields empty, so the
needed fields can be filled afterwards.
"""
mutable struct ALfit
    estimate::Vector{Float64}
    se::Vector{Float64}
    pvalues::Vector{Float64}
    CIs::Vector{Tuple{Float64,Float64}}
    optim
    Hinv::Array{Float64,2}
    nboot::Int
    kwargs
    bootsamples
    bootestimates
    convergence
end

# Constructor with no arguments - for object creation. Initialize everything to empty or 
# nothing.
ALfit() = ALfit(zeros(Float64,0),
                zeros(Float64,0),
                zeros(Float64,0),
                Vector{Tuple{Float64,Float64}}(undef,0),
                nothing,
                zeros(Float64,0,0),
                0,
                nothing,
                nothing,
                nothing,
                nothing)


# === show methods =============================================================
show(io::IO, f::ALfit) = print(io, "ALfit")

function show(io::IO, ::MIME"text/plain", f::ALfit)
    print(io, "Autologistic model fitting results. Its non-empty fields are:\n", 
          showfields(f,2), "Use summary(fit; [parnames, sigdigits]) to see a table of estimates.\n",
          "For pseudolikelihood, use oneboot() and addboot!() to add bootstrap after the fact.")
end
                
function showfields(f::ALfit, leadspaces=0)
    spc = repeat(" ", leadspaces)
    out = ""
    if length(f.estimate) > 0
        out *= spc * "estimate       " * 
               "$(size2string(f.estimate)) vector of parameter estimates\n"
    end
    if length(f.se) > 0
        out *= spc * "se             " * 
               "$(size2string(f.se)) vector of standard errors\n"
    end
    if length(f.pvalues) > 0
        out *= spc * "pvalues        " * 
               "$(size2string(f.pvalues)) vector of 2-sided p-values\n"
    end
    if length(f.CIs) > 0
        out *= spc * "CIs            " * 
               "$(size2string(f.CIs)) vector of 95% confidence intervals (as tuples)\n"
    end
    if f.optim !== nothing
        out *= spc * "optim          " * 
               "the output of the call to optimize()\n"
    end
    if length(f.Hinv) > 0
        out *= spc * "Hinv           " * 
               "the inverse of the Hessian, evaluated at the optimum\n"
    end
    if f.nboot > 0
        out *= spc * "nboot          " * 
               "the number of bootstrap replicates drawn\n"
    end
    if f.kwargs !== nothing
        out *= spc * "kwargs         " * 
               "extra keyword arguments passed to sample()\n"
    end
    if f.bootsamples !== nothing
        out *= spc * "bootsamples    " * 
               "$(size2string(f.bootsamples)) array of bootstrap replicates\n"
    end
    if f.bootestimates !== nothing
        out *= spc * "bootestimates  " * 
               "$(size2string(f.bootestimates)) array of bootstrap estimates\n"
    end
    if f.convergence !== nothing
        if length(f.convergence) == 1
            out *= spc * "convergence    " * 
                   "$(f.convergence)\n"
        else
            out *= spc * "convergence    " * 
                   "$(size2string(f.convergence)) vector of convergence flags " * 
                   "($(sum(f.convergence .== false)) false)\n"
        end
    end
    if out == ""
        out = spc * "(all fields empty)\n"
    end
    return out
end
# ==============================================================================

# Line up all strings in rows 2:end of a column of String matrix S, so that a certain
# character (e.g. decimal point or comma) aligns. Do this by prepending spaces.
# After processing, text will line up but strings still might not be all the same length.
function align!(S, col, char)
    nrow = size(S,1)
    locs = findfirst.(isequal(char), S[2:nrow,col])

    # If no char found - make all strings same length
    if all(locs .== nothing)  
        lengths = length.(S[2:nrow,col])
        maxlength = maximum(lengths)
        for i = 2:nrow
            S[i,col] = repeat(" ", maxlength - lengths[i-1]) * S[i,col]
        end
        return
    end

    # Otherwise, align the characters
    maxloc = any(locs .== nothing) ? maximum(length.(S[2:nrow,col])) : maximum(locs)
    for i = 2:nrow
        if locs[i-1] == nothing 
            continue
        end
        S[i,col] = repeat(" ", maxloc - locs[i-1]) * S[i,col]
    end
end

function summary(io::IO, f::ALfit; parnames=nothing, sigdigits=3)
    npar = length(f.estimate)
    if npar==0
        println(io, "No estimates to tabulate")
        return
    end
    if parnames != nothing && length(parnames) !== npar
        error("parnames vector is not the correct length")
    end

    # Create the matrix of strings, and add header row and "p-values" and "CIs" columns 
    # (only include the "p-value" column if it's a ML estimate).
    if f.bootestimates == nothing
        out = Matrix{String}(undef, npar+1, 5)
        out[1,:] = ["name", "est", "se", "p-value", "95% CI"]
        out[2:npar+1, 4] = length(f.pvalues)==0 ? ["" for i=1:npar] : 
                           string.(round.(f.pvalues,sigdigits=sigdigits))
        out[2:npar+1, 5] = length(f.CIs)==0 ? ["" for i=1:npar] : 
                           [string(round.((f.CIs[i][1], f.CIs[i][2]),sigdigits=sigdigits)) for i=1:npar]
        align!(out, 4, '.')
        align!(out, 5, ',')
    else
        out = Matrix{String}(undef, npar+1, 4)
        out[1,:] = ["name", "est", "se", "95% CI"]
        out[2:npar+1, 4] = length(f.CIs)==0 ? ["" for i=1:npar] : 
                           [string(round.((f.CIs[i][1], f.CIs[i][2]),sigdigits=sigdigits)) for i=1:npar]
        align!(out, 4, ',')
    end

    # Fill in the other columns
    for i = 2:npar+1
        out[i,1] = parnames==nothing ? "parameter $(i-1)" : parnames[i-1]
    end        
    out[2:npar+1, 2] = string.(round.(f.estimate,sigdigits=sigdigits))
    out[2:npar+1, 3] = length(f.se)==0 ? ["" for i=1:npar] : 
                       string.(round.(f.se,sigdigits=sigdigits))
    align!(out, 2, '.')
    align!(out, 3, '.')

    nrow, ncol = size(out)
    colwidths = [maximum(length.(out[:,i])) for i=1:ncol]
    for i = 1:nrow
        for j = 1:ncol
            print(io, out[i,j], repeat(" ", colwidths[j]-length(out[i,j])))
            if j < ncol
                print(io, "   ")
            else 
                print(io, "\n")
            end
        end
    end
end

function summary(f::ALfit; parnames=nothing, sigdigits=3)
    summary(stdout, f; parnames=parnames, sigdigits=sigdigits)
end

"""
    addboot!(fit::ALfit, bootsamples::Array{Float64,3}, 
             bootestimates::Array{Float64,2}, convergence::Vector{Bool})

Add parametric bootstrap information in arrays `bootsamples`, `bootestimates`, and
`convergence` to model fitting information `fit`.  If `fit` already contains bootstrap
data, the new data is appended to the existing data, and statistics are recomputed.

# Examples
```jldoctest
julia> using Random;
julia> Random.seed!(1234);
julia> G = makegrid4(4,3).G;
julia> Y=[[fill(-1,4); fill(1,8)] [fill(-1,3); fill(1,9)] [fill(-1,5); fill(1,7)]];
julia> model = ALRsimple(G, ones(12,1,3), Y=Y);
julia> fit = fit_pl!(model, start=[-0.4, 1.1]);
julia> samps = zeros(12,3,10);
julia> ests = zeros(2,10);
julia> convs = fill(false, 10);
julia> for i = 1:10
           temp = oneboot(model, start=[-0.4, 1.1])
           samps[:,:,i] = temp.sample
           ests[:,i] = temp.estimate
           convs[i] = temp.convergence
       end
julia> addboot!(fit, samps, ests, convs)
julia> summary(fit)
name          est     se      95% CI
parameter 1   -0.39   0.442      (-1.09, 0.263)
parameter 2    1.1    0.279   (-0.00664, 0.84)
```
"""
function addboot!(fit::ALfit, 
                  bootsamples::Array{Float64,3}, 
                  bootestimates::Array{Float64,2}, 
                  convergence::Vector{Bool})

    if size(bootsamples,2) == 1
        bootsamples = dropdims(bootsamples, dims=2)
    end
    if fit.bootsamples != nothing
        fit.bootsamples = cat(fit.bootsamples, bootsamples, dims=ndims(bootsamples))
        fit.bootestimates = [fit.bootestimates bootestimates]
        fit.convergence = [fit.convergence; convergence]
    else
        fit.bootsamples = bootsamples
        fit.bootestimates = bootestimates
        fit.convergence = convergence
    end

    ix = findall(convergence)
    if length(ix) < length(convergence)
        println("NOTE: $(length(convergence) - length(ix)) entries have convergence==false.", 
                " Omitting these in calculations.")
    end

    npar = size(bootestimates,1)
    fit.se = std(fit.bootestimates[:,ix], dims=2)[:]
    fit.CIs = [(0.0, 0.0) for i=1:npar]
    for i = 1:npar
        fit.CIs[i] = (quantile(bootestimates[i,ix],0.025), quantile(bootestimates[i,ix],0.975))
    end

end

"""
    addboot!(fit::ALfit, bootresults::Array{T,1}) where 
        T <: NamedTuple{(:sample, :estimate, :convergence)}

An `addboot!` method taking bootstrap data as an array of named tuples. Tuples are of the
form produced by `oneboot`.

# Examples
```jldoctest
julia>     using Random;
julia>     Random.seed!(1234);
julia>     G = makegrid4(4,3).G;
julia>     Y=[[fill(-1,4); fill(1,8)] [fill(-1,3); fill(1,9)] [fill(-1,5); fill(1,7)]];
julia>     model = ALRsimple(G, ones(12,1,3), Y=Y);
julia>     fit = fit_pl!(model, start=[-0.4, 1.1]);
julia>     boots = [oneboot(model, start=[-0.4, 1.1]) for i = 1:10];
julia>     addboot!(fit, boots)
julia>     summary(fit)
name          est     se      95% CI
parameter 1   -0.39   0.442      (-1.09, 0.263)
parameter 2    1.1    0.279   (-0.00664, 0.84)
```
"""
function addboot!(fit::ALfit, bootresults::Array{T,1}) where 
    T <: NamedTuple{(:sample, :estimate, :convergence)}

    nboot = length(bootresults)
    npar = length(bootresults[1].estimate)
    n = size(bootresults[1].sample, 1)
    m = size(bootresults[1].sample, 2) #n,m = size(...) won't work (sample may be 1D or 2D)

    bootsamples = Array{Float64}(undef, n, m, nboot)
    bootestimates = Array{Float64}(undef, npar, nboot)
    convergence = Array{Bool}(undef, nboot)
    for i = 1:nboot
        bootsamples[:,:,i] = bootresults[i].sample
        bootestimates[:,i] = bootresults[i].estimate
        convergence[i] = bootresults[i].convergence
    end

    addboot!(fit, bootsamples, bootestimates, convergence)
end
