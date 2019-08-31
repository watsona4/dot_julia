#
#  Copyright (C) 2019 Remi Imbach
#
#  This file is part of Ccluster.
#
#  Ccluster is free software: you can redistribute it and/or modify it under
#  the terms of the GNU Lesser General Public License (LGPL) as published
#  by the Free Software Foundation; either version 2.1 of the License, or
#  (at your option) any later version.  See <http://www.gnu.org/licenses/>.
#

using Printf

import Nemo: fmpz, fmpq, acb, acb_poly, fmpq_poly, degree, ArbField, AcbField, RealField, ComplexField, 
             AcbPolyRing, PolynomialRing, evaluate, coeff
             
export TCLUSTER_POLS, TCLUSTER_CFEV, TCLUSTER_CLUS, TCLUSTER_DEGS, TCLUSTER_STRA, TCLUSTER_VERB
export tcluster, printClusters, printClustersInFile

# global variables
TCLUSTER_POLS = [[]]
TCLUSTER_CFEV = []
TCLUSTER_CLUS = [[]]
TCLUSTER_DEGS = [[]]
TCLUSTER_PREC = [[]]
TCLUSTER_STRA = [55] 
TCLUSTER_VERB = [0] 

### interface
function tcluster( polys,  #an array of pols
                   domain, #an array of Ccluster.box, possibly of length 1
                   prec;   #a precision: Int
                   strat=55,  #a strategy: Int
                   verbosity="brief" ) #a verbosity flag; by defaults, a brief summary
                                       #options are "silent", "results" 
                   
    global TCLUSTER_STRA, TCLUSTER_VERB
    global TCLUSTER_POLS, TCLUSTER_CFEV, TCLUSTER_CLUS, TCLUSTER_DEGS, TCLUSTER_PREC

    if verbosity=="debug"
        print("tcluster.jl, tcluster: begin\n")
    end
    
    tic = time()
    
    Ccluster.initializeGlobalVariables(polys, prec, verbosity)
    
    #construct the initial domain
    initBox::Array{Ccluster.box,1}=[]
    if !initializeInitialDomain(initBox, domain)
        return -1, [], 0.0
    end
    
    TCLUSTER_STRA[1] = strat
    
    if typeof(verbosity) == String
        TCLUSTER_VERB[1] = 0
    else
        TCLUSTER_VERB[1] = verbosity
    end
    
    if verbosity=="debug"
        print("tcluster.jl, tcluster: initialization OK\n")
    end
    
    #solve the system
    clusters = Ccluster.clusterTriSys(initBox, prec)
    ellapsedTime = time() - tic
    
    if verbosity=="debug"
        print("tcluster.jl, tcluster: solving OK\n")
    end
    
    sumOfMults, solutions = constructOutput(clusters, prec)
    
    if verbosity=="debug"
        print("tcluster.jl, tcluster: construction output OK\n")
    end
    
    if verbosity == "brief" || verbosity == "results" || verbosity == "debug"
        printBrief(stdout, sumOfMults, solutions, ellapsedTime)
#         print("TIMEINGETPOLAT: $(TIMEINGETPOLAT[1])\n")
    end
    if verbosity == "results"
        printClusters(stdout, sumOfMults, solutions)
    end
    
    if verbosity=="debug"
        print("tcluster.jl, tcluster: end\n")
    end
    
    return sumOfMults, solutions, ellapsedTime
end

function initializeGlobalVariables(polys, prec::Int, verbosity)::Nothing
    
    global TCLUSTER_STRA, TCLUSTER_VERB
    global TCLUSTER_POLS, TCLUSTER_CFEV, TCLUSTER_CLUS, TCLUSTER_DEGS, TCLUSTER_PREC
    
