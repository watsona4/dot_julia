#############################
# LB-FINDER POINT OPERATION #
#############################
@inbounds function LB_Finder_Point(c1::Vector{T}, c2::Vector{T}, c3::Vector{T}, bound2::T, bound3::T, instance::MOOInstance, initial_solution::Vector{T}, stats) where {T<:Number}
	tmp = OOESolution()
	model = MathProgBase.LinearQuadraticModel(stats[:solver])
	MathProgBase.loadproblem!(model, instance.A, instance.v_lb, instance.v_ub, c1, instance.cons_lb, instance.cons_ub, :Min)
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
	tmp.fxopt = true	
	tmp
end

@inbounds function LB_Finder_Point(instance::MOOInstance, element1::OOESolution, Opt_Solution::OOESolution, GUB::Float64, sw::Bool, stats)
	tmp = OOESolution()
	tmp = LB_Finder_Point(instance.c[1,:], instance.c[2,:], instance.c[3,:], element1.obj_vals[2], element1.obj_vals[3], instance, element1.vars, stats)
	stats[:Number_MIPs] += 1
	if sw
		stats[:IP_Finder_Point] += 1
	else
		stats[:IP_UB_Finder_Triangle] += 1
	end
	Opt_Solution, GUB = Update_Global_Upper_Bound(Opt_Solution, tmp, GUB)
	tmp, Opt_Solution, GUB, stats
end

############################
# LB-FINDER LINE OPERATION #
############################
@inbounds function LB_Finder_Line(c1::Vector{T}, c2::Vector{T}, c3::Vector{T}, bound12::T, bound13::T, bound22::T, bound23::T, instance::MOOInstance, initial_solution::Vector{T}, stats) where {T<:Number}
	tmp = OOESolution()
        lambda1 = bound13 - bound23
        lambda2 = bound22 - bound12
        lambda3 = (lambda1 * bound12) + (lambda2 * bound13)
	model = MathProgBase.LinearQuadraticModel(stats[:solver])
	MathProgBase.loadproblem!(model, instance.A, instance.v_lb, instance.v_ub, c1, instance.cons_lb, instance.cons_ub, :Min)
	MathProgBase.setvartype!(model, instance.var_types)
	inds = findall(x -> x!="0.0", c2)
	MathProgBase.addconstr!(model, inds, c2[inds], -Inf, bound22 + Compute_Epsilon(bound22))
	inds = findall(x -> x!="0.0", c3)
	MathProgBase.addconstr!(model, inds, c3[inds], -Inf, bound13 + Compute_Epsilon(bound13))
	c4 = (lambda1*c2) + (lambda2*c3)
	inds = findall(x -> x!="0.0", c4)
	MathProgBase.addconstr!(model, inds, c4[inds], -Inf, lambda3 + 1e-5)
	MathProgBase.optimize!(model)
	try
		tmp.vars = MathProgBase.getsolution(model)
	catch
		tmp.vars = initial_solution
	end
	compute_objective_function_value!(tmp, instance)
	tmp.fxopt = true
	tmp
end

@inbounds function LB_Finder_Line(instance::MOOInstance, element1::OOESolution, element2::OOESolution, stats)
	tmp = OOESolution()
	tmp = LB_Finder_Line(instance.c[1,:], instance.c[2,:], instance.c[3,:], element1.obj_vals[2], element1.obj_vals[3], element2.obj_vals[2], element2.obj_vals[3], instance, element1.vars, stats)
	tmp
end

@inbounds function LB_Finder_Line(Connection_Index::Bool, Partial_Connection::Bool, Feasible_Solution::OOESolution, instance::MOOInstance, element1::OOESolution, element2::OOESolution, Opt_Solution::OOESolution, GUB::Float64, stats)
	if (Connection_Index == true)
		t0 = time()
		stats[:N_Finder_Line] += 1
		Feasible_Solution_2 = OOESolution()
		if (Partial_Connection == false)
			Feasible_Solution_2 = LB_Finder_Line(instance, element1, element2, stats)
		else
			Feasible_Solution_2 = LB_Finder_Line(instance, element1, Feasible_Solution, stats)
			element1 = Feasible_Solution
		end
		stats[:Number_MIPs] += 1
		stats[:IP_Finder_Line] += 1
		stats[:Time_Finder_Line] += time() - t0
		Opt_Solution, GUB = Update_Global_Upper_Bound(Opt_Solution, Feasible_Solution_2, GUB)
	end
	element1, Opt_Solution, GUB, stats
end

################################
# LB-FINDER TRIANGLE OPERATION #
################################
@inbounds function LB_Finder_Triangle(c1::Vector{T}, c2::Vector{T}, c3::Vector{T}, bound3::T, bound2::T, instance::MOOInstance, GUB::Float64, initial_solution::Vector{T}, stats) where {T<:Number}
	tmp = OOESolution()
	model = MathProgBase.LinearQuadraticModel(stats[:solver])
	MathProgBase.loadproblem!(model, instance.A, instance.v_lb, instance.v_ub, c1, instance.cons_lb, instance.cons_ub, :Min)
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
	ObjVal::Float64 = tmp.obj_vals[1]
	if (ObjVal < (GUB - Compute_Epsilon(GUB)))
		tmp2 = true
	else
		tmp2 = false
	end
	tmp.fxopt = false
	tmp, ObjVal, tmp2
end

@inbounds function LB_Finder_Triangle(instance::MOOInstance, element1::OOESolution, element2::OOESolution, GUB::Float64, stats)
	tmp = OOESolution()
	tmp1::Float64 = 0.0
	tmp2::Bool = false
	tmp, tmp1, tmp2 = LB_Finder_Triangle(instance.c[1,:], instance.c[2,:], instance.c[3,:], element1.obj_vals[3], element2.obj_vals[2], instance, GUB, element1.vars, stats)
	tmp, tmp1, tmp2
end

###############################
# UPDATING LOCAL LOWER BOUNDS #
###############################
@inbounds function update_local_lower_bound(element1::OOESolution, element2::OOESolution, instance::MOOInstance, Local_LB::Float64, GUB::Float64, stats)
	updated_local_lb::Float64 = 0
	if Top_and_Bottom(element1, element2)
		fs, updated_local_lb, ubc = LB_Finder_Triangle(instance, element1, element2, GUB, stats)
		stats[:Number_MIPs] += 1
		stats[:IP_UB_Finder_Triangle] += 1
	else
		updated_local_lb = Local_LB
	end
	updated_local_lb, stats
end
