
"""
    $(SIGNATURES)

Standardize the length colors used by RoMEPlotting.
"""
function getColorsByLength(len::Int=10)::Vector{String}
  COLORS = String["red";"green";"blue";"black";"deepskyblue";"yellow";"magenta"]
  morecyan = ["cyan" for i in (length(COLORS)+1):len]
  retc = [COLORS; morecyan]
  return retc[1:len]
end

"""
    $(SIGNATURES)

A peneric KDE plotting function that allows marginals of higher dimensional beliefs and various keyword options.

Example:
```julia
p = kde!(randn(3,100))

plotKDE(p)
plotKDE(p, dims=[1;2], levels=3)
plotKDE(p, dims=[1])

q = kde!(5*randn(3,100))
plotKDE([p;q])
plotKDE([p;q], dims=[1;2], levels=3)
plotKDE([p;q], dims=[1])
```
"""
function plotKDE(fgl::G,
                 sym::Symbol;
                 dims=nothing,
                 title="",
                 levels::Int=5,
                 fill::Bool=false,
                 layers::Bool=false  ) where G <: AbstractDFG
  #
  p = getKDE(getVariable(fgl,sym))
  # mmarg = length(marg) > 0 ? marg : collect(1:Ndim(p))
  # mp = marginal(p,mmarg)
  plotKDE(p, levels=levels, dims=dims, title=string(sym, "  ", title), fill=fill, layers=layers )
end
function plotKDE(fgl::G,
                 syms::Vector{Symbol};
                 addt::Vector{BallTreeDensity}=BallTreeDensity[],
                 dims=nothing,
                 title=nothing,
                 levels=3,
                 layers::Bool=false  ) where G <: AbstractDFG
  #
  # TODO -- consider automated rotisary of color
  # colors = ["black";"red";"green";"blue";"cyan";"deepskyblue"; "yellow"]
  # COLORS = repmat(colors, 10)
  COLORS = getColorsByLength(length(syms))
  MP = BallTreeDensity[]
  LEG = String[]
  # mmarg = Int[]
  for sym in syms
    p = getKDE(getVariable(fgl,sym))
    # mmarg = length(marg) > 0 ? marg : collect(1:Ndim(p))
    # mp = marginal(p,mmarg)
    push!(MP, p)
    push!(LEG, string(sym))
  end
  for p in addt
    # mp = marginal(p,mmarg)
    push!(MP, p)
    push!(LEG, "add")
  end
  plotKDE(MP,c=COLORS[1:length(MP)], levels=levels, dims=dims, legend=LEG, title=title, layers=layers)
end



"""
    $(SIGNATURES)

Plot absolute values of variables and measurement surrounding fsym factor.
"""
function plotKDEofnc(fgl::G,
                     fsym::Symbol;
                     marg=nothing,
                     N::Int=100  ) where G <: AbstractDFG
  #
  fnc = nothing
  if haskey(fgl.fIDs, fsym)
    fnc = getfnctype( fgl, fgl.fIDs[fsym] )
  else
    error("fIDs doesn't have $(fsym)")
  end
  p = kde!( getSample(fnc, N)[1]  )
  # mmarg = length(marg) > 0 ? marg : collect(1:Ndim(p))
  plotKDE(fgl, lsf(fgl, fsym), addt=[p], marg=marg)
end

"""
    $(SIGNATURES)

Try plot relative values of variables and measurement surrounding fsym factor.
"""
function plotKDEresiduals(fgl::G,
                          fsym::Symbol;
                          N::Int=100,
                          levels::Int=3,
                          dims=nothing,
                          fill=false  ) where G <: AbstractDFG
  #
  # COLORS = ["black";"red";"green";"blue";"cyan";"deepskyblue"]
  fnc = getfnctype( fgl, fgl.fIDs[fsym] )
  # @show sxi = lsf(fgl, fsym)[1]
  # @show sxj = lsf(fgl, fsym)[2]
  fct = getFactor(fgl, fsym)
  @show sxi = getData(fct).fncargvID[1]
  @show sxj = getData(fct).fncargvID[2]
  xi = getVal(fgl, sxi)
  xj = getVal(fgl, sxj)
  measM = getSample(fnc, N)
  meas = length(measM) == 1 ? (0*measM[1], ) : (0*measM[1], measM[2])
  @show size(meas[1])
  d = size(measM[1],1)
  RES = zeros(d,N)
  for i in 1:N
    res = zeros(d)
    fnc(res, i, meas, xi, xj)
    RES[:,i] = res
    if length(measM) > 1
      if measM[2][i] == 0
        RES[:,i] = 0.5*randn(d)
      end
    end
  end
  pR = kde!(RES)
  pM = kde!(measM[1])
  fncvar = getfnctype(fct)

  COLORS = getColorsByLength()
  plotKDE([pR;pM], c=COLORS[1:2], dims=dims,levels=3, legend=["residual";"model"], fill=fill, title=string(fsym, ", ", fncvar))
end

"""
    $(SIGNATURES)

Plot the product of priors and incoming upward messages for variable in clique.

plotPriorsAtCliq(tree, :x2, :x1[, marg=[1;2]])
"""
function plotPriorsAtCliq(tree::BayesTree,
                          lb::Symbol,
                          cllb::Symbol;
                          dims::Vector{Int}=Int[],
                          levels::Int=1,
                          fill::Bool=false  )
  #
  # COLORS = ["black";"red";"green";"blue";"cyan";"deepskyblue"]

  cliq = whichCliq(tree, cllb)
  cliqprs = cliq.attributes["debug"].priorprods[1]

  vidx = 1
  for lbel in cliqprs.lbls
    if lbel == lb
      break;
    else
      vidx += 1
    end
  end
  dims = length(dims)>0 ? dims : collect(1:size(cliqprs.prods[vidx].prev,1))

  arr = BallTreeDensity[]
  push!(arr, marginal(kde!(cliqprs.prods[vidx].prev), dims)  )
  push!(arr, marginal(kde!(cliqprs.prods[vidx].product), dims)  )
  len = length(cliqprs.prods[vidx].potentials)
  lg = String["p";"n"]
  i=0
  for pot in cliqprs.prods[vidx].potentials
    push!(arr, marginal(pot, dims)  )
    i+=1
    push!(lg, cliqprs.prods[vidx].potentialfac[i])
  end

  COLORS = getColorsByLength(len+2)
  # cc = COLORS[1:(len+2)]
  plotKDE(arr, c=COLORS, legend=lg, levels=levels, fill=fill );