#     global TIMEINGETPOLAT
#     TIMEINGETPOLAT[1]=0.
    
    empty!(TCLUSTER_CFEV)
    push!(TCLUSTER_CFEV,Ccluster.algClus[])
    
    empty!(TCLUSTER_CLUS)
    push!(TCLUSTER_CLUS, Array{Ccluster.algClus,1}[])
    
    empty!(TCLUSTER_POLS[1])
    empty!(TCLUSTER_DEGS[1])
    empty!(TCLUSTER_PREC[1])
    for index in 1:length(polys)
        push!(TCLUSTER_POLS[1], deepcopy(polys[index]))
        push!(TCLUSTER_CLUS[1], [])
        push!(TCLUSTER_DEGS[1], Ccluster.getDeg(polys[index], index))
        push!(TCLUSTER_PREC[1], prec)
        if verbosity=="debug"
            print("poly $index, degrees: $(TCLUSTER_DEGS[1][index])\n")
        end
    end
    
    #initialize TCLUSTER_PREC
    index::Int = length(polys)
    while index > 1
        index2::Int = index-1
        while index2>=1
            if TCLUSTER_DEGS[1][index][index2]>=1
                TCLUSTER_PREC[1][index2] = TCLUSTER_PREC[1][index2]*2
            end
            index2 = index2-1
        end
        index = index -1
    end
    if verbosity=="debug"
        print("precs: $(TCLUSTER_PREC[1])\n")
    end
end

function initializeInitialDomain(initBox::Array{Ccluster.box,1}, domain)::Bool
    
    if length(domain)==length(TCLUSTER_POLS[1])
        for index in 1:length(domain)
        
            if typeof(domain[index])==Ccluster.box
                btemp = Ccluster.box( domain[index] )
            elseif typeof(domain[index])==Array{fmpq,1}
                btemp = Ccluster.box( domain[index][1],domain[index][2],domain[index][3] )
            else
                print("bad type of domain[$(index)]: should be either Ccluster.box of Array{fmpq,1}\n")
                return false
            end
            push!(initBox, btemp)
        end
    elseif length(domain)==1
    
        if typeof(domain[1])==Ccluster.box
            btemp = Ccluster.box( domain[1] )
        elseif typeof(domain[1])==Array{fmpq,1}
            btemp = Ccluster.box( domain[1][1],domain[1][2],domain[1][3] )
        else
            print("bad type of domain[1]: should be either Ccluster.box of Array{fmpq,1}\n")
            return false
        end
        
        for index in 1:length(TCLUSTER_POLS[1])
            push!(initBox, Ccluster.box(btemp))
        end
    else
        print("bad length of domain: should be either 1 or $(TCLUSTER_POLS[1])\n")
        return false
    end
    return true
end

function constructOutput(clusters::Array{Array{Ccluster.algClus,1},1}, prec::Int)

    sumOfMults = 0
    solutions=[]
    
    for index in 1:length(clusters)
        mult = 1
        mults = []
        precs = []
        for index2 in 1:length(clusters[index])
#             print("mult: $(mult)\n")
            mult=mult*clusters[index][index2]._nbSols
            push!(mults, clusters[index][index2]._nbSols)
            push!(precs, clusters[index][index2]._prec)
        end
        sumOfMults +=mult
#         push!(solutions, [mult, clusters[index]])
        push!(solutions, [mult, getApproximation(clusters[index],prec), mults, precs])
    end
    return sumOfMults, solutions
    
end

function printBrief(out, sumOfMults, solutions, ellapsedTime)
    write(out, "----------tcluster-------------------\n")
    write(out, "time to solve the system: $ellapsedTime \n")
    write(out, "number of clusters: $(length(solutions))\n")
    write(out, "number of solutions: $(sumOfMults)\n")
    write(out, "-------------------------------------\n")
    return
end

function printClusters(out, sumOfMults, solutions)
    write(out, "-------------------------------------\n")
    for index in 1:length(solutions)
        mult = solutions[index][1]
        s = @sprintf("*** cluster with sum of multiplicity %4d *** \n", mult); write(out,s);
        approx = solutions[index][2]
        for index2 in 1:length(solutions[index][2])
            nbSols    = solutions[index][3][index2]
            clusprec  = solutions[index][4][index2]
            s = @sprintf("---%2d-th comp: prec %4d, nbSols %4d, ", index2, clusprec, nbSols); write(out,s);
            write(out, "$(approx[index2])\n");
        end
    end
    write(out, "-------------------------------------\n")
    return
