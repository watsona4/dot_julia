# MIT License
# Copyright (c) 2017: Xavier Gandibleux, Anthony Przybylski, Gauthier Soleilhac, and contributors.

# ==========================================================================
# vOpt solver
#   Part of the open source prototype issued from the ANR-DFG research project
# Coordinator:
#   Xavier.Gandibleux@univ-nantes.fr
# --------------------------------------------------------------------------
# Content of this package:
#   Exact algorithm for solving the 1/./(sumCi , Tmax) scheduling problem
# Contributor(s):
#   Pauline Chatellier-Bertin
#   Xavier Gandibleux
# Version and Release date:
#   V0.1 - April 28, 2017
# ==========================================================================

# ==========================================================================
# Types and structures
# ==========================================================================
# Environment variables
struct t_environment
	# for display's options: false => mute, true => verbose
	displayYN      :: Bool # display the generation of all efficient solutions and non-dominated points
	displayPrint   :: Bool # display all the prints to follow the algorithm's activity
	displayGraphic :: Bool # display the results on a graphic
end

# ==========================================================================
# Type of a instance for the scheduling problem presented in the paper Morita et al., 2001 (FCDS)
struct _2OSP
	n ::Int      # number of tasks (positive integer value)
	p ::Vector{Int}# vector of processing time (positive integer values)
	d ::Vector{Int}# vector of due dates (non-negative integer values)
	r ::Vector{Int}#vector of release dates (non-negative integer values)
	w ::Vector{Int}# vector of weights (non-negative integer values)
end

Base.show(io::IO, id::_2OSP) = begin
		print(io, "Bi-Objective Scheduling Problem with $(id.n) tasks.")
		print(io, "\nProcessing times : ") ; show(IOContext(io, :limit=>true), id.p)
		print(io, "\nDue dates : ") ; show(IOContext(io, :limit=>true), id.d)
		if any(x->x!=0, id.r)
				print(io, "\nRelease dates : ") ; show(IOContext(io, :limit=>true), id.r)
		end
		if any(x->x!=1, id.w)
				print(io, "\nWeights : ") ; show(IOContext(io, :limit=>true), id.w)
		end
end

# ==========================================================================
# Type of a solution for the scheduling problem presented in the paper Morita et al., 2001 (FCDS)
mutable struct t_solution
	x ::Vector{Int}# vector of index of jobs in the solution
	z1::Int   # performance objective 1 (integer)
	z2::Int   # performance objective 2 (integer)
end

# ==========================================================================
# Instance's Generators
# ==========================================================================
# Generate a didactic instance
function generateDidacticInstance(idInstance::String)::_2OSP
	if     idInstance == "2001"
		# From the paper:
		#   Hiroyuki Morita, Xavier Gandibleux, Naoki Katoh.
		#   Experimental feedback on biobjective permutation scheduling problems solved with a population heuristic.
		#   Foundations of Computing and Decision Sciences 26 (1), 23-50.
		#   http://fcds.cs.put.poznan.pl/FCDS2/PastIssues.aspx
		nTasks = 4
		data = _2OSP(nTasks, [3, 4, 5, 6], [20, 16, 11, 5], [1, 1, 1, 1], ones(nTasks))
		return data

	elseif idInstance == "1980_4"
		# From the paper:
		#   Luc Van Wassenhove and Ludo Gelders
		#   Solving a bicriterion scheduling problem.
		#   European Journal of Operational Research 4 (1980) 42-48.
		nTasks = 4
		data = _2OSP(nTasks, [2, 4, 3, 1], [1, 2, 4, 6], [1, 1, 1, 1], ones(nTasks))
		# data = _2OSP(nTasks, [2, 3, 1, 2], [3, 4, 5, 6], [1, 1, 1, 1], ones(nTasks))
		return data

	elseif idInstance == "1980_10"
		# From the paper:
		#   Luc Van Wassenhove and Ludo Gelders
		#   Solving a bicriterion scheduling problem.
		#   European Journal of Operational Research 4 (1980) 42-48.
		nTasks = 10
		data = _2OSP(nTasks,
					[9, 9, 6, 7, 2, 4, 7, 2, 7, 8],
					[32, 49, 7, 25, 55, 9, 54, 40, 52, 51], 
					[1, 1, 1, 1, 1, 1, 1, 1, 1, 1], 
					ones(nTasks))
		return data

	end
end

