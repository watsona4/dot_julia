##################
# DIAGONAL SPLIT #
##################
@inbounds function Split_Diagonal(obj::Vector{T}, cons::Vector{T}, diagonal_bound::T, lambda::T, instance::MOOInstance, initial_solution::Vector{T}, stats) where {T<:Number}
	tmp = OOESolution()
	model = MathProgBase.LinearQuadraticModel(stats[:solver])
	MathProgBase.loadproblem!(model, instance.A, instance.v_lb, instance.v_ub, obj, instance.cons_lb, instance.cons_ub, :Min)
	MathProgBase.setvartype!(model, instance.var_types)
	extra_constraint = obj - diagonal_bound * cons
	inds = findall(x -> x!="0.0", extra_constraint)
	MathProgBase.addconstr!(model, inds, extra_constraint[inds], lambda, Inf)
	MathProgBase.optimize!(model)
	try
		tmp.vars = MathProgBase.getsolution(model)
	catch
		tmp.vars = initial_solution
	end
	compute_objective_function_value!(tmp, instance)
	tmp
end

###############################
# DIVISION OF OBJECTIVE SPACE #
###############################
@inbounds function horizontal_division_of_objective_space(initial_solutions::Vector{Vector{OOESolution}}, instance::MOOInstance, Partial_Solutions::Vector{OOESolution}, threads::Int64, stats, pareto_frontier::Bool)
	element1 = Partial_Solutions[1]
	element2 = OOESolution()
	bound_variation = (element1.obj_vals[3] - Partial_Solutions[2].obj_vals[3])/ threads
	half_bound::Float64 = element1.obj_vals[3] - bound_variation
	for i in 1: threads - 1
		element2 = Split_Triangle(instance.c[2,:], instance.c[3,:], half_bound, instance, Partial_Solutions[2].vars, stats)
		stats[:Number_MIPs] += 1
		element2 = Weighted_Sum(instance, element2, stats)
		stats[:Number_MIPs] += 1
		if !pareto_frontier
			element2, Opt_Solution, GUB, stats = LB_Finder_Point(instance, element2, deepcopy(element2), 0.0, false, stats)
		end
		tmp = [element1, element2]
		initial_solutions[i] = tmp
		element1 = element2
		half_bound += -bound_variation
	end
	initial_solutions[threads] = [element1, Partial_Solutions[2]]
	initial_solutions, stats
end

@inbounds function vertical_division_of_objective_space(initial_solutions::Vector{Vector{OOESolution}}, instance::MOOInstance, Partial_Solutions::Vector{OOESolution}, threads::Int64, stats, pareto_frontier::Bool)
	element1 = Partial_Solutions[1]
	element2 = OOESolution()
	bound_variation = (Partial_Solutions[2].obj_vals[2] - element1.obj_vals[2])/ threads
	half_bound::Float64 = element1.obj_vals[2] + bound_variation
	for i in 1: threads - 1
		element2 = Split_Triangle(instance.c[3,:], instance.c[2,:], half_bound, instance, element1.vars, stats)
		stats[:Number_MIPs] += 1
		element2 = Weighted_Sum(instance, element2, stats)
		stats[:Number_MIPs] += 1
		if !pareto_frontier
			element2, Opt_Solution, GUB, stats = LB_Finder_Point(instance, element2, deepcopy(element2), 0.0, false, stats)
		end
		tmp = [element1, element2]
		initial_solutions[i] = tmp
		element1 = element2
		half_bound += bound_variation
	end
	initial_solutions[threads] = [element1, Partial_Solutions[2]]
	initial_solutions, stats
end

