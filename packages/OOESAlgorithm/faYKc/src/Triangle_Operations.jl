############################
# SPLIT USING WEIGHTED SUM #
############################
@inbounds function split_triangle_using_weighted_sum(Priority_Queue::Vector{EOPriorQueue}, element::EOPriorQueue, element1::OOESolution, element2::OOESolution, instance::MOOInstance, Feasible_Solution::OOESolution,Local_LB1::Float64, Local_LB2::Float64, Local_LB::Float64, Opt_Solution::OOESolution, GUB::Float64, stats)
	Feasible_Solution_2 = Weighted_Sum(instance, Feasible_Solution, stats)
	stats[:Number_MIPs] += 1
	stats[:IP_UB_Finder_Triangle] += 1
	Feasible_Solution_3, Opt_Solution, GUB, stats = LB_Finder_Point(instance, Feasible_Solution_2, Opt_Solution, GUB, false, stats)
	Gap_Points1, Gap_Points2 = Point_Difference2(Feasible_Solution, Feasible_Solution_3)
	if (Gap_Points1 > Compute_Epsilon(Feasible_Solution.obj_vals[2]) || Gap_Points2 > Compute_Epsilon(Feasible_Solution.obj_vals[3]))
		Local_LB1, stats = update_local_lower_bound(Feasible_Solution_3, element2, instance, Local_LB, GUB, stats)
		Local_LB2, stats = update_local_lower_bound(element1, Feasible_Solution_3, instance, Local_LB, GUB, stats)
	end
	if Local_LB1 < GUB - Compute_Epsilon(GUB)
		insert_element_in_queue!(Priority_Queue, Feasible_Solution_3, element2, false, element.Direction, Local_LB1)
	end
	if Local_LB2 < GUB - Compute_Epsilon(GUB)
		insert_element_in_queue!(Priority_Queue, element1, Feasible_Solution_3, false, element.Direction, Local_LB2)
	end
	Priority_Queue, Opt_Solution, GUB, stats
end