# ==========================================================================
# Generate a parameterized random instance
function generateRandomInstance(nTasks::Int, pMax::Int, dMax::Int, wMax::Int)::_2OSP
	data = _2OSP(nTasks, rand(1:pMax, nTasks), rand(1:dMax, nTasks), rand(1:wMax, nTasks), ones(nTasks))
	return data
end

# ==========================================================================
# Generate a parameterized instance according to (Yagiura and Ibaraki, 1996)
function generateHardInstance(nTasks::Int;  pMax::Int = 30, LF::Float64 = 0.3, RDD::Float64 = 0.9)::_2OSP
	# The generator follows the rules provided in the paper:
	#   Mutsunori Yagiura, Toshihide Ibaraki.
	#   Genetic and local search algorithms as robust and simple optimization tools.
	#   In "Meta-Heuristics: Theory and Applications" (I. Osman and J. Kelly Edts). Kluwer, pp.63-82, 1996.

	# --------------------------------------------------------------------------
	# The parameters are:
	#   nTasks : number of tasks for the scheduling problem
	#     nTasks > 0
	#   pMax : upper value of p_i
	#     1 <= pMax <= 30
	#   LF : Average Lateness Factor (facteur de retard moyen)
	#     0.1 <= LF <= 0.5
	#   RDD : Relative Range of Duedate (interval relatif des dates echues)
	#     0.8 <= RDD <= 1.0

	data_p = rand(1:pMax, nTasks)
	MP = sum(data_p)
	data_d = max.(0 , rand( floor(Int, (1-LF-RDD/2)*MP) : floor(Int, (1-LF+RDD/2)*MP) , nTasks))
	data = _2OSP(nTasks, data_p, data_d, ones(Int,nTasks), ones(nTasks))
	return data
end

# ==========================================================================
# Optimization algorithmsmax.(0 , rand( floor(Int, (1-LF-RDD/2)*MP) : floor(Int, (1-LF+RDD/2)*MP) , nTasks))
# ==========================================================================
# minimize the flowtime on a single machine (Smith's rule)
function computeMinFlowtime(env::t_environment, data::_2OSP)::Tuple{Vector{Int}, Int}
	# minimise f1 : flowtime (SPT-rule)
	SPT = sortperm(data.p)
	somCi = 0
	somPi = 0
	c = zeros(Int,data.n)
	for i=1:data.n
		c[SPT[i]] = somPi + data.p[SPT[i]]
		somPi = somPi + data.p[SPT[i]]
		somCi = somCi + c[SPT[i]]
	end
	if env.displayPrint == true
		println("minimum f1 (min flowtime) = ", somCi)
	end
	return SPT, somCi
end

# ==========================================================================
# minimize the maximum tardiness on a single machine
function computeMinMaxTardiness(env::t_environment, data::_2OSP)::Tuple{Vector{Int}, Int}
	# minimise f2 : maximum tardiness (EDD-rule)
	EDD = sortperm(data.d)
	maxT = 0
	somPi = 0
	c = zeros(Int,data.n)
	for i=1:data.n
		c[EDD[i]] = somPi + data.p[EDD[i]]
		somPi = somPi + data.p[EDD[i]]
		maxT = max(maxT, c[EDD[i]]-data.d[EDD[i]])
	end
	if env.displayPrint == true
		println("minimum f2 (max tardiness) = ", maxT)
	end
	return EDD, maxT
end

# ==========================================================================
# minimize the flowtime on a single machine (modified Smith's backward scheduling rule)
function smith_modifie(env::t_environment, data::_2OSP, I::Matrix{Int}, R::Int, D::Vector{Int})::Tuple{Vector{Int}, Bool}
	sol = zeros(Int,data.n)
	k = data.n
	trouve = true

	# Ensemble des taches triees par ordre lexicographique de leur processing time puis de leur due date
	N = [I[i,3] for i = 1:data.n]

	# Assignation des taches a chaque position en partant de la fin (on decremente k)
	# jusqu'a les avoir toutes assignees ou lorsqu'il n'y a plus de tache i respectant D_i >= R
	while 0 < k && trouve

		i = length(N)
		trouve = false

		# Parcours des taches de l'ensemble N,
		# en partant de celle ayant le plus grand p_i, en cas de p_i egaux celle ayant le plus grand d_i
		while 0 < i && !trouve

			# Si la tache i respecte la conditon D_i >= R
			if D[N[i]] >= R
				sol[k] = N[i] # on l'assigne à la position k
				R = R - data.p[N[i]] # R = R - p_i
				deleteat!(N, i) # on supprime i de l'ensemble N
				k = k-1
				trouve = true
			else
				i = i-1
			end

		end
	end

	return sol, trouve

