####################
# INSTANCE STORAGE #
####################
mutable struct MOOInstance
	var_types::Vector{Symbol}
	v_lb::Vector{Float64}
	v_ub::Vector{Float64}
	c::Array{Float64, 2}
	A::SparseMatrixCSC{Float64,Int64}
	cons_lb::Vector{Float64}
	cons_ub::Vector{Float64}
end

function MOOInstance(;var_types::Vector{Symbol}=Symbol[], v_lb::Vector{Float64}=Float64[], v_ub::Vector{Float64}=Float64[], c::Array{Float64, 2}=Array{Float64}(1, 1), A::SparseMatrixCSC{Float64,Int64}=spzeros(1,1), cons_lb::Vector{Float64}=Float64[], cons_ub::Vector{Float64}=Float64[])
	MOOInstance(var_types, v_lb, v_ub, c, A, cons_lb, cons_ub)
end

function copy(instance::MOOInstance)
    MOOInstance(instance.var_types, instance.v_lb, instance.v_ub, instance.c, instance.A, instance.cons_lb, instance.cons_ub)
end

####################
# SOLUTION STORAGE #
####################
mutable struct OOESolution
	vars::Vector{Float64}
	obj_vals::Vector{Float64}
	fxopt::Bool
end

function OOESolution(;vars::Vector{Float64}=Float64[], obj_vals::Vector{Float64}=Float64[], fxopt::Bool=false)
	OOESolution(vars, obj_vals, fxopt)
end

###########################
# PRIORITY QUEUE ELEMENTS #
###########################
abstract type Queue_Element end

mutable struct EOPriorQueue <: Queue_Element
	Sol_Top::OOESolution
	Sol_Bottom::OOESolution
	Shape::Bool
    	Direction::Bool
    	LBound::Float64
end

function EOPriorQueue(;Sol_Top::OOESolution=OOESolution(), Sol_Bottom::OOESolution=OOESolution(), Shape::Bool=false, Direction::Bool=false, LBound::Float64=0.0)
	EOPriorQueue(Sol_Top, Sol_Bottom, Shape, Direction, LBound)
end

#####################################
# PARALLELIZATION SOLUTIONS STORAGE #
#####################################
abstract type Parallel_Opt_Solution end

mutable struct Opt_Solutions <: Parallel_Opt_Solution
	tmp_solution::OOESolution
	stats::Dict
	GLB::Float64
end

function Opt_Solutions(;Opt_Solution::OOESolution=OOESolution(), stats=Dict(), GLB::Float64=0.0)
	Opt_Solutions(Opt_Solution, stats, GLB)
end

mutable struct Opt_Pareto_Solutions <: Parallel_Opt_Solution
	tmp_solution::Vector{OOESolution}
	stats::Dict
	GLB::Float64
end

function Opt_Pareto_Solutions(;Opt_Solution::Vector{OOESolution}=OOESolution[], stats=Dict(), GLB::Float64=0.0)
	Opt_Pareto_Solutions(Opt_Solution, stats, GLB)
end

abstract type Parallel_Vector end

mutable struct Parallel_Solutions <: Parallel_Vector
	Priority_Queue::Vector{EOPriorQueue}
	Partial_Solutions::Vector{OOESolution}
	Opt_Solution::OOESolution
	GUB::Float64
	stats::Dict
end

function Parallel_Solutions(;Priority_Queue::Vector{EOPriorQueue} = EOPriorQueue[], Partial_Solutions::Vector{OOESolution} = OOESolution[], Opt_Solution::OOESolution = OOESolution(), GUB::Float64 = 0.0, stats=Dict())
	Parallel_Solutions(Priority_Queue, Partial_Solutions, Opt_Solution, GUB, stats)
end

mutable struct Parallel_Pareto_Solutions <: Parallel_Vector
	Priority_Queue::Vector{EOPriorQueue}
	Partial_Solutions::Vector{OOESolution}
	Opt_Solution::Vector{OOESolution}
	GUB::Float64
	stats::Dict
end

function Parallel_Pareto_Solutions(;Priority_Queue::Vector{EOPriorQueue} = EOPriorQueue[], Partial_Solutions::Vector{OOESolution} = OOESolution[], Opt_Solution::Vector{OOESolution} = OOESolution[], GUB::Float64 = 0.0, stats=Dict())
	Parallel_Pareto_Solutions(Priority_Queue, Partial_Solutions, Opt_Solution, GUB, stats)
end
################################
# INITIALIZATION OF STATISTICS #
################################

