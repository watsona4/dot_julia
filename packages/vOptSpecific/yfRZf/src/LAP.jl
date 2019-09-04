# MIT License
# Copyright (c) 2017: Xavier Gandibleux, Anthony Przybylski, Gauthier Soleilhac, and contributors.
struct _2LAP
    nSize::Int
    C1::Matrix{Int}
    C2::Matrix{Int}
end

Base.show(io::IO, id::_2LAP) = print("Bi-Objective Linear Affectation Problem with $(id.nSize) variables.")

set2LAP(n::Int, c1::Matrix{Int}, c2::Matrix{Int}) = begin
    if !(size(c1,1) == size(c1, 2) == size(c2,1) == size(c2 , 2) == n)
        error("dimensions incorrectes")
    end
    _2LAP(n, c1, c2)
end
set2LAP(c1::Matrix{Int}, c2::Matrix{Int}) = _2LAP(size(c1,1), c1, c2)

struct LAPsolver
    parameters
    solve::Function #::Function(id::_2LAP) -> ...
end

function vSolve(id::_2LAP, solver::LAPsolver = LAP_Przybylski2008())
    solver.solve(id)
end

function LAP_Przybylski2008()::LAPsolver
    f = (id::_2LAP) -> begin 
        nSize, C1, C2 = Cint(id.nSize), vec(convert(Matrix{Cint}, id.C1)), vec(convert(Matrix{Cint}, id.C2))
        p_z1,p_z2,p_solutions,p_nbsolutions = Ref{Ptr{Cint}}() , Ref{Ptr{Cint}}(), Ref{Ptr{Cint}}(), Ref{Cint}()
        ccall(
            (:solve_bilap_exact, libLAPpath),
            Nothing,
            (Ref{Cint},Ref{Cint}, Cint, Ref{Ptr{Cint}}, Ref{Ptr{Cint}}, Ref{Ptr{Cint}}, Ref{Cint}),
            C1, C2, nSize, p_z1, p_z2, p_solutions, p_nbsolutions)
        nbSol = p_nbsolutions.x
        z1,z2 = convert(Array{Int,1},_unsafe_wrap(Array, p_z1.x, nbSol, own=true)), convert(Array{Int,1},_unsafe_wrap(Array, p_z2.x, nbSol, own=true))
        solutions = convert(Array{Int,2},reshape(_unsafe_wrap(Array, p_solutions.x, nbSol*id.nSize, own=true), (id.nSize, nbSol)))
        return z1, z2, permutedims(solutions, [2,1]).+1
    end

    return LAPsolver(nothing, f)
end

function load2LAP(fname::AbstractString)
    f = open(fname)
    n = parse(Int,readline(f))
    C1 = zeros(Int,n,n)
    C2 = zeros(Int,n,n)
    for i = 1:n
		@static if VERSION > v"0.7-"
        	C1[i,:] = parse.(Int, split(chomp(readline(f)), ' ', keepempty=false))
		else
			C1[i,:] = parse.(Int, split(chomp(readline(f)), ' ', keep=false))
		end
    end
    for i=1:n
		@static if VERSION > v"0.7-"
	        C2[i,:] = parse.(Int, split(chomp(readline(f)), ' ', keepempty=false))
		else
			C2[i,:] = parse.(Int, split(chomp(readline(f)), ' ', keep=false))
		end
    end
    return _2LAP(n, C1, C2)
end
