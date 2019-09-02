"""
    plot(path::RegularizationPath, args...; <keyword arguments>)

Plots a `RegularizationPath` fitted with the `Lasso` package.

The minimum AICc segment is represented by a solid vertical line and the CVmin
and CV1se cross-validation selected segments by dashed vertical lines.

By default it shows nonzero coefficients at the AICc in color and the rest grayed out.

LassoPlot uses Plots.jl, so you can set any supported backend before plotting,
and add any features of the plot afterwards.

# Example:
```julia
    using Lasso, LassoPath, Plots
    path = fit(LassoPath, X, y, dist, link)
    plot(path)
```
# Arguments
- `args...` additional arguments passed to Plots.plot()

# Keywords
- `x=:segment` one of (:segment, :λ, :logλ)
- `varnames=nothing` specify variable names
- `select=:AICc` Selection criteria in (:AICc, :CVmin, :CV1se) for which coefficients
    will be shown in color. The rest are grayed out.
- `showselectors=[:AICc,:CVmin,:CV1se]` shown vertical lines
- `selectedvars=[]` Subset of the variables to present, or empty vector for all
- `kwargs...` additional keyword arguments passed along to fit(GammaLassoPath,...)
"""
function Plots.plot(path::RegularizationPath, args...;
    x=:segment, varnames=nothing, selectedvars=[], select=:AICc, showselectors=[:AICc,:CVmin,:CV1se], nCVfolds=10)
    β=coef(path)
    if hasintercept(path)
        β = β[2:end,:]
    end

    (p,nλ)=size(β)

    if varnames==nothing
        varnames=[Symbol("x$i") for i=1:p]
    end

    indata=DataFrame()
    if x==:λ
        indata[x]=path.λ
    elseif x==:logλ
        indata[x]=log.(path.λ)
    else
        x=:segment
        indata[x]=1:nλ
    end
    outdata = deepcopy(indata)

    # automatic selectors
    # xintercept = Float64[]
    dashed_vlines=Float64[]
    solid_vlines=Float64[]

    if select == :AICc || :AICc in showselectors
        minAICcix=minAICc(path)
        if select == :AICc
            push!(solid_vlines,indata[minAICcix,x])
        else
            push!(dashed_vlines,indata[minAICcix,x])
        end
    end

    if select == :CVmin || :CVmin in showselectors
        gen = Kfold(length(path.m.rr.y),nCVfolds)
        segCVmin = cross_validate_path(path;gen=gen,select=:CVmin)
        if select == :CVmin
            push!(solid_vlines,indata[segCVmin,x])
        else
            push!(dashed_vlines,indata[segCVmin,x])
        end
    end

    if select == :CV1se || :CV1se in showselectors
        gen = Kfold(length(path.m.rr.y),nCVfolds)
        segCV1se = cross_validate_path(path;gen=gen,select=:CV1se)
        if select == :CV1se
            push!(solid_vlines,indata[segCV1se,x])
        else
            push!(dashed_vlines,indata[segCV1se,x])
        end
    end

    if length(selectedvars) == 0
        if select == :all
            selectedvars = 1:p
        elseif select == :AICc
            selectedvars = findall(!iszero, β[:,minAICcix])
        elseif select == :CVmin
            selectedvars = findall(!iszero, β[:,segCVmin])
        elseif select == :CV1se
            selectedvars = findall(!iszero, β[:,segCV1se])
        else
            error("unknown selector $select")
        end
    end

    # colored paths
    for j in selectedvars
        indata[varnames[j]]=Vector(β[j,:])
    end

    # grayed out paths
    for j in setdiff(1:p,selectedvars)
        outdata[varnames[j]]=Vector(β[j,:])
    end

    inmdframe=melt(indata,x)
    outmdframe=melt(outdata,x)
    rename!(inmdframe,:value=>:coefficients)
    rename!(outmdframe,:value=>:coefficients)
    inmdframe = inmdframe[convert(BitArray,map(b->!isnan(b),inmdframe[:coefficients])),:]
    outmdframe = outmdframe[convert(BitArray,map(b->!isnan(b),outmdframe[:coefficients])),:]

    p = plot(xlabel=string(x), ylabel="Coefficient", args...)
    if size(inmdframe,1) > 0
      @df inmdframe plot!(cols(x), :coefficients, group=:variable)
    end
    if size(outmdframe,1) > 0
      @df outmdframe plot!(cols(x), :coefficients, group=:variable, palette=:grays)
    end
    if length(dashed_vlines) > 0
        vline!(dashed_vlines, line = (:dash, 0.5, 2, :black), label="")
    end
    if length(solid_vlines) > 0
        vline!(solid_vlines, line = (:solid, 0.5, 2, :black), label="")
    end

    p
end