function initialize_statistics(mip_solver::MathProgBase.SolverInterface.AbstractMathProgSolver)
	tmp = Dict()
	tmp[:iteration] = 0
	tmp[:Number_MIPs] = 0
	tmp[:Time_Finder_Point] = 0.0
	tmp[:IP_Finder_Point] = 0
	tmp[:N_Finder_Point] = 0
	tmp[:Time_Weighted_Sum] = 0.0
	tmp[:IP_Weighted_Sum] = 0
	tmp[:N_Weighted_Sum] = 0
	tmp[:Time_Line_Detector] = 0.0
	tmp[:IP_Line_Detector] = 0
	tmp[:N_Line_Detector] = 0
	tmp[:Time_Finder_Line] = 0.0
	tmp[:IP_Finder_Line] = 0
	tmp[:N_Finder_Line] = 0
	tmp[:Time_Finder_Triangle] = 0.0
	tmp[:IP_Finder_Triangle] = 0
	tmp[:N_Finder_Triangle] = 0
	tmp[:Time_UB_Finder_Triangle] = 0.0
	tmp[:IP_UB_Finder_Triangle] = 0
	tmp[:N_UB_Finder_Triangle] = 0
	tmp[:solver] = mip_solver
	tmp
end

function parallel_statistics(stats, new_stats)
	stats[:iteration] += new_stats[:iteration]
	stats[:Number_MIPs] += new_stats[:Number_MIPs]
	stats[:Time_Finder_Point] += new_stats[:Time_Finder_Point]
	stats[:IP_Finder_Point] += new_stats[:IP_Finder_Point]
	stats[:N_Finder_Point] += new_stats[:N_Finder_Point]
	stats[:Time_Weighted_Sum] += new_stats[:Time_Weighted_Sum]
	stats[:IP_Weighted_Sum] += new_stats[:IP_Weighted_Sum]
	stats[:N_Weighted_Sum] += new_stats[:N_Weighted_Sum]
	stats[:Time_Line_Detector] += new_stats[:Time_Line_Detector]
	stats[:IP_Line_Detector] += new_stats[:IP_Line_Detector]
	stats[:N_Line_Detector] += new_stats[:N_Line_Detector]
	stats[:Time_Finder_Line] += new_stats[:Time_Finder_Line]
	stats[:IP_Finder_Line] += new_stats[:IP_Finder_Line]
	stats[:N_Finder_Line] += new_stats[:N_Finder_Line]
	stats[:Time_Finder_Triangle] += new_stats[:Time_Finder_Triangle]
	stats[:IP_Finder_Triangle] += new_stats[:IP_Finder_Triangle]
	stats[:N_Finder_Triangle] += new_stats[:N_Finder_Triangle]
	stats[:Time_UB_Finder_Triangle] += new_stats[:Time_UB_Finder_Triangle]
	stats[:IP_UB_Finder_Triangle] += new_stats[:IP_UB_Finder_Triangle]
	stats[:N_UB_Finder_Triangle] += new_stats[:N_UB_Finder_Triangle]
	stats
end

function fixed_statistics(stats, threads::Int64)
	stats[:iteration] = stats[:iteration] / threads
	stats[:Number_MIPs] = stats[:Number_MIPs] / threads
	stats[:Time_Finder_Point] = stats[:Time_Finder_Point] / threads
	stats[:IP_Finder_Point] = stats[:IP_Finder_Point] / threads
	stats[:N_Finder_Point] = stats[:N_Finder_Point] / threads
	stats[:Time_Weighted_Sum] = stats[:Time_Weighted_Sum] / threads
	stats[:IP_Weighted_Sum] = stats[:IP_Weighted_Sum] / threads
	stats[:N_Weighted_Sum] = stats[:N_Weighted_Sum] / threads
	stats[:Time_Line_Detector] = stats[:Time_Line_Detector] / threads
	stats[:IP_Line_Detector] = stats[:IP_Line_Detector] / threads
	stats[:N_Line_Detector] = stats[:N_Line_Detector] / threads
	stats[:Time_Finder_Line] = stats[:Time_Finder_Line] / threads
	stats[:IP_Finder_Line] = stats[:IP_Finder_Line] / threads
	stats[:N_Finder_Line] = stats[:N_Finder_Line] / threads
	stats[:Time_Finder_Triangle] = stats[:Time_Finder_Triangle] / threads
	stats[:IP_Finder_Triangle] = stats[:IP_Finder_Triangle] / threads
	stats[:N_Finder_Triangle] = stats[:N_Finder_Triangle] / threads
	stats[:Time_UB_Finder_Triangle] = stats[:Time_UB_Finder_Triangle] / threads
	stats[:IP_UB_Finder_Triangle] = stats[:IP_UB_Finder_Triangle] / threads
	stats[:N_UB_Finder_Triangle] = stats[:N_UB_Finder_Triangle] / threads

	stats
end
