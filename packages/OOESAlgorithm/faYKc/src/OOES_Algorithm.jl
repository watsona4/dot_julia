#using Distributed, MathOptInterface, JuMP, MathProgBase, GLPK, GLPKMathProgInterface, Pkg, SparseArrays

include("Storage.jl")
include("Read_Instances.jl")
include("Point_Differences_Epsilons.jl")
include("Priority_Queue_Update.jl")
include("Initial_Operations.jl")
include("Weighted_Sum_Method.jl")
include("Line_Detector.jl")
include("LB_Finder_Operations.jl")
include("Splitting_Triangle.jl")
include("Triangle_Operations.jl")
include("Parallelization.jl")
include("Exploring_Queue.jl")
include("Writing_Results.jl")

#################
# THE ALGORITHM #
#################
@inbounds function OOES(instance::MOOInstance, instance2::MOOInstance, Partial_Solutions::Vector{OOESolution}, Priority_Queue::Vector{EOPriorQueue}, Opt_Solution::Union{OOESolution, Vector{OOESolution}}, number_of_cont_variables::Int64, number_of_int_or_bin_variables::Int64, GUB::Float64, initial_time::Float64, timelimit::Float64, threads::Int64, parallelization::Int64, stats, pareto_frontier::Bool)
	Search_Done::Bool = false
	Epsilon::Float64 = 1e-5
	Epsilon6::Float64 = 1e-5
	GLB::Float64 = -1e10
	Feasible_Solution = OOESolution()
	while (length(Priority_Queue) > 0) && (Search_Done == false) && (time() - initial_time <= timelimit)

		GLB = Priority_Queue[1].LBound
		Relative_Gap = abs(GUB - GLB) / (abs(GUB) + Epsilon)
		stats[:iteration] += 1
		if (Relative_Gap < Epsilon6) || (GUB <= GLB + Epsilon6)
			Search_Done = true;
		elseif threads > 1 && parallelization == 4
			threads_to_use::Int64 = min(length(Priority_Queue), threads)
			num_threads::Vector{Int64} = setdiff(procs(), myid())[1:threads_to_use]
			Priority_Queue_Vector::Vector{Vector{EOPriorQueue}} = fill(EOPriorQueue[], threads_to_use)
			tmp_stats = initialize_statistics(stats[:solver])	
			for i in 1:threads_to_use
				Priority_Queue_Vector[i] = [Priority_Queue[1]]
				popfirst!(Priority_Queue)
			end
			vector_of_solutions = type_of_output(length(num_threads), parallelization, pareto_frontier)
			@sync begin
				for i in 1:threads_to_use
					@async begin
						vector_of_solutions[i] = remotecall_fetch(parallel_exploring_1st_element_of_queue, num_threads[i], copy(instance), copy(instance2), Partial_Solutions, Priority_Queue_Vector[i], number_of_cont_variables, number_of_int_or_bin_variables, Feasible_Solution, Opt_Solution, GUB, timelimit, tmp_stats, pareto_frontier)
					end
				end
			end
			if !pareto_frontier
				Opt_Solution, GUB = vector_of_solutions[1].Opt_Solution, vector_of_solutions[1].GUB
				if threads_to_use > 1
					for i in 2:threads_to_use
						if vector_of_solutions[i].Opt_Solution.obj_vals[1] < Opt_Solution.obj_vals[1]
							Opt_Solution = vector_of_solutions[i].Opt_Solution
						end
						if vector_of_solutions[i].GUB < GUB
							GUB = vector_of_solutions[i].GUB
						end
					end
				end
			else
				for i in 1:threads_to_use
					for j in 1:length(vector_of_solutions[i].Opt_Solution)
						if j > 1 && j <length(vector_of_solutions[i].Opt_Solution)
							insert_element_in_queue!(Opt_Solution, vector_of_solutions[i].Opt_Solution[j])
						end
					end
				end
			end
			for i in 1:threads_to_use
				stats = parallel_statistics(stats, vector_of_solutions[i].stats)
				for j in 1:length(vector_of_solutions[i].Priority_Queue)
					insert_element_in_queue!(Priority_Queue, vector_of_solutions[i].Priority_Queue[j].Sol_Top, vector_of_solutions[i].Priority_Queue[j].Sol_Bottom, vector_of_solutions[i].Priority_Queue[j].Shape, vector_of_solutions[i].Priority_Queue[j].Direction, vector_of_solutions[i].Priority_Queue[j].LBound)
				end
			end
		else
			Priority_Queue, Partial_Solutions, Opt_Solution, GUB, stats = exploring_1st_element_of_queue(instance, instance2, Partial_Solutions, Priority_Queue, number_of_cont_variables, number_of_int_or_bin_variables, Feasible_Solution, Opt_Solution, GUB, timelimit, stats, pareto_frontier)
		end
	end
	if !pareto_frontier
		GLB = Opt_Solution.obj_vals[1]
		if (length(Priority_Queue) > 0) && (time() - initial_time > timelimit)
			GLB = Priority_Queue[1].LBound
		end
	end
	Opt_Solution, stats, GLB
end

