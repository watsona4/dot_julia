#####################
# POINT DIFFERENCES #
#####################
@inbounds function Top_and_Bottom(element1::OOESolution, element2::OOESolution)
tmp = false
	if element1.obj_vals[2] < element2.obj_vals[2]
		if element2.obj_vals[3] < element1.obj_vals[3]
			tmp = true
		end
	end
	tmp
end

@inbounds function Point_Difference(element3::OOESolution, element1::OOESolution, element2::OOESolution)
	Epsilon2 = 0.15
	x = false
	if length(element3.obj_vals) == 0
		return x
	end
	Point_Diff11 = abs(element2.obj_vals[2] - element3.obj_vals[2])
	Point_Diff12 = abs(element1.obj_vals[3] - element3.obj_vals[3])
	Point_Diff21 = (element2.obj_vals[2] - element1.obj_vals[2]) * Epsilon2
	Point_Diff22 = (element1.obj_vals[3] - element2.obj_vals[3]) * Epsilon2
	if (Point_Diff11 > Point_Diff21 && Point_Diff12 > Point_Diff22)
		x = true
	end
	x
end

@inbounds function Point_Difference2(Feasible_Solution::OOESolution, Feasible_Solution2::OOESolution)
	Gap_Points1 = abs(Feasible_Solution.obj_vals[2] - Feasible_Solution2.obj_vals[2])
	Gap_Points2 = abs(Feasible_Solution.obj_vals[3] - Feasible_Solution2.obj_vals[3])
	Gap_Points1, Gap_Points2
end

@inbounds function Point_Difference3(Feasible_Solution::OOESolution, Feasible_Solution2::OOESolution)
	Epsilon = 1e-5
	tmp = false
	Gap_Points1 = abs(Feasible_Solution.obj_vals[2] - Feasible_Solution2.obj_vals[2]) / abs(Feasible_Solution2.obj_vals[2])
	Gap_Points2 = abs(Feasible_Solution.obj_vals[3] - Feasible_Solution2.obj_vals[3]) / abs(Feasible_Solution2.obj_vals[3])
	if Gap_Points1 > Epsilon || Gap_Points2 > Epsilon
		tmp = true
	end
	tmp
end

@inbounds function Point_Difference4(Feasible_Solution::OOESolution, Feasible_Solution2::OOESolution; Epsilon::Float64 = 1e-4)
	tmp = false
	Gap_Points1 = abs(Feasible_Solution.obj_vals[2] - Feasible_Solution2.obj_vals[2]) / abs(Feasible_Solution2.obj_vals[2])
	Gap_Points2 = abs(Feasible_Solution.obj_vals[3] - Feasible_Solution2.obj_vals[3]) / abs(Feasible_Solution2.obj_vals[3])
	if Gap_Points1 > Epsilon && Gap_Points2 > Epsilon
		tmp = true
	end
	tmp
end

####################
# COMPUTE EPSILONS #
####################
@inbounds function Compute_Epsilon(Epsilon_Coefficient::T) where {T<:Number}
	Var_Epsilon::Float64 = 1e-6
	Var_Epsilon += abs(Epsilon_Coefficient) * 1e-6
	return Var_Epsilon
end

@inbounds function Compute_Epsilon2(Epsilon_Coefficient::T) where {T<:Number}
	Var_Epsilon::Float64 = 2e-5
	Var_Epsilon += abs(Epsilon_Coefficient) * 2e-5
	return Var_Epsilon
end

@inbounds function Compute_Epsilon3(Epsilon_Coefficient::T) where {T<:Number}
	Var_Epsilon::Float64 = 1e-5
	Var_Epsilon += abs(Epsilon_Coefficient) * 1e-5
	return Var_Epsilon
end

##################
# COMPUTE SLOPES #
##################
@inbounds function Compute_Slope(element2::OOESolution, element3::OOESolution)
	tmp::Float64 = 0.0
	tmp = (element2.obj_vals[3] - element3.obj_vals[3])/(element2.obj_vals[2] - element3.obj_vals[2] + 1e-5)
	tmp = tmp * (-2 * (Compute_Epsilon3(element3.obj_vals[2])))
	tmp += element3.obj_vals[3]
	tmp
end

@inbounds function Compute_Inverse_Slope(element1::OOESolution, element3::OOESolution)
	tmp::Float64 = 0.0
	tmp = (element1.obj_vals[2] - element3.obj_vals[2])/(element1.obj_vals[3] - element3.obj_vals[3] + 1e-5)
	tmp = tmp * (-2 * (Compute_Epsilon3(element3.obj_vals[3])))
	tmp += element3.obj_vals[2]
	tmp
end