end


"""
    $(SIGNATURES)

Draw the up pass belief of lb from clique cllb.

plotUpMsgsAtCliq(tree, :x2, :x1)
"""
function plotUpMsgsAtCliq(treel::BayesTree, lb::Symbol, cllb::Symbol;
      show::Bool=true,
      w=20cm, h=15cm,
      levels::Int=1,
      marg::Vector{Int}=Int[] )
  #
  cliq = whichCliq(treel, string(cllb))
  cliqoutmsg = cliq.attributes["debug"].outmsg
  lbls = cliq.attributes["debug"].outmsglbls

  bel = kde!(cliqoutmsg.p[lbls[lb]])
  bel = length(marg)==0 ? bel : marginal(bel, marg)

  plotKDE(bel)
end

function plotMCMC(treel::BayesTree,
                  lbll::Symbol;
                  delay::Int=200,
                  show::Bool=true,
                  w=20cm, h=15cm,
                  levels::Int=1,
                  dims=nothing  )
  #
  cliq = whichCliq(treel, string(lbll))
  cliqdbg = cliq.attributes["debug"]

  vidx = 1
  for lb in cliqdbg.mcmc[1].lbls
    if lb == lbll
      break;
    else
      vidx += 1
    end
  end

  tmpfilepath = joinpath(dirname(@__FILE__),"tmpimgs")
  ARR = BallTreeDensity[]
  COLORS = getColorsByLength()
  # COLORS = ["black";"red";"green";"blue";"cyan";"deepskyblue";"magenta"]
  for i in 1:length(cliqdbg.mcmc)
    ppr = kde!(cliqdbg.mcmc[i].prods[vidx].prev)
    ppp = kde!(cliqdbg.mcmc[i].prods[vidx].product)
    ARR = [ARR;ppr;ppr;cliqdbg.mcmc[i].prods[vidx].potentials]
  end
  rangeV = getKDERange(ARR)
  ppp = nothing
  for i in 1:length(cliqdbg.mcmc)
    ppr = kde!(cliqdbg.mcmc[i].prods[vidx].prev)
    ppp = kde!(cliqdbg.mcmc[i].prods[vidx].product)
    arr = [ppr;ppp;cliqdbg.mcmc[i].prods[vidx].potentials]
    len = length(cliqdbg.mcmc[i].prods[vidx].potentials)
    lg = String["p";"n";cliqdbg.mcmc[i].prods[vidx].potentialfac] #map(string, 1:len)]
    COLORS_l = getColorsByLength(len+2)
    cc = plotKDE(arr, c=COLORS_l, legend=lg, levels=levels, fill=true, axis=rangeV, dims=dims );
    Gadfly.draw(PNG(joinpath(tmpfilepath,"$(string(lbll))mcmc$(i).png"),w,h),cc)
  end
  # draw initial and final result
  pp0 = kde!(cliqdbg.mcmc[1].prods[vidx].prev)
  i = 0
  cc = plotKDE([pp0], c=[COLORS[1]], legend=["0"], levels=levels, fill=true, axis=rangeV, dims=dims );
  Gadfly.draw(PNG(joinpath(tmpfilepath,"$(string(lbll))mcmc$(i).png"),w,h),cc)

  i = length(cliqdbg.mcmc)+1
  cc = plotKDE([pp0;ppp], c=COLORS[1:2], legend=["0";"n"], levels=levels, fill=true, axis=rangeV, dims=dims );
  Gadfly.draw(PNG(joinpath(tmpfilepath,"$(string(lbll))mcmc$(i).png"),w,h),cc)
  # generate output
  run(`convert -delay $(delay) $(tmpfilepath)/$(string(lbll))mcmc*.png $(tmpfilepath)/$(string(lbll))mcmc.gif`)
  !show ? nothing : (@async run(`eog $(tmpfilepath)/$(string(lbll))mcmc.gif`) )
  return "$(tmpfilepath)/$(string(lbll))mcmc.gif"
end

function drawOneMC!(cliqMC::CliqGibbsMC, minmax, mcmc=0; offs=2.0)

    if mcmc>minmax[4]
      minmax[4]=mcmc
    end

    i = 0.0
    for prod in cliqMC.prods
        prodVal = kde!(prod.product,"lcv")
        plotKDEProd!([prodVal;prod.potentials],minmax, h=-i*offs, mcmc=mcmc)
        i += 1.0
    end

end