@inbounds function diagonal_division_of_objective_space(initial_solutions::Vector{Vector{OOESolution}}, instance::MOOInstance, Partial_Solutions::Vector{OOESolution}, threads::Int64, stats, pareto_frontier::Bool)
	element1 = Partial_Solutions[1]
	element2 = OOESolution()
	tmp_angle = (pi/2)/threads
	for i in 1: threads - 1
		tmp_angle *= i
		diagonal_bound = tan(tmp_angle)
		lambda = element1.obj_vals[3] - (Partial_Solutions[2].obj_vals[2] * diagonal_bound)
		element2 = Split_Diagonal(instance.c[3,:], instance.c[2,:], diagonal_bound, lambda, instance, element1.vars, stats)
		stats[:Number_MIPs] += 1
		element2 = Weighted_Sum(instance, element2, stats)
		stats[:Number_MIPs] += 1
		if !pareto_frontier
			element2, Opt_Solution, GUB, stats = LB_Finder_Point(instance, element2, deepcopy(element2), 0.0, false, stats)
		end
		tmp = [element1, element2]
		initial_solutions[i] = tmp
		element1 = element2
	end		
	initial_solutions[threads] = [element1, Partial_Solutions[2]]
	initial_solutions, stats
end

##############################
# PARALLELIZATION TECHNIQUES #
##############################
@inbounds function parallel_division_of_objective_space(initial_solutions::Vector{Vector{OOESolution}}, instance::MOOInstance, Partial_Solutions::Vector{OOESolution}, threads::Int64, parallelization::Int64, stats, pareto_frontier::Bool)
	if parallelization == 1
		initial_solutions, stats = horizontal_division_of_objective_space(initial_solutions, instance, Partial_Solutions, threads, stats, pareto_frontier)
	elseif parallelization == 2
		initial_solutions, stats = vertical_division_of_objective_space(initial_solutions, instance, Partial_Solutions, threads, stats, pareto_frontier)
	else
		initial_solutions, stats = diagonal_division_of_objective_space(initial_solutions, instance, Partial_Solutions, threads, stats, pareto_frontier)
	end
	initial_solutions, stats	
end

###########################################################################################################################################################################

############################
# PARALLELIZATION APPROACH #
############################
@inbounds function OOES_parallel(instance::MOOInstance, instance2::MOOInstance, Partial_Solutions::Vector{OOESolution}, number_of_cont_variables::Int64, number_of_int_or_bin_variables::Int64, threads::Int64, parallelization::Int64, initial_time::Float64, timelimit::Float64, stats, pareto_frontier::Bool)
	GLB::Float64 = -1e10
	num_threads::Vector{Int64} = setdiff(procs(), myid())[1:threads]
	initial_solutions::Vector{Vector{OOESolution}} = fill(OOESolution[], length(num_threads))
	vector_of_solutions = type_of_output(length(num_threads), parallelization, pareto_frontier)
	initial_solutions, stats = parallel_division_of_objective_space(initial_solutions, instance, Partial_Solutions, threads, parallelization, stats, pareto_frontier)
	@sync begin
		for i in 1:length(num_threads)
			@async begin
				vector_of_solutions[i] = remotecall_fetch(OOES, num_threads[i], copy(instance), copy(instance2), initial_solutions[i], number_of_cont_variables, number_of_int_or_bin_variables, initial_time, timelimit, threads, parallelization, stats, pareto_frontier)
			end
		end
	end
	Opt_Solution = type_of_output(pareto_frontier)
	if !pareto_frontier
		Opt_Solution, stats, GLB = vector_of_solutions[1].tmp_solution, vector_of_solutions[1].stats, vector_of_solutions[1].GLB
		for i in 2:length(num_threads)
			if vector_of_solutions[i].tmp_solution.obj_vals[1] < Opt_Solution.obj_vals[1]
				Opt_Solution = vector_of_solutions[i].tmp_solution
			end
			if vector_of_solutions[i].GLB < GLB
				GLB = vector_of_solutions[i].GLB
			end
			stats = parallel_statistics(stats, vector_of_solutions[i].stats)
		end
	else
		for i in 1:length(num_threads)
			for j in 1:length(vector_of_solutions[i].tmp_solution)
				if (i < length(num_threads) && j < length(vector_of_solutions[i].tmp_solution)) || (i == length(num_threads) && j <= length(vector_of_solutions[i].tmp_solution))
					insert_element_in_queue!(Opt_Solution, vector_of_solutions[i].tmp_solution[j])
				end
			end
		end
	end
	Opt_Solution, stats, GLB
end
