############################################
# OPERATIONS ON FIRST ELEMENT OF THE QUEUE #
############################################
@inbounds function operations_on_first_element(instance::MOOInstance, instance2::MOOInstance, Partial_Solutions::Vector{OOESolution}, Priority_Queue::Vector{EOPriorQueue}, number_of_cont_variables::Int64, number_of_int_or_bin_variables::Int64, Feasible_Solution::OOESolution, Opt_Solution::Union{OOESolution, Vector{OOESolution}}, GUB::Float64, timelimit::Float64, stats, pareto_frontier::Bool)
	Epsilon::Float64 = 1e-5
	sw::Bool = false
	element, element1, element2, Priority_Queue = first_element_of_the_queue(Priority_Queue)
	gap_points1, gap_Points2 = Point_Difference2(element1, element2)
	if gap_points1 + gap_Points2 < Epsilon * 2
		t0 = time()
		stats[:N_Finder_Point] += 1
		if !pareto_frontier
			Feasible_Solution, Opt_Solution, GUB, stats = LB_Finder_Point(instance, element1, Opt_Solution, GUB, true, stats)
		end
		stats[:Time_Finder_Point] += time() - t0
	elseif (element.Shape == false)
		t0 = time()
		stats[:N_Weighted_Sum] += 1
		counter_solutions::Int64 = 1
		Partial_Solutions, counter_solutions, stats = Weighted_Sum_Method(Partial_Solutions, counter_solutions, sw, instance, element1, element2, stats)
		Priority_Queue, Partial_Solutions, Opt_Solution = Weighted_Sum_Update(Priority_Queue, Partial_Solutions, counter_solutions, element, Opt_Solution, pareto_frontier)
		stats[:Time_Weighted_Sum] += time() - t0
	else
		t0 = time()
		Connection_Index::Bool = false
		Partial_Connection::Bool = false
		Feasible_Solution, Connection_Index, Partial_Connection, stats = Line_Detector_Process(number_of_cont_variables, number_of_int_or_bin_variables, sw, Feasible_Solution, Connection_Index, Partial_Connection, instance2, instance, element1, element2, stats)
		stats[:Time_Line_Detector] += time() - t0
		if !pareto_frontier
			element1, Opt_Solution, GUB, stats = LB_Finder_Line(Connection_Index, Partial_Connection, Feasible_Solution, instance, element1, element2, Opt_Solution, GUB, stats)
		else
			if Partial_Connection
				insert_element_in_queue!(Opt_Solution, Feasible_Solution)
				indicate_line!(Opt_Solution, Feasible_Solution)
			elseif Connection_Index
				indicate_line!(Opt_Solution, element2)
			end
		end
		Priority_Queue, Opt_Solution, GUB, stats = Triangle_Splitting_Algorithm(Priority_Queue, element, Connection_Index, Partial_Connection, instance, Opt_Solution, element1, element2, GUB, Epsilon, stats, pareto_frontier)
	end
	Priority_Queue, Partial_Solutions, Opt_Solution, GUB, stats
end

########################################
# EXPLORING FIRST ELEMENT OF THE QUEUE #
########################################
@inbounds function exploring_1st_element_of_queue(instance::MOOInstance, instance2::MOOInstance, Partial_Solutions::Vector{OOESolution}, Priority_Queue::Vector{EOPriorQueue}, number_of_cont_variables::Int64, number_of_int_or_bin_variables::Int64, Feasible_Solution::OOESolution, Opt_Solution::Union{OOESolution, Vector{OOESolution}}, GUB::Float64, timelimit::Float64, stats, pareto_frontier::Bool)
	Priority_Queue, Partial_Solutions, Opt_Solution, GUB, stats = operations_on_first_element(instance, instance2, Partial_Solutions, Priority_Queue, number_of_cont_variables, number_of_int_or_bin_variables, Feasible_Solution, Opt_Solution, GUB, timelimit, stats, pareto_frontier)
	Priority_Queue, Partial_Solutions, Opt_Solution, GUB, stats
end

####################################################
# EXPLORING FIRST ELEMENT OF THE QUEUE IN PARALLEL #
####################################################
@inbounds function parallel_exploring_1st_element_of_queue(instance::MOOInstance, instance2::MOOInstance, Partial_Solutions::Vector{OOESolution}, Priority_Queue::Vector{EOPriorQueue}, number_of_cont_variables::Int64, number_of_int_or_bin_variables::Int64, Feasible_Solution::OOESolution, Opt_Solution::Union{OOESolution, Vector{OOESolution}}, GUB::Float64, timelimit::Float64, stats, pareto_frontier::Bool)
	Priority_Queue, Partial_Solutions, Opt_Solution, GUB, stats = operations_on_first_element(instance, instance2, Partial_Solutions, Priority_Queue, number_of_cont_variables, number_of_int_or_bin_variables, Feasible_Solution, Opt_Solution, GUB, timelimit, stats, pareto_frontier)
	if !pareto_frontier
		final_results = Parallel_Solutions()
		final_results.Priority_Queue = Priority_Queue
		final_results.Partial_Solutions = Partial_Solutions
		final_results.Opt_Solution = Opt_Solution
		final_results.GUB = GUB
		final_results.stats = stats
		return 	final_results
	else
		final_results = Parallel_Pareto_Solutions()
		final_results.Priority_Queue = Priority_Queue
		final_results.Partial_Solutions = Partial_Solutions
		final_results.Opt_Solution = Opt_Solution
		final_results.GUB = GUB
		final_results.stats = stats
		return 	final_results
	end	
end