##############################
# SPLIT USING HORIZONTAL CUT #
##############################
@inbounds function split_triangle_using_horizontal_cut(Priority_Queue::Vector{EOPriorQueue}, condition1::Bool, condition2::Bool, element1::OOESolution, element2::OOESolution, instance::MOOInstance, Feasible_Solution::OOESolution, Local_LB1::Float64, Local_LB2::Float64, Local_LB::Float64, Opt_Solution::Union{OOESolution, Vector{OOESolution}}, GUB::Float64, Feasible_Solution_3::OOESolution, Feasible_Solution_4::OOESolution, Epsilon::Float64, stats, pareto_frontier::Bool)
	Feasible_Solution_2 = Split_Triangle_Horizontal(instance, element1, element2, stats)
	stats[:Number_MIPs] += 1
	stats[:IP_UB_Finder_Triangle] += 1
	if abs(Feasible_Solution_2.obj_vals[2] - element2.obj_vals[2]) / abs(element2.obj_vals[2]) >= 1e-5
		Feasible_Solution_2 = Second_Horizontal_Step(Feasible_Solution_2, instance, stats)
		stats[:Number_MIPs] += 1
		stats[:IP_UB_Finder_Triangle] += 1
	else
		Feasible_Solution_2 = element2
		condition1 = true
	end
	if !pareto_frontier
		if Feasible_Solution_2.fxopt
		   Feasible_Solution_3 = Feasible_Solution_2
		   Opt_Solution, GUB = Update_Global_Upper_Bound(Opt_Solution, Feasible_Solution_3, GUB)
		else
		   Feasible_Solution_3, Opt_Solution, GUB, stats = LB_Finder_Point(instance, Feasible_Solution_2, Opt_Solution, GUB, false, stats)
		   condition2 = true
		end
		Update_Queue_Top!(Priority_Queue, condition1, condition2, Feasible_Solution_3)
		if (Feasible_Solution.obj_vals[2] <= element2.obj_vals[2] + Compute_Epsilon(element2.obj_vals[2]) && Feasible_Solution.obj_vals[3] <= Feasible_Solution_3.obj_vals[3] + Compute_Epsilon(Feasible_Solution_3.obj_vals[3]))
		   Local_LB1 = Local_LB
		else
		   Gap_Points1, Gap_Points2 = Point_Difference2(element2, Feasible_Solution_3)
		   if (Gap_Points1 + Gap_Points2 > abs(Epsilon * 2 * element2.obj_vals[2]))
		      Local_LB1, stats = update_local_lower_bound(Feasible_Solution_3, element2, instance, Local_LB, GUB, stats)
		   else
		      Local_LB1 = Feasible_Solution_3.obj_vals[1]
		   end
		end
	else
		Feasible_Solution_3 = Feasible_Solution_2
		insert_element_in_queue!(Opt_Solution, Feasible_Solution_3)
	end
	Slope::Float64 = Compute_Slope(element2, Feasible_Solution_3)
	if Slope < ((element1.obj_vals[3] + element2.obj_vals[3]) / 2) - Epsilon
		Feasible_Solution_4 = Third_Horizontal_Step(instance, Feasible_Solution_3, element1, element2, stats)
		stats[:Number_MIPs] += 1
		stats[:IP_UB_Finder_Triangle] += 1
		if abs(Feasible_Solution_4.obj_vals[3] - element1.obj_vals[3]) / abs(element1.obj_vals[3]) >= 1e-5
			Feasible_Solution_4 = Second_Vertical_Step(Feasible_Solution_4, instance, stats)
			stats[:Number_MIPs] += 1
			stats[:IP_UB_Finder_Triangle] += 1
		else
			Feasible_Solution_4 = element1
			condition1 = true
		end
		if !pareto_frontier
			if Feasible_Solution_4.fxopt
			   Opt_Solution, GUB = Update_Global_Upper_Bound(Opt_Solution, Feasible_Solution_4, GUB)
			else
			   Feasible_Solution_4, Opt_Solution, GUB, stats = LB_Finder_Point(instance, Feasible_Solution_4, Opt_Solution, GUB, false, stats)
			   condition2 = true
			end
			Update_Queue_Bottom!(Priority_Queue, condition1, condition2, Feasible_Solution_4)
		else
			insert_element_in_queue!(Opt_Solution, Feasible_Solution_4)
		end
	else
		Feasible_Solution_4 = Feasible_Solution_3
	end
	if !pareto_frontier
		if (Feasible_Solution.obj_vals[3] <= element1.obj_vals[3] + Compute_Epsilon(element1.obj_vals[3]) && Feasible_Solution.obj_vals[2] <= Feasible_Solution_4.obj_vals[2] + Compute_Epsilon(Feasible_Solution_4.obj_vals[2]))
			Local_LB2 = Local_LB
		else
			Gap_Points1, Gap_Points2 = Point_Difference2(element1, Feasible_Solution_4)
			if (Gap_Points1 + Gap_Points2 > abs(Epsilon * 2 * element1.obj_vals[2]))
				Local_LB2, stats = update_local_lower_bound(element1, Feasible_Solution_4, instance, Local_LB, GUB, stats)
			else
				Local_LB2 = Feasible_Solution_4.obj_vals[1]
			end
		end
		if Local_LB2 < GUB - Compute_Epsilon(GUB) && Point_Difference4(element1, Feasible_Solution_4) && Point_Difference4(element2, Feasible_Solution_4)
			insert_element_in_queue!(Priority_Queue, element1, Feasible_Solution_4, false, true, Local_LB2)
		end
		if Local_LB1 < GUB - Compute_Epsilon(GUB) && Point_Difference4(element2, Feasible_Solution_3)
			insert_element_in_queue!(Priority_Queue, Feasible_Solution_3, element2, false, true, Local_LB1)
		end
	else
		if Point_Difference4(element1, Feasible_Solution_4) && Point_Difference4(element2, Feasible_Solution_4)
			insert_element_in_queue!(Priority_Queue, element1, Feasible_Solution_4, false, true, Local_LB2)
		end
		if Point_Difference4(element2, Feasible_Solution_3)
			insert_element_in_queue!(Priority_Queue, Feasible_Solution_3, element2, false, true, Local_LB1)
		end
	end
	Priority_Queue, Opt_Solution, GUB, stats
end