function drawMCMCDebug(cliq; offs=2.0)
    println("$(cliq.attributes["label"])")
    cliqDbg = cliq.attributes["data"].debug
    MCd = 100.0/length(cliqDbg.mcmc)
    MCo=0.0
    minmax=[99999,-99999,-10,-99999.0]
    for mc in cliqDbg.mcmc
        drawOneMC!(mc, minmax, MCo, offs=offs)
        MCo+=MCd
    end

    n = 3
    y = linspace(minmax[1], minmax[2], n)
    x = linspace(minmax[3],minmax[4],n)
    xgrid = repmat(x',n,1)
    ygrid = repmat(y,1,n)
    z = zeros(n,n)

    for i in 1:length(cliqDbg.mcmc[1].prods)
      surf(xgrid,ygrid,z-(i-1)*offs,alpha=0.04, linewidth=0.0)
    end
end


function drawTreeUpwardMsgs(fgl::G,
                            bt::BayesTree;
                            N=300 ) where G <: AbstractDFG
  #
  len = length(bt.cliques)-1
  vv = Array{Gadfly.Compose.Context,1}(undef, len)
  #r = Array{RemoteRef,1}(len)
  i = 0
  for cliq in bt.cliques
      if cliq[1] == 1 println("No upward msgs from root."); continue; end
      @show cliq[2].attributes["label"]
      i+=1
      vv[i] = drawHorDens(fgl, cliq[2].attributes["debug"].outmsg.p, N)
  end
  #[r[j] = @spawn drawCliqueMsgs(bt.cliques[j+1]) for j in 1:len]
  #[vv[j] = fetch(r[j]) for j in 1:len]
  vv
end

function drawFrontalDens(fg::G,
                         bt::BayesTree;
                         N=300,
                         gt=Union{} ) where G <: AbstractDFG
    #
    len = length(bt.cliques)
    vv = Array{Gadfly.Compose.Context,1}(len)
    i = 0
    for cliq in bt.cliques
        #@show cliq[2].attributes["label"]
        lenfr = length(cliq[2].attributes["data"].frontalIDs)

        p = Array{BallTreeDensity,1}(lenfr)
        j=0
        #pvals = Array{Array{Float64,2},1}(lenfr)
        gtvals = Dict{Int,Array{Float64,2}}()
        lbls = String[]

        for frid in cliq[2].attributes["data"].frontalIDs
            j+=1
            p[j] = getKDE(getVariable(fg, frid)) # getKDE(fg.v[frid])
            # p[j] = kde!(fg.v[frid].attributes["val"])

            #pvals[j] = fg.v[frid].attributes["val"]

            if gt!=Union{}
              gtvals[j] = gt[getVariable(fg,frid).label] # fg.v[frid].
              #push!(gtvals, gt[fg.v[frid].attributes["label"]][1])
              #push!(gtvals, gt[fg.v[frid].attributes["label"]][2])
            end
            push!(lbls, getVariable(fg,frid).label) # fg.v[frid].

        end

        #r = Array{RemoteRef,1}(lenfr)
        #[r[j] = @spawn kde!(pvals[j]) for j in 1:lenfr]
        #[p[j] = fetch(r[j]) for j in 1:lenfr]

        i+=1
        if length(gtvals) > 0
          #gtvals = reshape(gtvals,2,round(Int,length(gtvals)/2))'
          vv[i] = drawHorDens(p, N, gt=gtvals, lbls=lbls)
        else
          vv[i] = drawHorDens(p, N,lbls=lbls)
        end
    end

    #r = Array{RemoteRef,1}(lenfr)
    #[r[j] = @spawn kde!(pvals[j]) for j in 1:lenfr]
    #[p[j] = fetch(r[j]) for j in 1:lenfr]

    i+=1
    if length(gtvals) > 0
      #gtvals = reshape(gtvals,2,round(Int,length(gtvals)/2))'
      vv[i] = drawHorDens(p, N, gt=gtvals, lbls=lbls)
    else
      vv[i] = drawHorDens(p, N,lbls=lbls)
    end
  #
  return vv
end

# for some reason we still need msgPlots of right size in the global for these functions to work.
# precall drawTreeUpwardMsgs or drawFrontalDens to make this work properly TODO
function vstackedDensities(msgPlots)
    #msgPlots = f(fg, bt) # drawTreeUpwardMsgs
    evalstr = ""
    for i in 1:length(msgPlots)
        evalstr = string(evalstr, ",msgPlots[$(i)]")
    end
    eval(parse(string("vstack(",evalstr[2:end],")")))
end

function investigateMultidimKDE(p::BallTreeDensity, p0::BallTreeDensity)
    co = ["black"; "blue"]
    h = Union{}
    x = plotKDE([marginal(p,[1]); marginal(p0,[1])], c=co )
    y = plotKDE([marginal(p,[2]); marginal(p0,[2])], c=co )
    if p.bt.dims >= 3
      th = plotKDE([marginal(p,[3]); marginal(p0,[3])], c=co )
      h = hstack(x,y,th)
    else
      h = hstack(x,y)
    end

    return h
end


function investigateMultidimKDE(p::Array{BallTreeDensity,1})
    co = ["black"; "blue"; "green"; "red"; "magenta"; "cyan"; "cyan1"; "cyan2";
    "magenta"; "cyan"; "cyan1"; "cyan2"; "magenta"; "cyan"; "cyan1"; "cyan2"; "magenta";
    "cyan"; "cyan1"; "cyan2"; "magenta"; "cyan"; "cyan1"; "cyan2"]
    # compute all the marginals
    Pm = Array{Array{BallTreeDensity,1},1}()
    push!(Pm,stackMarginals(p,1)) #[marginal(p[1],[1]); marginal(p[2],[1])]
    push!(Pm,stackMarginals(p,2)) #[marginal(p[1],[2]); marginal(p[2],[2])]

    h = Union{}
    x = plotKDE(Pm[1], c=co )
    y = plotKDE(Pm[2], c=co )
    if p[1].bt.dims >= 3
      #Pm3 = [marginal(p[1],[3]); marginal(p[2],[3])]
      push!(Pm,stackMarginals(p,3)) # [marginal(p[1],[3]); marginal(p[2],[3])]
      th = plotKDE(Pm[3], c=co )
      h = hstack(x,y,th)
    else
      h = hstack(x,y)
    end
    return h
end

function investigateMultidimKDE(p::BallTreeDensity)
    x = plotKDE(marginal(p,[1]) )
    y = plotKDE(marginal(p,[2]) )
    if p.bt.dims >= 3
      th = plotKDE(marginal(p,[3]) )
      return hstack(x,y,th)
    end
    return hstack(x,y)
end

function vArrPotentials(potens::Dict{Symbol,EasyMessage})
  vv = Array{Gadfly.Compose.Context,1}(length(potens))
  i = 0
  oned=false
  for p in potens
      i+=1
      pb = kde!(p[2].pts, p[2].bws)
      if size(p[2].pts,1) > 3
        # vv[i] = plotKDE(pb)
        error("can't handle higher dimensional plots here yet")
      elseif size(p[2].pts,1) > 1
        vv[i] = investigateMultidimKDE(pb)
      else
        vv[i] = plotKDE(pb)
      end
  end
  return vv
end


function draw(em::EasyMessage;xlbl="X")
  p = Union{}
  if size(em.pts,1) == 1
    p=plotKDE(kde!(em),xlbl=xlbl)
  else
    p=plotKDE(kde!(em))
  end
  return p
end

function whosWith(cliq::Graphs.ExVertex)
  println("$(cliq.attributes["label"])")
  for pot in cliq.attributes["data"].potentials
      println("$(pot)")
  end
  nothing
end

function whosWith(bt::BayesTree, frt::String)
    whosWith(whichCliq(bt,frt))
end


function drawUpMsgAtCliq(fg::G,
                         cliq::Graphs.ExVertex  ) where G <: AbstractDFG
  #
  for id in keys(cliq.attributes["data"].debug.outmsg.p)
      print("$(getVariable(fg,id).label), ") #fg.v[id].
  end
  println("")
  sleep(0.1)
  potens = getData(cliq).debug.outmsg.p
  vArrPotentials(potens)
end

function drawUpMsgAtCliq(fg::G,
                         bt::BayesTree,
                         lbl::Union{String,Symbol}  ) where G <: AbstractDFG
  #
  drawUpMsgAtCliq(fg, whichCliq(bt, Symbol(lbl)) )
end

# function drawDwnMsgAtCliq(fg::FactorGraph, cliq::Graphs.ExVertex)
function dwnMsgsAtCliq(fg::G,
                       cliq::Graphs.ExVertex  ) where G <: AbstractDFG
  #
  for id in keys(cliq.attributes["data"].debugDwn.outmsg.p)
      print("$(getVariable(fg,id).label), ") # fg.v[id].
  end
  println("")
  sleep(0.1)
  potens = cliq.attributes["data"].debugDwn.outmsg.p
  potens
end

function dwnMsgsAtCliq(fg::G,
                       bt::BayesTree,
                       lbl::Union{String,Symbol}  ) where G <: AbstractDFG
  #
  dwnMsgsAtCliq(fg, whichCliq(bt, Symbol(lbl)) )
end

function drawPose2DMC!(plots::Array{Gadfly.Compose.Context,1},
                       cliqMC::CliqGibbsMC )
  #
  for prod in cliqMC.prods
    prodVal = kde!(prod.product, "lcv") #cliqMC.prods[1]
    push!(plots, plotKDE([prodVal;prod.potentials]) )
  end
  vstackedPlots(plots)
end

function mcmcPose2D!(plots::Array{Gadfly.Compose.Context,1},
                     cliqDbg::DebugCliqMCMC,
                     iter::Int=1  )
    # for mc in cliqDbg.mcmc
    mc = cliqDbg.mcmc[iter]
    v = drawPose2DMC!(plots, mc)
    # end
    return v
end

function drawUpMCMCPose2D!(plots::Array{Gadfly.Compose.Context,1},
                           cliq::Graphs.ExVertex,
                           iter::Int=1 )
  #
  whosWith(cliq)
  cliqDbg = cliq.attributes["data"].debug
  sleep(0.1)
  mcmcPose2D!(plots, cliqDbg, iter)
end

function drawUpMCMCPose2D!(plots::Array{Gadfly.Compose.Context,1},
                           bt::BayesTree,
                           frt::String,
                           iter::Int=1 )
  #
  drawUpMCMCPose2D!(plots, whichCliq(bt,frt), iter)
end

function drawDwnMCMCPose2D!(plots::Array{Gadfly.Compose.Context,1},
                            cliq::Graphs.ExVertex,
                            iter::Int=1  )
  #
  whosWith(cliq)
  cliqDbg = cliq.attributes["data"].debugDwn
  sleep(0.1)
  mcmcPose2D!(plots, cliqDbg, iter)
end

function drawDwnMCMCPose2D!(plots::Array{Gadfly.Compose.Context,1},
                            bt::BayesTree,
                            frt::String,
                            iter::Int=1 )
  #
  drawDwnMCMCPose2D!(plots, whichCliq(bt,frt), iter)
end

function drawLbl(fgl::G, lbl::Symbol) where G <: AbstractDFG
    plotKDE(getKDE(getVariable(fgl,lbl)))
end
drawLbl(fgl::G, lbl::T) where {G <: AbstractDFG, T <: AbstractString} = drawLbl(fgl, Symbol(lbl))

function predCurrFactorBeliefs(fgl::G,
                               fc::Graphs.ExVertex  ) where G <: AbstractDFG
  #
  # TODO update to use ls and lsv functions
  prjcurvals = Dict{String, Array{BallTreeDensity,1}}()
  for v in getNeighbors(fgl, fc)
    pred = kde!(evalFactor2(fgl, fc, v.index))
    curr = kde!(getVal(v))
    prjcurvals[v.attributes["label"]] = [curr; pred]
  end
  return prjcurvals, collect(keys(prjcurvals))
end


function drawHorDens(fgl::G,
                     pDens::Dict{Int,EasyMessage},
                     N=200 ) where G <: AbstractDFG
  #
  p = BallTreeDensity[]
  lbls = String[]
  for pd in pDens
    push!(p, kde!(pd[2].pts,pd[2].bws))
    push!(lbls, getVariable(fgl,pd[1]).label)
  end
  drawHorDens(p,N=N,lbls=lbls)
end

function drawHorBeliefsList(fgl::G,
                            lbls::Array{Symbol,1};
                            nhor::Int=-1,
                            gt=nothing,
                            N::Int=200,
                            extend=0.1  ) where G <: AbstractDFG
  #
  len = length(lbls)
  pDens = BallTreeDensity[]
  for lb in lbls
    ptkde = getKDE(getVariable(fgl,lb))
    push!(pDens, ptkde )
  end

  if nhor<1
    nhor = round(Int,sqrt(len))
  end
  vlen = ceil(Int, len/nhor)
  vv = Array{Gadfly.Compose.Context,1}(vlen)
  conslb = deepcopy(lbls)
  vidx = 0
  for i in 1:nhor:len
    pH = BallTreeDensity[]
    gtvals = Dict{Int,Array{Float64,2}}()
    labels = String[]
    for j in 0:(nhor-1)
      if i+j <= len
        push!(pH, pDens[i+j])
        push!(labels, string(lbls[i+j]))
        if gt != nothing gtvals[j+1] = gt[lbls[i+j]]  end
      end
    end
    vidx+=1
    if gt !=nothing
      vv[vidx] = KernelDensityEstimatePlotting.drawHorDens(pH, N=N, gt=gtvals, lbls=labels, extend=extend)
    else
      vv[vidx] = KernelDensityEstimatePlotting.drawHorDens(pH, N=N, lbls=labels, extend=extend)
    end
  end
  vv
end

function drawFactorBeliefs(fgl::G,
                           flbl::Symbol ) where G <: AbstractDFG
  #
  if !haskey(fgl.fIDs, flbl)
    println("no key $(flbl)")
    return nothing
  end
  # for fc in fgl.f
    # if fc[2].attributes["label"] == flbl

    fc = fgl.g.vertices[fgl.fIDs[flbl]]  # fc = fgl.f[fgl.fIDs[flbl]]
      prjcurvals, lbls = predCurrFactorBeliefs(fgl, fc)
      if length(lbls) == 3
        return vstack(
        plotKDE(prjcurvals[lbls[1]]),
        plotKDE(prjcurvals[lbls[2]]),
        plotKDE(prjcurvals[lbls[3]]),
        )
      elseif length(lbls) == 2
        return vstack(
        plotKDE(prjcurvals[lbls[1]]),
        plotKDE(prjcurvals[lbls[2]]),
        )
      elseif length(lbls) == 1
        return plotKDE(prjcurvals[lbls[1]])
      end

    # end
  # end
  nothing
end
drawFactorBeliefs(fgl::G, flbl::T) where {G <: AbstractDFG, T <: AbstractString} = drawFactorBeliefs(fgl, Symbol(flbl))


"""
    $(SIGNATURES)

Plot the proposal belief from neighboring factors to `lbl` in the factor graph (ignoring Bayes tree representation),
and show with new product approximation for reference.
"""
function plotLocalProduct(fgl::G,
                          lbl::Symbol;
                          N::Int=100,
                          dims::Vector{Int}=Int[],
                          levels::Int=1,
                          show=true,
                          dirpath="/tmp/",
                          mimetype::AbstractString="svg",
                          sidelength=20cm,
                          title::String="Local product, "  ) where G <: AbstractDFG
  #
  @warn "not showing partial constraints, but included in the product"
  arr = Array{BallTreeDensity,1}()
  lbls = String[]
  push!(arr, getKDE(getVariable(fgl, lbl)))
  push!(lbls, "curr")
  pl = nothing
  pp, parr, partials, lb = IncrementalInference.localProduct(fgl, lbl, N=N)
  if length(parr) > 0 && length(partials) == 0
    if pp != parr[1]
      push!(arr,pp)
      push!(lbls, "prod")
      for a in parr
        push!(arr, a)
      end
      @show lb, lbls
      lbls = union(lbls, string(lb))
    end
    dims = length(dims) > 0 ? dims : collect(1:Ndim(pp))
    colors = getColorsByLength(length(arr))
    pl = plotKDE(arr, dims=dims, levels=levels, c=colors, title=string(title,lbl), legend=string.(lbls)) #
  elseif length(parr) == 0 && length(partials) > 0
    # stack 1d plots to accomodate all the partials
    PL = []
    lbls = String["prod";"curr";lb]
    pdims = sort(collect(keys(partials)))
    for dimn in pdims
      vals = partials[dimn]
      proddim = marginal(pp, [dimn])
      colors = getColorsByLength(length(vals)+2)
      pl = plotKDE([proddim;getKDE(getVariable(fgl, lbl));vals], dims=[1;], levels=levels, c=colors, title=string("Local product, dim=$(dimn), ",lbl))
      push!(PL, pl)
    end
    pl = Gadfly.vstack(PL...)
  else
    return error("plotLocalProduct not built for lengths parr, partials = $(length(parr)), $(length(partials)) yet.")
  end

  # now let's export:
  backend = getfield(Gadfly, Symbol(uppercase(mimetype)))
  Gadfly.draw(backend(dirpath*"test_$(lbl).$(mimetype)",sidelength,0.75*sidelength), pl)
  driver = mimetype in ["pdf"] ? "evince" : "eog"
  show ? (@async run(`$driver $(dirpath)test_$(lbl).$(mimetype)`)) : nothing

  return pl
end


"""
    $(SIGNATURES)

Plot---for the cylindrical manifold only---the proposal belief from neighboring factors to `lbl` in the factor graph (ignoring Bayes tree representation),
and show with new product approximation for reference.  The linear and circular belief products are returned as a tuple.
"""
function plotLocalProductCylinder(fgl::G,
                                  lbl::Symbol;
                                  N::Int=100,
                                  levels::Int=1,
                                  show=true,
                                  dirpath="/tmp/",
                                  mimetype::AbstractString="svg",
                                  sidelength=30cm,
                                  scale::Float64=0.2 ) where G <: AbstractDFG
  #
  @warn "not showing partial constraints, but included in the product"
  arr = Array{BallTreeDensity,1}()
  carr = Array{BallTreeDensity,1}()
  lbls = String[]
  push!(arr, getKDE(getVariable(fgl, lbl)))
  push!(lbls, "curr")
  pl = nothing
  plc = nothing
  pp, parr, partials, lb = IncrementalInference.localProduct(fgl, lbl, N=N)
  if length(parr) > 0 && length(partials) == 0
    if pp != parr[1]
      push!(arr, marginal(pp,[1]))
      push!(lbls, "prod")
      push!(carr, marginal(pp, [2]))
      for a in parr
        push!(arr, marginal(a,[1]))
        push!(carr, marginal(a,[2]))
      end
      lbls = union(lbls, lb)
    end
    colors = getColorsByLength(length(arr))
    pll = plotKDE(arr, dims=[1;], levels=levels, c=colors, legend=lbls, title=string("Local product, ",lbl))
    plc = AMP.plotKDECircular(carr, c=colors, scale=scale)
    # (pll, plc)
  elseif length(parr) == 0 && length(partials) > 0
    # stack 1d plots to accomodate all the partials
    PL = []
    PLC = []
    lbls = ["prod";"curr";lb]
    pdims = sort(collect(keys(partials)))
    for dimn in pdims
      vals = partials[dimn]
      proddim = marginal(pp, [dimn])
      colors = getColorsByLength(length(vals)+2)
      if dimn == 1
        pll = plotKDE([proddim;getKDE(getVariable(fgl, lbl));vals], dims=[1;], levels=levels, c=colors, title=string("Local product, dim=$(dimn), ",lbl))
        push!(PL, pl)
      else
        plc = AMP.plotKDECircular([proddim; marginal(getKDE(getVariable(fgl, lbl)),[2]);vals], c=colors, scale=scale)
        push!(PLC, plc)
      end
    end
    pl = Gadfly.vstack(PL..., PLC...)
  else
    return error("plotLocalProduct not built for lengths parr, partials = $(length(parr)), $(length(partials)) yet.")
  end

  # now let's export:
  # backend = getfield(Gadfly, Symbol(uppercase(mimetype)))
  # Gadfly.draw(backend(dirpath*"test_$(lbl).$(mimetype)",sidelength,sidelength), pl)
  # driver = mimetype in ["pdf"] ? "evince" : "eog"
  # show ? (@async run(`$driver $(dirpath)test_$(lbl).$(mimetype)`)) : nothing

  return pll, plc
end


"""
    $SIGNATURES

Plot the proposal belief from neighboring factors to `lbl` in the factor graph (ignoring Bayes tree representation),
and show with new product approximation for reference. String version is obsolete and will be deprecated.
"""
plotLocalProduct(fgl::G, lbl::T; N::Int=100, dims::Vector{Int}=Int[]) where {G <: AbstractDFG, T <: AbstractString} = plotLocalProduct(fgl, Symbol(lbl), N=N, dims=dims)

"""
    $SIGNATURES

Project (convolve) to and take product of variable in Bayes/Junction tree.

Notes
- assume cliq and var sym the same, unless both specified.
- `cliqsym` defines a frontal variable of a clique.
"""
function plotTreeProductUp(fgl::G,
                           treel::BayesTree,
                           cliqsym::Symbol,
                           varsym::Symbol=cliqsym  ) where G <: AbstractDFG
  #
  # build a subgraph copy of clique
  cliq = whichCliq(treel, cliqsym)
  syms = getCliqAllVarSyms(fgl, cliq)
  subfg = buildSubgraphFromLabels(fgl,syms)

  # add upward messages to subgraph
  msgs = getCliqChildMsgsUp(treel,cliq, BallTreeDensity)
  # @show typeof(msgs)
  addMsgFactors!(subfg, msgs)

  # predictBelief
  # stuff = treeProductUp(fgl, treel, cliqsym, varsym)
  # plotKDE(manikde!(stuff[1], getManifolds(fgl, varsym)))
  cllbl = cliq.attributes["label"]
  return plotLocalProduct(subfg, varsym, title="Tree Up $(cllbl) | ")
end


function plotTreeProductDown(fgl::G,
                             treel::BayesTree,
                             cliqsym::Symbol,
                             varsym::Symbol=cliqsym  ) where G <: AbstractDFG
  #
  # build a subgraph copy of clique
  cliq = whichCliq(treel, cliqsym)
  syms = getCliqAllVarSyms(fgl, cliq)
  subfg = buildSubgraphFromLabels(fgl,syms)

  # add upward messages to subgraph
  msgs = getCliqParentMsgDown(treel,cliq)
  addMsgFactors!(subfg, msgs)

  # predictBelief
  # stuff = treeProductUp(fgl, treel, cliqsym, varsym)
  # plotKDE(manikde!(stuff[1], getManifolds(fgl, varsym)))
  cllbl = cliq.attributes["label"]
  return plotLocalProduct(subfg, varsym, title="Tree Dwn $(cllbl) | ")
end


function saveplot(pl;name="pl",frt=:png,w=25cm,h=25cm,nw=false,fill=true)
  if frt==:png
    Gadfly.draw(PNG(string(name,".png"),w,h),pl)
    # if fill run(`composite $(name).png plB.png $(name).png`) end
    if !nw run(`eog $(name).png`) end
  end
  if frt==:pdf
    Gadfly.draw(PDF(string(name,".pdf"),w,h),pl)
    if !nw run(`evince $(name).pdf`) end
  end
  nothing
end

function animateVertexBelief(FGL::Array{<:AbstractDFG,1}, lbl; nw=false)
  len = length(FGL)
  [saveplot(plotLocalProduct(FG[i],lbl),h=15cm,w=30cm,name="gifs/pl$(i)",nw=true) for i=1:len];
  run(`convert -delay 100 gifs/pl'*'.png result.gif`)
  if !nw run(`eog result.gif`) end
  nothing
end

function fixRotWrapErr!(RT::Array{Float64,1})

  for i in 1:length(RT)
    if RT[i] > pi
      RT[i] = abs(RT[i]-2.0*pi)
    end
  end
  nothing
end

function asyncUniComp(fgl::G, isamdict::Dict{Int,Array{Float64,1}}) where G <: AbstractDFG
  r,rt,lb = computeGraphResiduals(fgl,isamdict);
  fixRotWrapErr!(rt)
  return [sqrt(mean(r.^2));maximum(abs(r));sqrt(mean(rt.^2));maximum(rt)]
end

function unimodalCompare(FGL::Array{<:AbstractDFG,1},isamdict::Dict{Int,Array{Float64,1}})
  len = length(FGL)
  RMS = Float64[]
  MAX = Float64[]
  RMSth = Float64[]
  MAXth = Float64[]

  rr = Future[] #RemoteRef[]

  for fgl in FGL
    push!(rr, remotecall(uppA(),asyncUniComp, fgl, isamdict))
  end

  for r in rr
    err = fetch(r)
    push!(RMS, err[1])
    push!(MAX, err[2])
    push!(RMSth, err[3])
    push!(MAXth, err[4])
  end

  x=0:(len-1)
  df1 = DataFrame(x=x, y=RMS, label="rms")
  df2 = DataFrame(x=x, y=MAX, label="max")
  df3 = DataFrame(x=x, y=RMSth*180.0/pi, label="rmsth")
  df4 = DataFrame(x=x, y=MAXth*180.0/pi, label="maxth")
  df = vcat(df1, df2)
  dfth = vcat(df3,df4)

  return df,dfth
end

function asyncAnalyzeSolution(fgl::G, sym::Symbol) where G <: AbstractDFG
  lbl = string(sym)
  pp, arr, partials = IncrementalInference.localProduct(fgl, lbl)
  lpm = getKDEMax(pp)
  em = getKDEMax(getKDE(getVariable(fgl,lbl)))
  err1 = norm(lpm[1:2]-em[1:2])
  err2 = 0.0
  if lbl[1]=='x'
    err2 = abs(lpm[3]-em[3])
  end
  return [err1;err2]
end

function analyzeSolution(FGL::Array{<: AbstractDFG,1},fggt=Union{})
  len = length(FGL)
  RMS = Float64[]
  MAX = Float64[]
  RMSth = Float64[]
  MAXth = Float64[]
  for fgl in FGL
    xLB, lLB = ls(fgl)
    ERR = Float64[]
    ERRth = Float64[]
    ALB = [xLB;lLB]
    rr = Future[] #RemoteRef[]
    for lbl in ALB
      push!(rr, remotecall(uppA(),asyncAnalyzeSolution, fgl, lbl))
      # err
      # push!(ERR, err[1])
      # if lbl[1]=='x'
      #   push!(ERRth, err[2])
      # end
    end

    idx = 1
    for r in rr
      err = fetch(r)
      push!(ERR, err[1])
      if ALB[idx][1]=='x'
        push!(ERRth, err[2])
      end
      idx += 1
    end
    push!(RMS, sqrt(mean(ERR.^2)))
    push!(MAX, maximum(abs(ERR)))
    push!(RMSth, sqrt(mean(ERRth.^2)))
    push!(MAXth, maximum(ERRth))
  end

  x=0:(len-1)
  df1 = DataFrame(x=x, y=RMS, label="rms")
  df2 = DataFrame(x=x, y=MAX, label="max")
  df3 = DataFrame(x=x, y=RMSth*180.0/pi, label="rmsth")
  df4 = DataFrame(x=x, y=MAXth*180.0/pi, label="maxth")
  df = vcat(df1, df2)
  dfth = vcat(df3,df4)
  return df,dfth
end
# discrete_color_manual(colors...; levels=nothing,order=nothing) is deprecated, use color_discrete_manual(colors...; levels=levels,order=order) instead.

function drawAnalysis(df,dfth)
  return vstack(
  Gadfly.plot(df, x="x", y="y", color="label", Geom.line,
         Scale.discrete_color_manual("red","black")),
  Gadfly.plot(dfth, x="x", y="y", color="label", Geom.line,
        Scale.discrete_color_manual("red","black"))
        )
end

function getAllFGsKDEs(fgD::Array{<: AbstractDFG,1}, vertsym::Symbol)
  ret = Array{BallTreeDensity,1}()
  for i in 1:length(fgD)
    push!(ret, getKDE(getVariable(fgD[i],vertsym)) )
  end
  return ret
end

function drawAllPose2DBeliefs(plots::Array{Gadfly.Compose.Context,1}, fgD::Array{<: AbstractDFG,1})
    ids = sort(collect(keys(fgD[1].v)))
    co = ["black"; "blue"; "green"; "red"; "magenta"; "cyan"; "cyan1"; "cyan2"]
    println(co[1:length(fgD)])
    for i in ids
        getVariable(fgD[1],i).label
        kdes = getAllFGsKDEs(fgD, i)
        push!(plots, plotKDE(  kdes  )) # [kde!(getVal(V)); kde!(getVal(V0))]
    end
    vstackedPlots(plots)
end

# legacy function -- use the array version instead
function drawAllPose2DBeliefs(plots::Array{Gadfly.Compose.Context,1}, fgD::G, fgD0=Union{}) where G <: AbstractDFG
  println("WARNING: drawAllPose2DBeliefs -- legacy function -- use the array version instead.")
  if fgD0 != Union{}
    drawAllPose2DBeliefs(plots, [fgD;fgD0])
  else
    drawAllPose2DBeliefs(plots, [fgD])
  end
end

function drawComicStripLM(fgD::Array{<: AbstractDFG,1})
    comicA = Array{Gadfly.Plot,1}()
    for fgd in fgD
        cv = drawPosesLandms(fgd)
        # cv = drawPoses(fgd)
        push!(comicA,cv)
    end
    hstack(comicA)
end

function drawComicStrip(fgD::Array{<: AbstractDFG,1})
    comicA = Array{Gadfly.Plot,1}()
    for fgd in fgD
        cv = drawPoses(fgd)
        push!(comicA,cv)
    end
    hstack(comicA)
end


function compositeComic(fnc::Function, fgGT, fgA::Array{<: AbstractDFG,1})
    v = Union{}
    @show length(fgA)
    if length(fgA) == 2
        Gadfly.set_default_plot_size(25cm, 10cm)
        v = fnc([fgA[1:2];fgGT])
    elseif length(fgA) == 3
        Gadfly.set_default_plot_size(25cm, 20cm)
        v = vstack(fnc(fgA[1:2])
        ,fnc([fgA[3];fgGT])    )
    elseif length(fgA) == 4
        Gadfly.set_default_plot_size(25cm, 20cm)
        v = vstack(fnc(fgA[1:3])
        ,fnc([fgA[4];fgGT])    )
    elseif length(fgA) == 7
        Gadfly.set_default_plot_size(25cm, 25cm)
        v = vstack(fnc(fgA[1:3])
        ,fnc(fgA[4:6])
        ,fnc([fgA[7];fgGT])    )
    elseif length(fgA) == 10
        Gadfly.set_default_plot_size(25cm, 25cm)
        v = vstack(fnc(fgA[1:3])
        ,fnc(fgA[4:6])
        ,fnc(fgA[7:9])
        ,fnc([fgA[10];fgGT])    )
    elseif length(fgA) == 13
        Gadfly.set_default_plot_size(25cm, 30cm)
        v = vstack(fnc(fgA[1:3])
        ,fnc(fgA[4:6])
        ,fnc(fgA[7:9])
        ,fnc(fgA[10:12])
        ,fnc([fgA[13];fgGT])    )
    end
    v
end


function compositeComic(fnc::Function, fgA::Array{<: AbstractDFG,1})
    v = Union{}
    @show length(fgA)
    if length(fgA) == 2
        Gadfly.set_default_plot_size(25cm, 10cm)
        v = fnc(fgA[1:2])
    elseif length(fgA) == 3
        Gadfly.set_default_plot_size(25cm, 20cm)
        v = fnc(fgA[1:3])
    elseif length(fgA) == 4
        Gadfly.set_default_plot_size(25cm, 25cm)
        v = vstack(fnc(fgA[1:2])
        ,fnc(fgA[3:4]))
    elseif length(fgA) == 6
        Gadfly.set_default_plot_size(25cm, 25cm)
        v = vstack(fnc(fgA[1:3])
        ,fnc(fgA[4:6])  )
    elseif length(fgA) == 9
        Gadfly.set_default_plot_size(25cm, 25cm)
        v = vstack(fnc(fgA[1:3])
        ,fnc(fgA[4:6])
        ,fnc(fgA[7:9])    )
    elseif length(fgA) == 12
        Gadfly.set_default_plot_size(25cm, 30cm)
        v = vstack(fnc(fgA[1:3])
        ,fnc(fgA[4:6])
        ,fnc(fgA[7:9])
        ,fnc(fgA[10:12])    )
    end
    v
end

#
#
#
# function spyCliqMat(cliq::Graphs.ExVertex; showmsg=true)
#   mat = deepcopy(getCliqMat(cliq, showmsg=showmsg))
#   # TODO -- add improved visualization here, iter vs skip
#   mat = map(Float64, mat)*2.0.-1.0
#   numlcl = size(IIF.getCliqAssocMat(cliq),1)
#   mat[(numlcl+1):end,:] *= 0.9
#   mat[(numlcl+1):end,:] .-= 0.1
#   numfrtl1 = floor(Int,length(getData(cliq).frontalIDs) + 1)
#   mat[:,numfrtl1:end] *= 0.9
#   mat[:,numfrtl1:end] .-= 0.1
#   @show getData(cliq).itervarIDs
#   @show getData(cliq).directvarIDs
#   @show getData(cliq).msgskipIDs
#   @show getData(cliq).directFrtlMsgIDs
#   @show getData(cliq).directPriorMsgIDs
#   sp = Gadfly.spy(mat)
#   push!(sp.guides, Gadfly.Guide.title("$(cliq.attributes["label"]) || $(cliq.attributes["data"].frontalIDs) :$(cliq.attributes["data"].conditIDs)"))
#   push!(sp.guides, Gadfly.Guide.xlabel("fmcmcs $(cliq.attributes["data"].itervarIDs)"))
#   push!(sp.guides, Gadfly.Guide.ylabel("lcl=$(numlcl) || msg=$(size(getCliqMsgMat(cliq),1))" ))
#   return sp
# end
# function spyCliqMat(bt::BayesTree, lbl::Symbol; showmsg=true)
#   spyCliqMat(whichCliq(bt,lbl), showmsg=showmsg)
# end





function plotPose2Vels(fgl::G, sym::Symbol; coord=nothing) where G <: AbstractDFG
  X = getKDE(getVariable(fgl, sym))
  px = plotKDE(X, dims=[4], title="Velx")
  coord != nothing ? (px.coord = coord) : nothing
  py = plotKDE(X, dims=[5], title="Vely")
  coord != nothing ? (py.coord = coord) : nothing
  hstack(px, py)
end


"""
    $(SIGNATURES)

Analysis function to compare KDE plots between the factor graph centric product of a variable with
current value stored in the factor graph object.
"""
function plotProductVsKDE(fgl::G,
                          sym::Symbol;
                          levels::Int=3,
                          c::Vector{String}=["red";"black"] ) where  G <: AbstractDFG
    #
    plotKDE([IIF.localProduct(fgl, sym)[1], getKDE(getVariable(fgl, sym))], levels=3, c=c)
end
