#######################
# WEIGHTED SUM METHOD #
#######################
@inbounds function Weighted_Sum_Method(instance::MOOInstance, c2::Vector{T}, c3::Vector{T}, lambda2::T, lambda3::T, cons2::T, cons3::T, initial_solution::Vector{T}, stats) where {T<:Number}
	tmp = OOESolution()
	c4 = lambda2 * c2 + lambda3 * c3
	model = MathProgBase.LinearQuadraticModel(stats[:solver])
	MathProgBase.loadproblem!(model, instance.A, instance.v_lb, instance.v_ub, c4, instance.cons_lb, instance.cons_ub, :Min)
	MathProgBase.setvartype!(model, instance.var_types)
	inds = findall(x -> x!="0.0", c2)
	MathProgBase.addconstr!(model, inds, c2[inds], cons2, Inf)
	inds = findall(x -> x!="0.0", c3)
	MathProgBase.addconstr!(model, inds, c3[inds], cons3, Inf)
	MathProgBase.optimize!(model)
	try
		tmp.vars = MathProgBase.getsolution(model)
	catch
		tmp.vars = initial_solution
	end
	tmp
end

@inbounds function Weighted_Sum_Method(Partial_Solutions::Vector{OOESolution}, instance::MOOInstance, element1::OOESolution , element2::OOESolution, counter_solutions::Int64, stats)
	tmp = OOESolution()
	lambda2::Float64 = element1.obj_vals[3] - element2.obj_vals[3]
	lambda3::Float64 = element2.obj_vals[2] - element1.obj_vals[2]
	tmp = Weighted_Sum_Method(instance, instance.c[2,:], instance.c[3,:], lambda2, lambda3, element1.obj_vals[2], element2.obj_vals[3], element1.vars, stats)
	compute_objective_function_value!(tmp, instance)
	tmp.fxopt = false
	lambda_top::Float64 = (lambda2 * tmp.obj_vals[2] + lambda3 * tmp.obj_vals[3]) - (lambda2 * element1.obj_vals[2] + lambda3 * element1.obj_vals[3])
	gap_line1 = (abs(lambda2 * element1.obj_vals[2]) + abs(lambda3 * element1.obj_vals[3])) * 1e-5
	if (lambda_top < (gap_line1 + 1e-5) * -1)
		insert!(Partial_Solutions, counter_solutions + 1, tmp)	
	else
		counter_solutions += 1
 	end
	Partial_Solutions, counter_solutions
end

@inbounds function Weighted_Sum_Method(Partial_Solutions::Vector{OOESolution}, counter_solutions::Int64, sw::Bool, instance::MOOInstance, element1::OOESolution , element2::OOESolution, stats)
	push!(Partial_Solutions, element1)
	push!(Partial_Solutions, element2)
	while sw == false
		Partial_Solutions, counter_solutions = Weighted_Sum_Method(Partial_Solutions, instance, element1, element2, counter_solutions, stats)
		stats[:Number_MIPs] += 1
		stats[:IP_Weighted_Sum] += 1
		if length(Partial_Solutions) < counter_solutions + 1
			sw = true
		else
			element1 = Partial_Solutions[counter_solutions]
			element2 = Partial_Solutions[counter_solutions + 1]
		end
	end
	counter_solutions = length(Partial_Solutions)
	Partial_Solutions, counter_solutions, stats
end

######################
# WEIGHTED SUM UPDATE#
######################
@inbounds function Weighted_Sum_Update(Priority_Queue::Vector{EOPriorQueue}, Partial_Solutions::Vector{OOESolution}, counter_solutions::Int64, element::EOPriorQueue, Opt_Solution::Union{OOESolution, Vector{OOESolution}}, pareto_frontier::Bool)
	for i in 2:counter_solutions
		insert_element_in_queue!(Priority_Queue, Partial_Solutions[counter_solutions - i + 1], Partial_Solutions[counter_solutions - i + 2], true, element.Direction, element.LBound)
		if pareto_frontier && i != counter_solutions
			insert_element_in_queue!(Opt_Solution, Partial_Solutions[counter_solutions - i + 1])
		end
		pop!(Partial_Solutions)
	end	
	pop!(Partial_Solutions)
	Priority_Queue, Partial_Solutions, Opt_Solution
end

################
# WEIGHTED SUM #
################
@inbounds function Weighted_Sum(c2::Vector{T}, c3::Vector{T}, bound2::T, bound3::T, instance::MOOInstance, initial_solution::Vector{T}, stats) where {T<:Number}
	tmp = OOESolution()
	c4 = c2 + c3
	model = MathProgBase.LinearQuadraticModel(stats[:solver])
	MathProgBase.loadproblem!(model, instance.A, instance.v_lb, instance.v_ub, c4, instance.cons_lb, instance.cons_ub, :Min)
	MathProgBase.setvartype!(model, instance.var_types)
	inds = findall(x -> x!="0.0", c2)
	MathProgBase.addconstr!(model, inds, c2[inds], -Inf, bound2 + Compute_Epsilon(bound2))
	inds = findall(x -> x!="0.0", c3)
	MathProgBase.addconstr!(model, inds, c3[inds], -Inf, bound3 + Compute_Epsilon(bound3))
	MathProgBase.optimize!(model)
	try
		tmp.vars = MathProgBase.getsolution(model)
	catch
		tmp.vars = initial_solution
	end
	compute_objective_function_value!(tmp, instance)
	tmp
end

@inbounds function Weighted_Sum(instance::MOOInstance, element::OOESolution, stats)
	tmp = OOESolution()
	tmp = Weighted_Sum(instance.c[2,:], instance.c[3,:], element.obj_vals[2], element.obj_vals[3], instance, element.vars, stats)
	tmp
end

####################
# OPTIMALITY PROOF #
####################
@inbounds function Optimality_proof(c2::Vector{T}, c3::Vector{T}, bound2::T, bound3::T, model::MathProgBase.AbstractMathProgModel, instance::MOOInstance) where {T<:Number}
	MathProgBase.setobj!(model, c2 + c3)	
	inds = findall(x -> x!="0.0", c2)
	MathProgBase.addconstr!(model, inds, c2[inds], -Inf, bound2)
	inds = findall(x -> x!="0.0", c3)
	MathProgBase.addconstr!(model, inds, c3[inds], -Inf, bound3)
	MathProgBase.optimize!(model)
	tmp = OOESolution(vars=MathProgBase.getsolution(model))
	constraints = collect(length(MathProgBase.getconstrLB(model))-:length(MathProgBase.getconstrLB(model)))
	MathProgBase.delconstrs!(model, constraints)
	compute_objective_function_value!(tmp, instance)
	tmp
end

@inbounds function Optimality_proof(instance::MOOInstance, model::MathProgBase.AbstractMathProgModel, z1::Float64, z2::Float64)
	tmp = OOESolution()
	tmp = Optimality_proof(instance.c[2,:], instance.c[3,:], z1, z2 , model, instance)
	println(tmp.obj_vals)
	if z1 - tmp.obj_vals[2] >= 1e-5 || z2 -tmp.obj_vals[3]  >= 1e-5
		println("not optimal")
	else
		println("optimal")
	end
	tmp
end