@inbounds function OOES(instance::MOOInstance, instance2::MOOInstance, Partial_Solutions::Vector{OOESolution}, number_of_cont_variables::Int64, number_of_int_or_bin_variables::Int64, initial_time::Float64, timelimit::Float64, threads::Int64, parallelization::Int64, stats, pareto_frontier::Bool)
	GUB::Float64 = 1e10
	Opt_Solution = type_of_output(pareto_frontier)
	Priority_Queue::Vector{EOPriorQueue} = EOPriorQueue[]
	if length(Partial_Solutions) > 0
		if !pareto_frontier
			for i in 1:length(Partial_Solutions)
				Opt_Solution, GUB = Update_Global_Upper_Bound(Opt_Solution, Partial_Solutions[i], GUB)
			end
		else
			for i in 1:length(Partial_Solutions)
				insert_element_in_queue!(Opt_Solution, Partial_Solutions[i])
			end
		end
		insert_element_in_queue!(Priority_Queue, Partial_Solutions[1], Partial_Solutions[2], false, false, -1e10)
		popfirst!(Partial_Solutions)
		popfirst!(Partial_Solutions)
		Opt_Solution, stats, GLB = OOES(instance, instance2, Partial_Solutions, Priority_Queue, Opt_Solution, number_of_cont_variables, number_of_int_or_bin_variables, GUB, initial_time, timelimit, threads, parallelization, stats, pareto_frontier)
		if threads == 1 || (threads > 1 && parallelization == 4)
			return Opt_Solution, stats, GLB
		else
			if !pareto_frontier
				final_results = Opt_Solutions()
				final_results.tmp_solution = Opt_Solution
				final_results.stats = stats
				final_results.GLB = GLB
				return final_results
			else
				final_results = Opt_Pareto_Solutions()
				final_results.tmp_solution = Opt_Solution
				final_results.stats = stats
				final_results.GLB = GLB
				return final_results
			end
		end
	else
		println("Infeasible")
	end
end

#####################
# INITIAL ALGORITHM #
#####################
@inbounds function OOES(instance::MOOInstance, sense::Array{Symbol,1}, mip_solver::MathProgBase.SolverInterface.AbstractMathProgSolver, threads::Int64, parallelization::Int64, timelimit::Float64, pareto_frontier::Bool)
   GLB::Float64 = -1e10
   if threads > 1 && threads > length(procs())-1
      println("")
      println("Please, make sure to setup the number of threads correctly")
   else
      if threads > 1 && parallelization == 4 && pareto_frontier
	      println("")
	      println("Please, select a different parallelization type")
      else
	      initial_time::Float64 = time()
	      instance2, Partial_Solutions, number_of_cont_variables, number_of_int_or_bin_variables, stats = OOES_warm_up(instance, mip_solver, pareto_frontier)
	      if threads == 1 || (threads > 1 && parallelization == 4)
		 Opt_Solution, stats, GLB = OOES(instance, instance2, Partial_Solutions, number_of_cont_variables, number_of_int_or_bin_variables, initial_time, timelimit, threads, parallelization, stats, pareto_frontier)
	      else
		 Opt_Solution, stats, GLB = OOES_parallel(instance, instance2, Partial_Solutions, number_of_cont_variables, number_of_int_or_bin_variables, threads, parallelization, initial_time, timelimit, stats, pareto_frontier)
	      end
	      Total_Time = time() - initial_time
	      for i in 1:length(sense)
		 if sense[i] == :Max
			if !pareto_frontier
			    Opt_Solution.obj_vals[i] = -1.0*Opt_Solution.obj_vals[i]
			else
			    for j in 1:length(Opt_Solution)
			    	Opt_Solution[j].obj_vals[i] = -1.0*Opt_Solution[j].obj_vals[i]
			    end
			end
		 end
	      end
	      Writing_The_Output_File(Opt_Solution, Total_Time, threads, stats, GLB, pareto_frontier)
	      return Opt_Solution
      end
   end
end

###################################
# READING INSTANCE FROM JuMP FILE #
###################################
@inbounds function OOES(model::JuMP.Model; mipsolver::Int64=1, mip_solver::MathProgBase.SolverInterface.AbstractMathProgSolver=GLPKSolverMIP(), threads::Int64=1, parallelization::Int64=1, timelimit::Float64=86400.0, relative_gap::Float64=1.0e-6, sense::Array{Symbol,1} = [:Min, :Min, :Min], pareto_frontier::Bool=false)
   mip_solver = solver_selection(mipsolver, mip_solver, relative_gap)
   instance, sense = read_an_instance_from_a_jump_model(model, sense)
   OOES(instance, sense, mip_solver, threads, parallelization, timelimit, pareto_frontier)
end

########################################
# READING INSTANCE FROM LP OR MPS FILE #
########################################
@inbounds function OOES(filename::String; mipsolver::Int64=1, mip_solver::MathProgBase.SolverInterface.AbstractMathProgSolver=GLPKSolverMIP(), threads::Int64=1, parallelization::Int64=1, timelimit::Float64=86400.0, relative_gap::Float64=1.0e-6, sense::Array{Symbol,1} = [:Min, :Min, :Min], pareto_frontier::Bool=false)
   mip_solver = solver_selection(mipsolver, mip_solver, relative_gap)
   instance, sense = read_an_instance_from_a_lp_or_a_mps_file(filename, sense)
   OOES(instance, sense, mip_solver, threads, parallelization, timelimit, pareto_frontier)
end