end

function printClustersInFile(nameOutFile, sumOfMults, solutions, ellapsedTime)
    open(nameOutFile, "w") do out
        printBrief(out, sumOfMults, solutions, ellapsedTime)
        printClusters(out, sumOfMults, solutions)
    end
    return
end

### Main function
function clusterTriSys(b::Array{Ccluster.box,1}, prec::Int)::Array{Array{Ccluster.algClus,1},1}

    global TCLUSTER_STRA, TCLUSTER_VERB
    global TCLUSTER_POLS, TCLUSTER_CFEV, TCLUSTER_CLUS, TCLUSTER_DEGS, TCLUSTER_PREC
    
    actualPol::Int = length(b)
    
    if actualPol==1 #terminal case
#         clusters::Array{Array{Ccluster.algClus,1},1} = Ccluster.clusterPol(b[1], prec)
        clusters::Array{Array{Ccluster.algClus,1},1} = Ccluster.clusterPol(b[1], TCLUSTER_PREC[1][actualPol])
    else            #other cases
        btemp::Ccluster.box = pop!(b)
        clusterstemp::Array{Array{Ccluster.algClus,1},1} = clusterTriSys( b, prec )
        clusters=[]
        while length(clusterstemp)>0
            clus::Array{Ccluster.algClus,1}=pop!(clusterstemp)
#             clusterstemp2::Array{Array{Ccluster.algClus,1},1} = Ccluster.clusterPolInFiber(clus, btemp, prec)
            clusterstemp2::Array{Array{Ccluster.algClus,1},1} = Ccluster.clusterPolInFiber(clus, btemp, TCLUSTER_PREC[1][actualPol])
            while length(clusterstemp2)>0
                push!(clusters, pop!(clusterstemp2))
            end
        end
        
    end 
    
    return clusters
end

### Compute clusters for first equation: univariate polynomial
# approximation function
function getAppFirst( dest::Ptr{acb_poly}, prec::Int )::Cvoid
    global TCLUSTER_POLS
    ccall((:acb_poly_set_fmpq_poly, :libarb), 
            Cvoid, (Ptr{acb_poly}, Ref{fmpq_poly}, Int), 
                   dest,           TCLUSTER_POLS[1][1],            prec)
end

# version for box
function clusterPol(b::Ccluster.box, prec::Int)::Array{Array{Ccluster.algClus,1},1}

    global TCLUSTER_STRA, TCLUSTER_VERB
    global TCLUSTER_POLS, TCLUSTER_CFEV, TCLUSTER_CLUS, TCLUSTER_DEGS
    
    TCLUSTER_CFEVsave::Array{Ccluster.algClus,1} = TCLUSTER_CFEV[1]
    
    TCLUSTER_CFEV[1]=[]
    clusters=Array{Ccluster.algClus,1}[]
    eps = fmpq(1, fmpz(2)^(prec-1))
    
#     qRes::Ccluster.listConnComp = Ccluster.ccluster_solve(getAppSys, b, eps, TCLUSTER_STRA[1], TCLUSTER_VERB[1]);
    qRes::Ccluster.listConnComp = Ccluster.ccluster_solve(getAppFirst, b, eps, TCLUSTER_STRA[1], TCLUSTER_VERB[1]);
    while !Ccluster.isEmpty(qRes)
        objCC, ptrCC = Ccluster.pop_obj_and_ptr(qRes)
        push!(clusters, [Ccluster.algClus(objCC, ptrCC, b, prec)] )
    end
    
    TCLUSTER_CFEV[1] = TCLUSTER_CFEVsave
    return clusters
end

# version for Ccluster.algClus
function clusterPol(b::Ccluster.algClus, prec::Int)::Array{Array{Ccluster.algClus,1},1}
    
    global TCLUSTER_STRA, TCLUSTER_VERB
    global TCLUSTER_POLS, TCLUSTER_CFEV, TCLUSTER_CLUS, TCLUSTER_DEGS
    
    TCLUSTER_CFEVsave::Array{Ccluster.algClus,1} = TCLUSTER_CFEV[1]
    TCLUSTER_CFEV[1]=[]
