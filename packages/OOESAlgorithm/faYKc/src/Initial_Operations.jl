###########################
# LEXICOGRAPHIC OPERATION #
###########################
@inbounds function lex_min(instance::MOOInstance, c2::Vector{T}, c3::Vector{T}, c1::Vector{T}, stats) where {T<:Number}
	model = MathProgBase.LinearQuadraticModel(stats[:solver])
	MathProgBase.loadproblem!(model, instance.A, instance.v_lb, instance.v_ub, c2, instance.cons_lb, instance.cons_ub, :Min)
	MathProgBase.setvartype!(model, instance.var_types)
	MathProgBase.optimize!(model)
	try
		inds = findall(x -> x!="0.0", c2)
        	MathProgBase.addconstr!(model, inds, c2[inds], -Inf, MathProgBase.getobjval(model))
	catch
		return OOESolution()
	end
	MathProgBase.setobj!(model, c3)
	MathProgBase.optimize!(model)
	tmp = OOESolution(vars=MathProgBase.getsolution(model))
	tmp
end

@inbounds function lex_min(instance::MOOInstance, stats, pareto_frontier::Bool)
	non_dom_sols::Vector{OOESolution} = OOESolution[]
	tmp = OOESolution()
	for i in 1:2
		if i == 1
			tmp = lex_min(instance::MOOInstance, instance.c[2,:], instance.c[3,:], instance.c[1,:], stats)
		else
			tmp = lex_min(instance::MOOInstance, instance.c[3,:], instance.c[2,:], instance.c[1,:],  stats)
		end
		if length(tmp.vars) == 0
			continue
		else
			compute_objective_function_value!(tmp, instance)
			if !pareto_frontier
				model = MathProgBase.LinearQuadraticModel(stats[:solver])
				MathProgBase.loadproblem!(model, instance.A, instance.v_lb, instance.v_ub, instance.c[1, :], instance.cons_lb, instance.cons_ub, :Min)
				MathProgBase.setvartype!(model, instance.var_types)
				c2 = instance.c[2,:]
				c3 = instance.c[3,:]
				inds = findall(x -> x!="0.0", c2)
				MathProgBase.addconstr!(model, inds, c2[inds], -Inf, tmp.obj_vals[2] + Compute_Epsilon(tmp.obj_vals[2]))
				inds = findall(x -> x!="0.0", c3)
				MathProgBase.addconstr!(model, inds, c3[inds], -Inf, tmp.obj_vals[3] + Compute_Epsilon(tmp.obj_vals[3]))
				MathProgBase.optimize!(model)
				try
					tmp.vars = MathProgBase.getsolution(model)
				catch
					tmp.vars = tmp.vars
				end
				compute_objective_function_value!(tmp, instance)
				tmp.fxopt = true
			end	
			push!(non_dom_sols, tmp)
		end
	end
	non_dom_sols
end

########################
# MODEL INITIALIZATION #
########################
@inbounds function OOES_warm_up(instance::MOOInstance, mip_solver::MathProgBase.SolverInterface.AbstractMathProgSolver, pareto_frontier::Bool)
	Partial_Solutions::Vector{OOESolution} = OOESolution[]
	#Priority_Queue::Vector{EOPriorQueue} = EOPriorQueue[]
	#Opt_Solution = OOESolution()
	#Feasible_Solution = OOESolution()
	number_of_cont_variables, number_of_int_or_bin_variables = counting(instance)
	if number_of_cont_variables > 0 && number_of_int_or_bin_variables > 0 
		instance2 = deepcopy(instance)
		Duplicate_Instance!(instance2, instance, number_of_cont_variables)
	else
		instance2 = deepcopy(instance)
	end
	stats = initialize_statistics(mip_solver)	
	Partial_Solutions = lex_min(instance, stats, pareto_frontier)
	stats[:Number_MIPs] += 6
	instance2, Partial_Solutions, number_of_cont_variables, number_of_int_or_bin_variables, stats
end

####################
# SOLVER SELECTION #
####################
@inbounds function solver_selection(mipsolver::Int64, mip_solver::MathProgBase.SolverInterface.AbstractMathProgSolver, relative_gap::Float64)
	if mipsolver == 2
		mip_solver=GurobiSolver(OutputFlag=0, Threads=1, MIPGap=relative_gap)
	elseif mipsolver == 3
		mip_solver=CplexSolver(CPX_PARAM_SCRIND=0, CPX_PARAM_THREADS=1, CPX_PARAM_EPGAP=relative_gap)
	elseif mipsolver == 4
		mip_solver=SCIPSolver("display/verblevel", 0, "limits/gap", relative_gap)
	elseif mipsolver == 5
		mip_solver=Xpress.XpressSolver(THREADS=1, BARGAPSTOP=relative_gap, OUTPUTLOG=0)
	end
	mip_solver
end