end

# ==========================================================================
# minimize both flowtime and maximum tardiness on a single machine
function computeExactFlowtimeMaxTardiness(env::t_environment, data::_2OSP)::Vector{t_solution}
	# The algorithm implemented is presented in the paper:
	#   Luc Van Wassenhove and Ludo Gelders
	#   Solving a bicriterion scheduling problem.
	#   European Journal of Operational Research 4 (1980) 42-48.

	# --------------------------------------------------------------------------
	# YN est un tableau contenant tous les points non-domines
	YN = t_solution[]

	# --------------------------------------------------------------------------
	# Trie des taches par ordre lexicographique
	# sur leur processing time puis leur due date
	I = [data.p data.d 1:data.n]
	
	I = @static if VERSION > v"0.7-"
			sortslices(I, dims=1)
		else
			sortrows(I)
		end

	# --------------------------------------------------------------------------
	# Initialisation de R avec la somme des processing time
	R = sum(data.p)

	# --------------------------------------------------------------------------
	# Initialisation de delta avec la somme des processing time, puis des D_i = d_i - delta
	delta = sum(data.p)
	D = [data.d[i] + delta for i = 1:data.n]

	# --------------------------------------------------------------------------
	# Recherche d'une 1ere solution X avec les R et D_i initiaux
	X, existeX = smith_modifie(env, data, I, R, D)

	# --------------------------------------------------------------------------
	# Recherche de l'ensemble des solutions efficaces
	while existeX

		sol = t_solution(X, 0, 0)
		evaluateSolution!(env, data, sol) # (re)evalue la solution sur les 2 objectifs
		push!(YN, sol) # ajoute le point non-domine a l'ensemble YN

		# Affichage de la solution trouvée
		if env.displayYN == true
			println("")
			println("     X  (scheduling) = ", sol.x)
			println("     z1 (total flow time)   = ", sol.z1)
			println("     z2 (maximum tardiness) = ", sol.z2)
			println("")
		end

		# plotEfficientGraphicY(env, sol)

		# Si z2 peut être amélioré on cherche de nouvelle solution sinon on arrête
		if sol.z2 != 0
			# Mise à jour de delta et D_i
			delta = sol.z2 - 1
			for j = 1:data.n
				D[j] = data.d[j] + delta
			end
			X, existeX = smith_modifie(env, data, I, R, D)
		else
			existeX = false
		end #if
	end #while

	return YN

end

# ==========================================================================
# Bi-objective evaluation of a solution
function evaluateSolution!(env::t_environment, data::_2OSP, sol::t_solution)
	# a solution here is a feasible scheduling of tasks
	c = 0; sol.z1 = 0; sol.z2 = 0
	for i=1:data.n
		# completion time de la tache i
		c = c + data.p[sol.x[i]]
		# calcule la somme des c_i (total flow time))
		sol.z1 = sol.z1 + c
		# calcule le retard maximum (maximum tardiness)
		sol.z2 = max(sol.z2, c - data.d[sol.x[i]] )
	end
end

# ==========================================================================
# Output on screen
# ==========================================================================
# display the values of the instance
function displayInstance(env::t_environment, data::_2OSP)
	if env.displayPrint == true
		println("Instance :")
		println(" n = ", data.n)
		println(" p = ", data.p)
		println(" d = ", data.d)
	end
end

# ==========================================================================
# display the points corresponding to optimal solutions for objectives separately
function displayOptimal(env::t_environment, optf1::t_solution, optf2::t_solution)
	if env.displayPrint == true
		println("")
		println("     X optimal f1           = ", optf1.x)
		println("     z1 (total flowtime)    = ", optf1.z1)
		println("     z2 (maximum tardiness) = ", optf1.z2)
		println("")
		println("     X optimal f2           = ", optf2.x)
		println("     z1 (total flowtime)    = ", optf2.z1)
		println("     z2 (maximum tardiness) = ", optf2.z2)
		println("")
		println("------------------------------------------------------------------")
	end
end

# ==========================================================================
# display on screen a summary of the solving process
function displaySummary(env::t_environment, YN, elapsedTime)
	if env.displayPrint == true
		println("")
		println("     Number of non-dominated points = ", length(YN))
		println("     Elapsed time (seconds)         = ", elapsedTime)
		println("")
	end
