######################################
# DUPLICATE MODEL FOR LINE DETECTION #
######################################
@inbounds function counting(instance::MOOInstance)
	x = 0
	y = 0
	for i in 1:length(instance.var_types)
		if instance.var_types[i] == :Cont
			x += 1
		end
	end
	y = length(instance.var_types) - x
	x, y
end

@inbounds function Duplicate_Instance!(instance2::MOOInstance,instance::MOOInstance, number_of_cont_variables::Int64)
	for i in 1:length(instance.var_types)
		if instance.var_types[i] == :Cont
			instance2.var_types = vcat(instance2.var_types, instance2.var_types[i])
			instance2.v_lb = vcat(instance2.v_lb,instance2.v_lb[i])
			instance2.v_ub = vcat(instance2.v_ub,instance2.v_ub[i])
		end
	end	
	instance2.c = vcat(hcat(instance2.c,zeros(Float64,(3,number_of_cont_variables))),zeros(Float64,(2,length(instance.var_types)+number_of_cont_variables)))
	instance2.A = vcat(hcat(instance.A,zeros(Float64,(size(instance.A,1),number_of_cont_variables))),zeros(Float64,(size(instance.A,1),length(instance.var_types)+number_of_cont_variables)))
	j = length(instance.var_types) + 1
	for i in 1:length(instance.var_types)
		if instance.var_types[i] != :Cont
			instance2.c[4:5, i] = instance2.c[2:3, i]
			instance2.A[size(instance.A,1) + 1:size(instance2.A,1), i] = instance2.A[1:size(instance.A,1), i]
		else
			instance2.c[4:5, j] = instance2.c[2:3, i]
			instance2.A[size(instance.A,1) + 1:size(instance2.A,1), j] = instance2.A[1:size(instance.A,1), i]
			j += 1
		end
	end	
	instance2.cons_lb= vcat(instance2.cons_lb,instance2.cons_lb)
	instance2.cons_ub= vcat(instance2.cons_ub,instance2.cons_ub)
end

###########################
# LINE DETECTOR OPERATION #
###########################
@inbounds function Line_Detector(c2::Vector{T}, c3::Vector{T}, c4::Vector{T}, c5::Vector{T}, bound12::T, bound13::T, bound22::T, bound23::T, number_of_cont_variables::Int64, instance::MOOInstance, instance2::MOOInstance, initial_solution::Vector{T}, stats) where {T<:Number}
	tmp = OOESolution()
	tmp2 = zeros(Float64, length(instance2.var_types))
        lambda1 = bound13 - bound23
        lambda2 = bound22 - bound12
        lambda3 = (lambda1 * bound12) + (lambda2 * bound13)
	model = MathProgBase.LinearQuadraticModel(stats[:solver])
	MathProgBase.loadproblem!(model, instance2.A, instance2.v_lb, instance2.v_ub, c4, instance2.cons_lb, instance2.cons_ub, :Max)
	MathProgBase.setvartype!(model, instance2.var_types)
	inds = findall(x -> x!="0.0", c2)
	MathProgBase.addconstr!(model, inds, c2[inds], -Inf, bound12 + Compute_Epsilon(bound12))
	inds = findall(x -> x!="0.0", c3)
	MathProgBase.addconstr!(model, inds, c3[inds], -Inf, bound13 + Compute_Epsilon(bound13))
	c6 = (lambda1*c4) + (lambda2*c5)
	inds = findall(x -> x!="0.0", c6)
	MathProgBase.addconstr!(model, inds, c6[inds], -Inf, lambda3 + 1e-5)
	MathProgBase.optimize!(model)
	try
		tmp2 = MathProgBase.getsolution(model)
	catch
		tmp2 = initial_solution
	end
	tmp.vars = zeros(Float64, length(instance.var_types))
	j = length(instance.var_types) + 1
	for i in 1:length(instance.var_types)
		if instance2.var_types[i] != :Cont
			tmp.vars[i] = tmp2[i]
		else
			tmp.vars[i] = tmp2[j]
			j += 1
		end
	end
	compute_objective_function_value!(tmp, instance)
	tmp.fxopt = false	
	tmp
end

@inbounds function Line_Detector(instance2::MOOInstance, instance::MOOInstance, element1::OOESolution, element2::OOESolution, number_of_cont_variables::Int64, stats)
	tmp = OOESolution()
	Connection_Index::Bool = false
	Partial_Connection::Bool = false
	for i in 1:length(instance.var_types)
		if instance.var_types[i] == :Cont
			element1.vars = vcat(element1.vars, element1.vars[i])
		end
	end
	tmp = Line_Detector(instance2.c[2,:], instance2.c[3,:], instance2.c[4,:], instance2.c[5,:], element1.obj_vals[2], element1.obj_vals[3], element2.obj_vals[2], element2.obj_vals[3], number_of_cont_variables, instance, instance2, element1.vars, stats)
	element1.vars =  element1.vars[1:length(instance.var_types)]
	if (tmp.obj_vals[2] >= (element2.obj_vals[2] - Compute_Epsilon3(element2.obj_vals[2])))
		Connection_Index = true
	elseif (tmp.obj_vals[2] > (element1.obj_vals[2] + Compute_Epsilon3(element1.obj_vals[2])))
		Connection_Index = true
		Partial_Connection = true
	end
	tmp, Connection_Index, Partial_Connection
end

###############################
# LINE DETECTOR PREPROCESSING #
###############################
@inbounds function Line_Detector_Preprocessing_1(element1::OOESolution, element2::OOESolution, instance::MOOInstance)
	tmp::Float64 = 0.0
	sw::Bool = false
	for i in 1:length(instance.var_types)
		if instance.var_types[i] != :Cont
			tmp += abs(element1.vars[i] - element2.vars[i])
		end
	end
	if tmp <= 1e-5
		sw = true
	end
	sw
end

@inbounds function Line_Detector_Preprocessing_2(element1::OOESolution, element2::OOESolution, instance::MOOInstance, number_of_int_or_bin_variables::Int64)
	tmp::Int64 = 0
	tmp2::Float64 = 0.0
	sw::Bool = false
	for i in 1:length(instance.var_types)
		if instance.var_types[i] != :Cont && abs(element1.vars[i] - element2.vars[i]) <= 1e-5
			tmp += 1
		end
	end
	tmp2 = tmp / number_of_int_or_bin_variables
	if tmp2 < 1 - 0.05
		sw = true
	end
	sw
end

#########################
# LINE DETECTOR PROCESS #
#########################
@inbounds function Line_Detector_Process(number_of_cont_variables::Int64 , number_of_int_or_bin_variables::Int64, sw::Bool, Feasible_Solution::OOESolution, Connection_Index::Bool, Partial_Connection::Bool, instance2::MOOInstance, instance::MOOInstance, element1::OOESolution, element2::OOESolution, stats)
	if number_of_cont_variables > 0 && number_of_int_or_bin_variables > 0
		stats[:N_Line_Detector] += 1
		sw = Line_Detector_Preprocessing_1(element1, element2, instance)
		if sw == false
			sw = Line_Detector_Preprocessing_2(element1, element2, instance, number_of_int_or_bin_variables)
		else
			Connection_Index = true
		end
	elseif number_of_cont_variables == 0
		sw = true
	else
		sw = true
		Connection_Index = true
	end
	if sw == false
		Feasible_Solution, Connection_Index, Partial_Connection = Line_Detector(instance2, instance, element1, element2, number_of_cont_variables, stats)
		stats[:Number_MIPs] += 1
		stats[:IP_Line_Detector] += 1
	end
	Feasible_Solution, Connection_Index, Partial_Connection, stats
end
