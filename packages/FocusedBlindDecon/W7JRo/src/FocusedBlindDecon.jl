# blind deconvolution
module FocusedBlindDecon

using Inversion
using Misfits
using Signals
using Conv
using Optim
using LineSearches
using RecipesBase
using DataFrames
using StatsBase
using IterativeSolvers
using LinearMaps
using TimerOutputs
using CSV
using Random
using DSP
using FFTW
using LinearAlgebra
using Dates

global const to = TimerOutput(); # create a timer object

global STF_FLAG=false
global FILT_FLAG=false

struct UseOptim end
struct UseIterativeSolvers end

global optG
global optS



function __init__(;stf=false, filt=false)
	global optG, optS, STF_FLAG
	if(get(ENV, "FOCUSBD_OPTG","not_set") == "iterativesolvers")
		@info "FocusBD using IterativeSolvers.jl for G"
		optG=UseIterativeSolvers() 
	else
		@info "FocusBD using Optim.jl for G"
		optG=UseOptim() 
	end
	if(get(ENV, "FOCUSBD_OPTS","not_set") == "iterativesolvers")
		@info "FocusBD using IterativeSolvers.jl for S"
		optS=UseIterativeSolvers() 
	else
		@info "FocusBD using Optim.jl for S"
		optS=UseOptim() 
	end

	if(stf)
		STF_FLAG=true
	end
	if(filt)
		FILT_FLAG=true
	end
	return nothing
end

const FBD=FocusedBlindDecon
export FBD

struct Sxparam
	n::Int64
	attrib::Symbol
end



include("types.jl")
include("fpr.jl")
include("bd.jl")
include("common.jl")
include("ibd.jl")
include("fbd.jl")
include("misfits.jl")
include("ddecon.jl")
include("operators.jl")
include("updates.jl")
include("save.jl")
include("misc.jl")
include("plots.jl")


end # module

#=

function update_func_grad!(pa; goptim=nothing, soptim=nothing, gαvec=nothing, sαvec=nothing)
	# they will be changed in this program, so make a copy 
	ssave=copy(pa.optm.cal.s);
	gsave=copy(pa.optm.cal.g);
	dcalsave=copy(pa.optm.cal.d);

	(goptim===nothing) && (goptim=[:ls])
	(gαvec===nothing) && (gαvec=ones(length(goptim)))

	(soptim===nothing) && (soptim=[:ls])
	(sαvec===nothing) && (sαvec=ones(length(soptim)))

	# dfg for optimization functions
	optim_funcg=Vector{Function}(length(goptim))
	optim_gradg=Vector{Function}(length(goptim))
	for iop in 1:length(goptim)
		if (goptim[iop]==:ls)
			optim_funcg[iop]= x->func_grad!(nothing, x,  pa) 
			optim_gradg[iop]=(storage, x)->func_grad!(storage, x,  pa)
		elseif(goptim[iop]==:weights)
			optim_funcg[iop]= x -> func_grad_g_weights!(nothing, x, pa) 
			optim_gradg[iop]= (storage, x) -> func_grad_g_weights!(storage, x, pa)
		elseif(goptim[iop]==:acorr_weights)
			optim_funcg[iop]= x -> func_grad_g_acorr_weights!(nothing, x, pa) 
			optim_gradg[iop]= (storage, x) -> func_grad_g_acorr_weights!(storage, x, pa)
		else
			error("invalid optim_funcg")
		end
	end
	pa.attrib_inv=:g
	# multi-objective framework
	paMOg=Inversion.ParamMO(noptim=length(goptim), ninv=length(pa.gx.x), αvec=gαvec,
			    		optim_func=optim_funcg,optim_grad=optim_gradg,
					x_init=randn(length(pa.gx.x),10))
	# create dfg for optimization
	pa.gx.func = x -> paMOg.func(x, paMOg)
	pa.gx.grad! = (storage, x) -> paMOg.grad!(storage, x, paMOg)
#	pa.dfg = OnceDifferentiable(x -> paMOg.func(x, paMOg),       
#			    (storage, x) -> paMOg.grad!(storage, x, paMOg), )


	# dfs for optimization functions
	optim_funcs=Vector{Function}(length(soptim))
	optim_grads=Vector{Function}(length(soptim))
	for iop in 1:length(soptim)
		if (soptim[iop]==:ls)
			optim_funcs[iop]=x->func_grad!(nothing, x,  pa) 
			optim_grads[iop]=(storage, x)->func_grad!(storage, x,  pa) 
		else
			error("invalid optim_funcs")
		end
	end

	pa.attrib_inv=:s
	# multi-objective framework
	paMOs=Inversion.ParamMO(noptim=length(soptim), ninv=length(pa.sx.x), αvec=sαvec,
			    		optim_func=optim_funcs,optim_grad=optim_grads,
					x_init=vcat(ones(1,10),randn(length(pa.sx.x)-1,10)))
#	pa.dfs = OnceDifferentiable(x -> paMOs.func(x, paMOs),         
#			    (storage, x) -> paMOs.grad!(storage, x, paMOs))
	pa.sx.func = x -> paMOs.func(x, paMOs)
	pa.sx.grad! =  (storage, x) -> paMOs.grad!(storage, x, paMOs)


	copyto!(pa.optm.cal.s, ssave)
	copyto!(pa.optm.cal.g, gsave)
	copyto!(pa.optm.cal.d,dcalsave)

	return pa
end
=#