#     clusters::Array{Array{Ccluster.algClus,1},1} = Ccluster.refine_algClus( b, getAppSys, prec, TCLUSTER_STRA[1], TCLUSTER_VERB[1])
    clusters::Array{Array{Ccluster.algClus,1},1} = Ccluster.refine_algClus( b, getAppFirst, prec, TCLUSTER_STRA[1], TCLUSTER_VERB[1])
    TCLUSTER_CFEV[1] = TCLUSTER_CFEVsave
    return clusters
    
end

### find the next floor of a TAC that has to be refined
function nextFloorToRefine( actualPol::Int, clus::Array{Ccluster.algClus,1}, prec::Int)::Int

    global TCLUSTER_CFEV, TCLUSTER_DEGS
    
    degrees::Array{Int,1} = TCLUSTER_DEGS[1][actualPol]
    curPrecs::Array{Int,1} = Ccluster.getPrecs(TCLUSTER_CFEV[1])
    res::Int = actualPol -1
    
    while (res>=1)&&((degrees[res]==0)||(curPrecs[res]>=prec))
        res = res - 1
    end
    
    return res
    
end

### Compute clusters for other equations: recursive
function clusterPolInFiber(a::Array{Ccluster.algClus,1}, b::Ccluster.box, prec::Int)::Array{Array{Ccluster.algClus,1},1}
    
    global TCLUSTER_STRA, TCLUSTER_VERB
    global TCLUSTER_POLS, TCLUSTER_CFEV, TCLUSTER_CLUS, TCLUSTER_DEGS
    
    TCLUSTER_CFEVsave::Array{Ccluster.algClus,1} = TCLUSTER_CFEV[1]
    #floor d of the TAC
    actualPol::Int = length(a) + 1
    #push a in TCLUSTER_CLUS[1][actualPol-1] that should be empty
    push!(TCLUSTER_CLUS[1][actualPol-1], a)
    
    #initialize clusters
    clusters=Array{Ccluster.algClus,1}[]
    while length( TCLUSTER_CLUS[1][actualPol-1] )>0
        
        c::Array{Ccluster.algClus,1} = pop!(TCLUSTER_CLUS[1][actualPol-1])
        TCLUSTER_CFEV[1] = c
        eps::fmpq = fmpq(1, fmpz(2)^(prec-1))
        
        qRes::Ccluster.listConnComp = Ccluster.ccluster_solve(getAppSys, b, eps, TCLUSTER_STRA[1], TCLUSTER_VERB[1]);
        c = TCLUSTER_CFEV[1]
        
        while !Ccluster.isEmpty(qRes)
            cc::Array{Ccluster.algClus,1} = Ccluster.clusCopy(c)
            objCC, ptrCC = Ccluster.pop_obj_and_ptr(qRes)
            push!(cc, Ccluster.algClus( objCC, ptrCC, b, prec ) )
            push!(clusters, cc )
        end
            
    end
    
    TCLUSTER_CFEV[1] = TCLUSTER_CFEVsave
    
    return clusters
end

#version for Ccluster.algClus
function clusterPolInFiber(a::Array{Ccluster.algClus,1}, b::Ccluster.algClus, prec::Int)::Array{Array{Ccluster.algClus,1},1}
    
    global TCLUSTER_STRA, TCLUSTER_VERB
    global TCLUSTER_POLS, TCLUSTER_CFEV, TCLUSTER_CLUS, TCLUSTER_DEGS
    
    TCLUSTER_CFEVsave::Array{Ccluster.algClus,1} = TCLUSTER_CFEV[1]
    #floor d of the TAC
    actualPol::Int = length(a) + 1
    #push a in TCLUSTER_CLUS[1][actualPol-1] that should be empty
    push!(TCLUSTER_CLUS[1][actualPol-1], a)
    
    #initialize clusters
    clusters=Array{Ccluster.algClus,1}[]
    while length( TCLUSTER_CLUS[1][actualPol-1] )>0
        
        c::Array{Ccluster.algClus,1} = pop!(TCLUSTER_CLUS[1][actualPol-1])
        TCLUSTER_CFEV[1] = c
        qRes::Array{Array{Ccluster.algClus,1},1} = Ccluster.refine_algClus(b, getAppSys, prec, TCLUSTER_STRA[1], TCLUSTER_VERB[1])
        c = TCLUSTER_CFEV[1]
        
        for index = 1:length(qRes)
                cc::Array{Ccluster.algClus,1} = Ccluster.clusCopy(c)
                push!(cc, qRes[index][1])
                push!(clusters, cc) 
        end
            
    end
    
    TCLUSTER_CFEV[1] = TCLUSTER_CFEVsave
    
    return clusters