############################
# SPLIT USING VERTICAL CUT #
############################
@inbounds function split_triangle_using_vertical_cut(Priority_Queue::Vector{EOPriorQueue}, condition1::Bool, condition2::Bool, element1::OOESolution, element2::OOESolution, instance::MOOInstance, Feasible_Solution::OOESolution, Local_LB1::Float64, Local_LB2::Float64, Local_LB::Float64, Opt_Solution::Union{OOESolution, Vector{OOESolution}}, GUB::Float64, Feasible_Solution_3::OOESolution, Feasible_Solution_4::OOESolution, Epsilon::Float64, stats, pareto_frontier::Bool)
	Feasible_Solution_2 = Split_Triangle_Vertical(instance, element1, element2, stats)
	stats[:Number_MIPs] += 1
	stats[:IP_UB_Finder_Triangle] += 1
	if abs(Feasible_Solution_2.obj_vals[3] - element1.obj_vals[3]) / abs(element1.obj_vals[3]) >= 1e-5
		Feasible_Solution_2 = Second_Vertical_Step(Feasible_Solution_2, instance, stats)
		stats[:Number_MIPs] += 1
		stats[:IP_UB_Finder_Triangle] += 1
	else
		Feasible_Solution_2 = element1
		condition1 = true
	end
	if !pareto_frontier
		if Feasible_Solution_2.fxopt
		   Feasible_Solution_3 = Feasible_Solution_2
		   Opt_Solution, GUB = Update_Global_Upper_Bound(Opt_Solution, Feasible_Solution_3, GUB)
		else
		   Feasible_Solution_3, Opt_Solution, GUB, stats = LB_Finder_Point(instance, Feasible_Solution_2, Opt_Solution, GUB, false, stats)
		   condition2 = true
		end
		Update_Queue_Bottom!(Priority_Queue, condition1, condition2, Feasible_Solution_3)
		if (Feasible_Solution.obj_vals[3] <= element1.obj_vals[3] + Compute_Epsilon(element1.obj_vals[3]) && Feasible_Solution.obj_vals[2] <= Feasible_Solution_3.obj_vals[2] + Compute_Epsilon(Feasible_Solution_3.obj_vals[2]))
		   Local_LB2 = Local_LB
		else
		   Gap_Points1, Gap_Points2 = Point_Difference2(element1, Feasible_Solution_3)
		   if (Gap_Points1 + Gap_Points2 > abs(Epsilon * 2 * element1.obj_vals[2]))
		      Local_LB2, stats = update_local_lower_bound(element1, Feasible_Solution_3, instance, Local_LB, GUB, stats)
		   else
		      Local_LB2 = Feasible_Solution_3.obj_vals[1]
		   end
		end
	else
		Feasible_Solution_3 = Feasible_Solution_2
		insert_element_in_queue!(Opt_Solution, Feasible_Solution_3)
	end
	Inverse_Slope::Float64 = Compute_Inverse_Slope(element1, Feasible_Solution_3)
	if Inverse_Slope < ((element1.obj_vals[2] + element2.obj_vals[2]) / 2) - Epsilon
		Feasible_Solution_4 = Third_Vertical_Step(instance, Feasible_Solution_3, element1, element2, stats)
		stats[:Number_MIPs] += 1
		stats[:IP_UB_Finder_Triangle] += 1
		if abs(Feasible_Solution_4.obj_vals[2] - element2.obj_vals[2]) / abs(element2.obj_vals[2]) >= 1e-5
			Feasible_Solution_4 = Second_Horizontal_Step(Feasible_Solution_4, instance, stats)
			stats[:Number_MIPs] += 1
			stats[:IP_UB_Finder_Triangle] += 1
		else
			Feasible_Solution_4 = element2
			condition1 = true
		end
		if !pareto_frontier
			if Feasible_Solution_4.fxopt
				Opt_Solution, GUB = Update_Global_Upper_Bound(Opt_Solution, Feasible_Solution_4, GUB)
			else
				Feasible_Solution_4, Opt_Solution, GUB, stats = LB_Finder_Point(instance, Feasible_Solution_4, Opt_Solution, GUB, false, stats)
				condition2 = true
			end
			Update_Queue_Top!(Priority_Queue, condition1, condition2, Feasible_Solution_4)
		else
			insert_element_in_queue!(Opt_Solution, Feasible_Solution_4)
		end
	else
		Feasible_Solution_4 = Feasible_Solution_3
	end
	if !pareto_frontier
		if (Feasible_Solution.obj_vals[2] <= element2.obj_vals[2] + Compute_Epsilon(element2.obj_vals[2]) && Feasible_Solution.obj_vals[3] <= Feasible_Solution_4.obj_vals[3] + Compute_Epsilon(Feasible_Solution_4.obj_vals[3]))
			Local_LB1 = Local_LB
		else
			Gap_Points1, Gap_Points2 = Point_Difference2(element2, Feasible_Solution_4)
			if (Gap_Points1 + Gap_Points2 > abs(Epsilon * 2 * element1.obj_vals[2]))
				Local_LB1, stats = update_local_lower_bound(Feasible_Solution_4, element2, instance, Local_LB, GUB, stats)
			else
				Local_LB1 = Feasible_Solution_4.obj_vals[1]
			end
		end
		if Local_LB2 < GUB - Compute_Epsilon(GUB) && Point_Difference4(element1, Feasible_Solution_3) 
			insert_element_in_queue!(Priority_Queue, element1, Feasible_Solution_3, false, false, Local_LB2)
		end
		if Local_LB1 < GUB - Compute_Epsilon(GUB) && Point_Difference4(element2, Feasible_Solution_4)  && Point_Difference4(element1, Feasible_Solution_4)
			insert_element_in_queue!(Priority_Queue, Feasible_Solution_4, element2, false, false, Local_LB1)
		end
	else
		if Point_Difference4(element1, Feasible_Solution_3) 
			insert_element_in_queue!(Priority_Queue, element1, Feasible_Solution_3, false, false, Local_LB2)
		end
		if Point_Difference4(element2, Feasible_Solution_4)  && Point_Difference4(element1, Feasible_Solution_4)
			insert_element_in_queue!(Priority_Queue, Feasible_Solution_4, element2, false, false, Local_LB1)
		end
	end
	Priority_Queue, Opt_Solution, GUB, stats