end

# ==========================================================================
# Output on graphics
# ==========================================================================
# initiate the legends of the graphic in the objective space
# function setupGraphicY(env::t_environment, titleFigure, axisX, axisY)
#   if env.displayGraphic == true
#     title(titleFigure)
#     xlabel(axisX)
#     ylabel(axisY)
#   end
# end

# ==========================================================================
# plot the optimal points corresponding to optimal solutions for both objectives separately
# function plotOptimalGraphicY(env::t_environment, optf1::t_solution, optf2::t_solution)
#   if env.displayGraphic == true
#     plot(optf1.z1,optf1.z2, color="green",linestyle="",marker="D", label="opt")
#     plot(optf2.z1,optf2.z2, color="green",linestyle="",marker="D", label="opt")
#   end
# end

# ==========================================================================
# plot one non-dominated point
# function plotEfficientGraphicY(env::t_environment, sol::t_solution)
#   if env.displayGraphic == true
#     plot(sol.z1,sol.z2, color="cyan",linestyle="",marker="o", label="YN")
#   end
# end

function solveOSP(data::_2OSP, displayYN, displayPrint)
	# --------------------------------------------------------------------------
	env = t_environment(displayYN, displayPrint, false)

	# display the values of the instance
	displayInstance(env, data)

	# --------------------------------------------------------------------------
	# Elements pour la representation graphique de l'espace des objectifs
	# setupGraphicY(env, "Y (objective space)", "z1 (total flow time)", "z2 (Maximum tardiness)")

	# --------------------------------------------------------------------------
	# Initialise le timer
	tstart = time_ns()

	# --------------------------------------------------------------------------
	# Calcul des solutions optimales pour les 2 objectifs pris separement
	optf1 = t_solution(zeros(data.n), 0, 0)
	optf1.x, optf1.z1 = computeMinFlowtime(env, data)
	evaluateSolution!(env, data, optf1) # (re)evalue la solution sur les 2 objectifs

	optf2 = t_solution(zeros(data.n), 0, 0)
	optf2.x, optf2.z2 = computeMinMaxTardiness(env, data)
	evaluateSolution!(env, data, optf2) # (re)evalue la solution sur les 2 objectifs

	# --------------------------------------------------------------------------
	# plot on graphic the optimal points corresponding to optimal solutions for both objectives separately
	# plotOptimalGraphicY(env, optf1, optf2)
  
	# --------------------------------------------------------------------------
	# display on screen the optimal solutions for both objectives separately
	displayOptimal(env, optf1, optf2)

	# --------------------------------------------------------------------------
	# Calcul des points non-domines pour les 2 objectifs pris simultanement
	YN = computeExactFlowtimeMaxTardiness(env, data)

	# Releve le timer et donne le temps utilise par la resolution
	elapsedTime = (time_ns() - tstart) * 1e-9

	# --------------------------------------------------------------------------
	# display on screen a summary of the solving process
	displaySummary(env, YN, elapsedTime)

	return map(x -> x.z1, YN), map(x -> x.z2, YN), map(x -> x.x, YN)

	# ==========================================================================

end

function set2OSP(n::Int, p::Vector{Int}, d::Vector{Int}, r::Vector{Int}=zeros(Int,n), w::Vector{Int}=ones(Int,n))
	@assert n==length(p)==length(d)==length(w)
	@assert all(x->x>0, p)
	@assert all(x->x>=0, d)
	@assert all(x->x>=0, r)
	@assert all(x->x>=0, w)
	_2OSP(n,p,d,r,w)
end
set2OSP(p::Vector{Int},d::Vector{Int},r::Vector{Int}=zeros(Int,length(p)),w::Vector{Int}=ones(Int, length(p))) = set2OSP(length(p),p,d,r,w)

struct OSPSolver
	solve::Function
end

function OSP_VanWassenhove1980(;displayYN=false, displayPrint=false)::OSPSolver
	return OSPSolver((id::_2OSP) -> solveOSP(id,displayYN,displayPrint))
end

function vSolve(id::_2OSP, solver::OSPSolver = OSP_VanWassenhove1980())
	solver.solve(id)
end

function load2OSP(fname::AbstractString)
	f = open(fname)
	n = parse(Int, readline(f))
	data = convert(Matrix{Int}, readdlm(f))
	p = data[1,:]
	d = data[2,:]
	r = data[3,:]
	w = data[4,:]
	close(f)
	return set2OSP(p,d,r,w)
end

