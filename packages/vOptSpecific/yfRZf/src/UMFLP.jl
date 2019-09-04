# MIT License
# Copyright (c) 2017: Xavier Gandibleux, Anthony Przybylski, Gauthier Soleilhac, and contributors.
struct _2UMFLP
  m::Int #nbCustomers
  n::Int #nbFacilities
  A1::Matrix{Float64} #Assignment costs of clients to facilities
  A2::Matrix{Float64} #Assignment costs of clients to facilities
  R1::Vector{Float64} #Running cost of facilities
  R2::Vector{Float64} #Running cost of facilities
end

Base.show(io::IO, id::_2UMFLP) = println("Bi-Objective Facility Location Problem with $(id.m) customers and $(id.n) facilities.")

set2UMFLP(m,n,A1,A2,R1,R2) = begin
    @assert size(A1,2) == length(R1)
    @assert n == size(A1, 2) == size(A2, 2) == length(R1) == length(R2)
    @assert m == size(A1, 1) == size(A2, 1)
    return _2UMFLP(m,n,A1,A2,R1,R2)
end
set2UMFLP(A1,A2,R1,R2) = set2UMFLP(size(A1,1), size(A1,2), A1, A2, R1, R2)

struct UMFLPsolver
    solve::Function
end

function vSolve(id::_2UMFLP, solver::UMFLPsolver = UMFLP_Delmee2017())
    solver.solve(id)
end

function load2UMFLP(fname)
   f = open(fname)
   nbC = parse(Int, readline(f))
   nbF = parse(Int, readline(f))

   d = readdlm(f)
   c_alloc1 = convert(Matrix{Float64}, d[1:nbC, 1:nbF])
   c_alloc2 = convert(Matrix{Float64}, d[nbC+1:2nbC, 1:nbF])
   c_loc1 = convert(Vector{Float64}, d[2nbC+1, 1:nbF])
   c_loc2 = convert(Vector{Float64}, d[2nbC+2, 1:nbF])
   return _2UMFLP(nbC, nbF, c_alloc1, c_alloc2, c_loc1, c_loc2)
end

function UMFLP_Delmee2017(; modeVerbose = false, modeUpperBound = true, modeLowerBound = true, modeImprovedLB = false, modeParam = true)::UMFLPsolver
    f = (id::_2UMFLP) -> begin 
        n, m = id.n, id.m  #n facilities, m customers
        A1, A2 = vec(permutedims(id.A1, [2,1])), vec(permutedims(id.A2, [2,1]))
        R1, R2 = id.R1, id.R2
        p_z1,p_z2 = Ref{Ptr{Cdouble}}() ,Ref{Ptr{Cdouble}}()
        p_facility, p_isEdge, p_isExtremityDominated = Ref{Ptr{Cuchar}}(), Ref{Ptr{Cuchar}}(), Ref{Ptr{Cuchar}}()
        p_nbAlloc, p_customerAlloc, p_correspondingFac = Ref{Ptr{Cint}}(), Ref{Ptr{Cint}}(), Ref{Ptr{Cint}}()
        p_percentageAlloc = Ref{Ptr{Cdouble}}()
        nbSol = ccall((:solve, libUMFLPpath),
                       Int,
                       (Cint, Cint, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, #Inputs
                           Cuchar, Cuchar, Cuchar, Cuchar, Cuchar, Cuchar, Cuchar, Cuchar, #Parameters
                           # Outputs :
                           Ref{Ptr{Cdouble}}, Ref{Ptr{Cdouble}}, #z1, z2
                           Ref{Ptr{Cuchar}}, Ref{Ptr{Cuchar}}, Ref{Ptr{Cuchar}},#facility, isEdge, isExtremityDominated,
                           Ref{Ptr{Cint}}, Ref{Ptr{Cint}}, Ref{Ptr{Cint}}, Ref{Ptr{Cdouble}}), #nb Alloc, SparseMatrix : i,j,k

                       m, n, A1, A2, R1, R2,
                       modeVerbose, modeLowerBound, false, false, modeImprovedLB, modeUpperBound, modeParam, false,
                       p_z1, p_z2,
                       p_facility, p_isEdge, p_isExtremityDominated,
                       p_nbAlloc, p_customerAlloc, p_correspondingFac, p_percentageAlloc)
        z1 = _unsafe_wrap(Array, p_z1.x, nbSol, own=true)
        z2 = _unsafe_wrap(Array, p_z2.x, nbSol, own=true)

        facility = convert(BitArray, _unsafe_wrap(Array, p_facility.x, nbSol*n, own=true))
        facility_res = [facility[i:i+n-1] for i = 1:n:nbSol*n]
        isEdge = convert(BitArray, _unsafe_wrap(Array, p_isEdge.x, nbSol, own=true))
        isExtremityDominated = convert(BitArray, _unsafe_wrap(Array, p_isExtremityDominated.x, nbSol, own=true))
        nbAlloc = _unsafe_wrap(Array, p_nbAlloc.x, nbSol, own=true)

        totalAlloc = sum(nbAlloc)

        customerAlloc = 1 .+ _unsafe_wrap(Array, p_customerAlloc.x, totalAlloc, own=true)
        correspondingFac = 1 .+ _unsafe_wrap(Array,  p_correspondingFac.x, totalAlloc, own=true)
        percentageAlloc = _unsafe_wrap(Array,  p_percentageAlloc.x, totalAlloc, own=true)

        ind = 1

        X = SparseMatrixCSC{Float64, Int}[]

        for i= 1:nbSol
            sm = sparse(customerAlloc[ind:ind+nbAlloc[i]-1], correspondingFac[ind:ind+nbAlloc[i]-1], percentageAlloc[ind:ind+nbAlloc[i]-1])
            ind += nbAlloc[i]
            push!(X, sm)
        end
        return z1, z2, facility_res, X, isEdge, isExtremityDominated
    end

    return UMFLPsolver(f)
end