end

################################
# TRIANGLE SPLITTING ALGORITHM #
################################
@inbounds function Triangle_Splitting_Algorithm(Priority_Queue::Vector{EOPriorQueue}, element::EOPriorQueue, Connection_Index::Bool, Partial_Connection::Bool, instance::MOOInstance, Opt_Solution::Union{OOESolution, Vector{OOESolution}}, element1::OOESolution, element2::OOESolution, GUB::Float64, Epsilon::Float64, stats, pareto_frontier::Bool)
	if (Connection_Index == false || Partial_Connection == true) && (Top_and_Bottom(element1, element2))
		t0 = time()
		stats[:N_Finder_Triangle] += 1
		Feasible_Solution, Local_LB, Upper_Bound_Condition = OOESolution(), 0.0, true
		if !pareto_frontier
			Feasible_Solution, Local_LB, Upper_Bound_Condition = LB_Finder_Triangle(instance, element1, element2, GUB, stats)
		end
		stats[:Number_MIPs] += 1
		stats[:IP_Finder_Triangle] += 1
		stats[:Time_Finder_Triangle] += time() - t0
		Local_LB1::Float64 = Local_LB
		Local_LB2::Float64 = Local_LB
		if Upper_Bound_Condition
			t0 = time()
			stats[:N_UB_Finder_Triangle] += 1
			if Point_Difference(Feasible_Solution, element1, element2)
				Priority_Queue, Opt_Solution, GUB, stats = split_triangle_using_weighted_sum(Priority_Queue, element, element1, element2, instance, Feasible_Solution, Local_LB1, Local_LB2, Local_LB, Opt_Solution, GUB, stats)
			else
				condition1::Bool = false
				condition2::Bool = false
				Feasible_Solution_3 = OOESolution()
				Feasible_Solution_4 = OOESolution()
				if element.Direction == false
					Priority_Queue, Opt_Solution, GUB, stats = split_triangle_using_horizontal_cut(Priority_Queue, condition1, condition2, element1, element2, instance, Feasible_Solution, Local_LB1, Local_LB2, Local_LB, Opt_Solution, GUB, Feasible_Solution_3, Feasible_Solution_4, Epsilon, stats, pareto_frontier)	
				else
					Priority_Queue, Opt_Solution, GUB, stats = split_triangle_using_vertical_cut(Priority_Queue, condition1, condition2, element1, element2, instance, Feasible_Solution, Local_LB1, Local_LB2, Local_LB, Opt_Solution, GUB, Feasible_Solution_3, Feasible_Solution_4, Epsilon, stats, pareto_frontier)
				end
			end
			stats[:Time_UB_Finder_Triangle] += time() - t0
		end
	end
	Priority_Queue, Opt_Solution, GUB, stats
end
