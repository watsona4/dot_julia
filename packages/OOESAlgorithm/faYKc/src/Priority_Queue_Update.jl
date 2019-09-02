#######################################
# UPDATING ELEMENTS IN PRIORITY QUEUE #
#######################################
@inbounds function insert_element_in_queue!(Priority_Queue::Vector{EOPriorQueue}, Sol_Top::OOESolution, Sol_Bottom::OOESolution, Shape::Bool, Direction::Bool, LBound::Float64)
	tmp = EOPriorQueue()
	tmp.Sol_Top = Sol_Top
	tmp.Sol_Bottom = Sol_Bottom
	tmp.Shape = Shape
    	tmp.Direction = Direction
    	tmp.LBound = LBound
	if length(Priority_Queue) > 0
		x = 1
		sw = false
		while LBound > Priority_Queue[x].LBound
			if x == length(Priority_Queue)
				push!(Priority_Queue, tmp)
				sw = true
				break
			end
			x += 1
		end
		if sw == false
			insert!(Priority_Queue, x, tmp)
		end
	else
		push!(Priority_Queue, tmp)
	end
end

@inbounds function insert_element_in_queue!(Opt_Solution::Vector{OOESolution}, nondominated_point::OOESolution)
	if length(Opt_Solution) > 0
		x = 1
		sw = false
		while nondominated_point.obj_vals[3] < Opt_Solution[x].obj_vals[3]
			if x == length(Opt_Solution)
				push!(Opt_Solution, nondominated_point)
				sw = true
				break
			end
			x += 1
		end
		if sw == false
			insert!(Opt_Solution, x, nondominated_point)
		end
	else
		push!(Opt_Solution, nondominated_point)
	end
end

@inbounds function indicate_line!(Opt_Solution::Vector{OOESolution}, nondominated_point::OOESolution)
	x = 1
	sw = false
	while nondominated_point.obj_vals[3] < Opt_Solution[x].obj_vals[3]
		x += 1
	end
	Opt_Solution[x-1].fxopt = true
end

@inbounds function Update_Queue_Top!(Priority_Queue::Vector{EOPriorQueue}, Condition1::Bool, Condition2::Bool, Feasible_Solution::OOESolution)
	x = 1
	sw = false
	if Condition1 == true && Condition2 == true
		while x <= length(Priority_Queue) && sw == false
			if Point_Difference4(Feasible_Solution, Priority_Queue[x].Sol_Top, Epsilon = 1e-5)
				x += 1
			else
				Priority_Queue[x].Sol_Top = Feasible_Solution
				sw = true
			end
		end
	end
end


@inbounds function Update_Queue_Bottom!(Priority_Queue::Vector{EOPriorQueue}, Condition1::Bool, Condition2::Bool, Feasible_Solution::OOESolution)
	x = 1
	sw = false
	if Condition1 == true && Condition2 == true
		while x <= length(Priority_Queue) && sw == false
			if Point_Difference4(Feasible_Solution, Priority_Queue[x].Sol_Bottom, Epsilon = 1e-5)
				x += 1
			else
				Priority_Queue[x].Sol_Bottom = Feasible_Solution
				sw = true
			end
		end
	end
end

@inbounds function Update_Global_Upper_Bound(Opt_Solution::OOESolution, Feasible_Solution::OOESolution, GUB::Float64)
	if (Feasible_Solution.obj_vals[1] < GUB)
		Opt_Solution = Feasible_Solution
		GUB = Opt_Solution.obj_vals[1]
	end
	Opt_Solution, GUB
end

@inbounds function first_element_of_the_queue(Priority_Queue::Vector{EOPriorQueue})
	element = Priority_Queue[1]
	element1 = element.Sol_Top
	element2 = element.Sol_Bottom
	popfirst!(Priority_Queue)
	element, element1, element2, Priority_Queue
end

@inbounds function type_of_output(pareto_frontier::Bool)
	if pareto_frontier
		temp = OOESolution[]
		return temp
	else
		temp = OOESolution()
		return temp
	end
end

@inbounds function type_of_output(threads::Int64, parallelization::Int64, pareto_frontier::Bool)
	if pareto_frontier
		if parallelization != 4
			temp = fill(Opt_Pareto_Solutions(), threads)
			return temp	
		else
			temp = fill(Parallel_Pareto_Solutions(), threads)
			return temp
		end	
	else
		if parallelization != 4
			temp = fill(Opt_Solutions(), threads)
			return temp
		else
			temp = fill(Parallel_Solutions(), threads)
			return temp
		end
	end
end