end

function getAppSys( dest::Ptr{acb_poly}, prec::Int )::Cvoid

    global TCLUSTER_STRA, TCLUSTER_VERB
    global TCLUSTER_POLS, TCLUSTER_CFEV, TCLUSTER_CLUS, TCLUSTER_DEGS
    
    actualPol::Int = length(TCLUSTER_CFEV[1]) + 1
    Ptemp = TCLUSTER_POLS[1][actualPol]
    
    if actualPol==1 #should never enter here
        ccall((:acb_poly_set_fmpq_poly, :libarb), 
            Cvoid, (Ptr{acb_poly}, Ref{fmpq_poly}, Int), 
                   dest,           Ptemp,            prec)
    else
        #find the higher floor to be refined
        ind::Int = Ccluster.nextFloorToRefine( actualPol, TCLUSTER_CFEV[1], prec)
        
        while ind>0
        
            #deconstruct the tower
            upperpart::Array{Ccluster.algClus,1} = TCLUSTER_CFEV[1][ind + 1 : length(TCLUSTER_CFEV[1])]
            TCLUSTER_CFEV[1] = TCLUSTER_CFEV[1][1:ind]
            #refine the tower
            if length( TCLUSTER_CFEV[1] ) ==1 # TCLUSTER_CFEV[1] contains just an algebraic cluster
                local clus, clust, clusters
                clus::Ccluster.algClus = TCLUSTER_CFEV[1][1]
                clusters::Array{Array{Ccluster.algClus,1},1} = Ccluster.clusterPol(clus, prec)
                clust::Array{Ccluster.algClus,1} = pop!(clusters)
                Ccluster.copyIn( TCLUSTER_CFEV[1][1], clust[1] )
            else # TCLUSTER_CFEV[1] is a TAC
                local clus
                clus = pop!(TCLUSTER_CFEV[1]) #the last floor of the TAC
                clusters = Ccluster.clusterPolInFiber(TCLUSTER_CFEV[1], clus, prec)
                clust = pop!(clusters)
                push!(TCLUSTER_CFEV[1],clust[length(clust)]) #just to extend the size of TCLUSTER_CFEV[1]
                Ccluster.copyIn( TCLUSTER_CFEV[1], clust )
            end
            #reconstruct the towers
            for j = 1:length(upperpart)
                for i = 1:length(clusters)
                    push!( clusters[i], Ccluster.clusCopy( upperpart[j] ) )
                end
                push!(TCLUSTER_CFEV[1], upperpart[j])
            end
            # push additionnal clusters in queue
            while length(clusters)>0
                push!(TCLUSTER_CLUS[1][actualPol-1], pop!(clusters))
            end
            # check if there is still something to refine
            ind = Ccluster.nextFloorToRefine( actualPol, TCLUSTER_CFEV[1], prec)
            
        end
        
        approx::Array{acb,1} = Ccluster.getApproximation(TCLUSTER_CFEV[1],prec)
        Ptemp2::acb_poly = Ccluster.getPolAtHorner(Ptemp,approx,prec)
        
        ccall((:acb_poly_set, :libarb), 
            Cvoid, (Ptr{acb_poly}, Ref{acb_poly}, Int), 
                   dest,          Ptemp2,         prec)
                   
    end   
end
