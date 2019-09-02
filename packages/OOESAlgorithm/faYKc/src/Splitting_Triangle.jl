##################
# TRIANGLE SPLIT #
##################
@inbounds function Split_Triangle(obj::Vector{T}, cons::Vector{T}, Half_Bound::T, instance::MOOInstance, initial_solution::Vector{T}, stats) where {T<:Number}
	tmp = OOESolution()
	model = MathProgBase.LinearQuadraticModel(stats[:solver])
	MathProgBase.loadproblem!(model, instance.A, instance.v_lb, instance.v_ub, obj, instance.cons_lb, instance.cons_ub, :Min)
	MathProgBase.setvartype!(model, instance.var_types)
	inds = findall(x -> x!="0.0", cons)
	MathProgBase.addconstr!(model, inds, cons[inds], -Inf, Half_Bound)
	MathProgBase.optimize!(model)
	try
		tmp.vars = MathProgBase.getsolution(model)
	catch
		tmp.vars = initial_solution
	end
	compute_objective_function_value!(tmp, instance)
	tmp
end

@inbounds function Second_Triangle(obj::Vector{T}, cons::Vector{T}, cons_val::T, Half_Bound::T, instance::MOOInstance, initial_solution::Vector{T}, stats) where {T<:Number}
	tmp = OOESolution()
	model = MathProgBase.LinearQuadraticModel(stats[:solver])
	MathProgBase.loadproblem!(model, instance.A, instance.v_lb, instance.v_ub, obj, instance.cons_lb, instance.cons_ub, :Min)
	MathProgBase.setvartype!(model, instance.var_types)
	inds = findall(x -> x!="0.0", obj)
	MathProgBase.addconstr!(model, inds, obj[inds], Half_Bound, Inf)
	inds = findall(x -> x!="0.0", cons)
	MathProgBase.addconstr!(model, inds, cons[inds], -Inf, cons_val - Compute_Epsilon2(cons_val))
	MathProgBase.optimize!(model)
	try
		tmp.vars = MathProgBase.getsolution(model)
	catch
		tmp.vars = initial_solution
	end
	compute_objective_function_value!(tmp, instance)
	tmp
end

####################
# HORIZONTAL SPLIT #
####################
@inbounds function Split_Triangle_Horizontal(instance::MOOInstance, element1::OOESolution, element2::OOESolution, stats)
	tmp = OOESolution()
	Half_Bound::Float64 = (element1.obj_vals[3] + element2.obj_vals[3]) / 2
	tmp = Split_Triangle(instance.c[2,:], instance.c[3,:], Half_Bound, instance, element2.vars, stats)
	tmp
end

@inbounds function Second_Horizontal_Step(Feasible_Solution_2::OOESolution, instance::MOOInstance, stats)
	Half_Bound::Float64 = Feasible_Solution_2.obj_vals[2] + Compute_Epsilon(Feasible_Solution_2.obj_vals[2])
	Feasible_Solution_2 = Split_Triangle(instance.c[3,:], instance.c[2,:], Half_Bound, instance, Feasible_Solution_2.vars, stats)
end

@inbounds function Third_Horizontal_Step(instance::MOOInstance, Feasible_Solution::OOESolution, element1::OOESolution, element2::OOESolution, stats)
	tmp = OOESolution()
	Half_Bound::Float64 = (element1.obj_vals[3] + element2.obj_vals[3]) / 2
	tmp = Second_Triangle(instance.c[3,:], instance.c[2,:], Feasible_Solution.obj_vals[2], Half_Bound, instance, element1.vars, stats)
	tmp
end

##################
# VERTICAL SPLIT #
##################
@inbounds function Split_Triangle_Vertical(instance::MOOInstance, element1::OOESolution, element2::OOESolution, stats)
	tmp = OOESolution()
	Half_Bound::Float64 = (element1.obj_vals[2] + element2.obj_vals[2]) / 2
	tmp = Split_Triangle(instance.c[3,:], instance.c[2,:], Half_Bound, instance, element1.vars, stats)
	tmp
end

@inbounds function Second_Vertical_Step(Feasible_Solution_2::OOESolution, instance::MOOInstance, stats)
	Half_Bound::Float64 = Feasible_Solution_2.obj_vals[3] + Compute_Epsilon(Feasible_Solution_2.obj_vals[3])
	Feasible_Solution_2 = Split_Triangle(instance.c[2,:], instance.c[3,:], Half_Bound, instance, Feasible_Solution_2.vars, stats)
end

@inbounds function Third_Vertical_Step(instance::MOOInstance, Feasible_Solution::OOESolution, element1::OOESolution, element2::OOESolution, stats)
	tmp = OOESolution()
	Half_Bound::Float64 = (element1.obj_vals[2] + element2.obj_vals[2]) / 2
	tmp = Second_Triangle(instance.c[2,:], instance.c[3,:], Feasible_Solution.obj_vals[3], Half_Bound, instance, element2.vars, stats)
	tmp
end
