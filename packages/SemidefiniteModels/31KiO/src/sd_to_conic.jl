# wrapper to convert SD solver into Conic solver

# To enable Conic support from an SD solver, define, e.g.,
# ConicModel(s::CSDPSolver) = SDtoConicBridge(SDModel(s))

mutable struct SDtoConicBridge <: MPB.AbstractConicModel
    sdmodel::AbstractSDModel
    varmap
    varnewconstrmap
    constrmap
    constrscaling
    c
    A
    b
    constr_cones
    var_cones
end

# FIXME implements supportedcones

SDtoConicBridge(m::AbstractSDModel) = SDtoConicBridge(m, nothing, nothing, nothing, nothing, nothing, nothing, nothing, nothing, nothing)

export SDtoConicBridge

MPB.numvar(m::SDtoConicBridge) = size(m.A,2)
MPB.numconstr(m::SDtoConicBridge) = size(m.A,1)

function getmatdim(k)
    # n*(n+1)/2 = k
    # n^2+n-2k = 0
    # (-1 + sqrt(1 + 8k))/2
    n = (-1 + sqrt(1 + 8k)) / 2
    if n * (n+1) != 2*k
        error("sd dim not consistent")
    end
    convert(Int, n)
end

# To transform Conic problems into SD problems
function MPB.loadproblem!(model::SDtoConicBridge, c, A, b, constr_cones, var_cones)
    m, n = size(A)
    model.c = c
    model.A = A
    model.b = b
    model.constr_cones = constr_cones
    model.var_cones = var_cones

    # Conic form        LP form
    # min  c'x          min      c'x
    #  st b-Ax ∈ K_1     st lb <= Ax <= b
    #        x ∈ K_2         l <=  x <= u

    # If a cone is anything other than [:Free,:Zero,:NonNeg,:NonPos,:SOC,:SOCRotated,:SDP], give up.
    bad_cones = [:ExpPrimal, :ExpDual]
    for (cone,_) in var_cones
        cone in bad_cones && error("Cone type $(cone) not supported")
    end
    for (cone,_) in constr_cones
        cone in bad_cones && error("Cone type $(cone) not supported")
    end

    blk = 0
    blkdims = Int[]
    socblks = Int[]
    socblksrotated = BitSet()
    socblksvarconemap = Int[]
    # For a variable at column index `col' in the conic model,
    # varmap[col] gives an array such that each coefficient A[.,col] should be replaced by the sum,
    # over each element (blk, i, j, coef) of the array of
    # X[blk][i,j] * (A[.,col] * coef)
    # Where X[blk] is the blk'th block of X
    model.varmap = varmap = Vector{Vector{Tuple{Int,Int,Int,Float64}}}(undef, n)
    varconeidx = 0
    for (cone,idxs) in var_cones
        varconeidx += 1
        # If a cone is anything other than [:Free,:Zero,:NonNeg,:NonPos,:SOC,:SDP], give up.
        if cone == :Free
            for i in idxs
                blk += 2
                push!(blkdims, 1)
                push!(blkdims, 1)
                # x free transformed into x = y - z with y, z >= 0
                varmap[i] = [(blk-1,1,1,1.), (blk,1,1,-1.)]
            end
        elseif cone == :Zero
            for i in idxs
                varmap[i] = []
            end
        elseif cone == :NonNeg
            for i in idxs
                blk += 1
                push!(blkdims, 1)
                varmap[i] = [(blk,1,1,1.)]
            end
        elseif cone == :NonPos
            for i in idxs
                blk += 1
                push!(blkdims, 1)
                varmap[i] = [(blk,1,1,-1.)]
            end
        elseif cone == :SOC
            blk += 1
            push!(blkdims, length(idxs))
            for i in 1:length(idxs)
                varmap[idxs[i]] = [(blk, 1, i, i == 1 ? 1.0 : 0.5)]
            end
            push!(socblks, blk)
            push!(socblksvarconemap, varconeidx)
        elseif cone == :SOCRotated
            blk += 1
            push!(blkdims, length(idxs)-1)
            varmap[idxs[1]] = [(blk,1,1,1.)]
            varmap[idxs[2]] = [(blk,2,2,.5)]
            for i in 3:length(idxs)
                varmap[idxs[i]] = [(blk,1,i-1,.5)]
            end
            push!(socblks, blk)
            push!(socblksrotated, length(socblks))
            push!(socblksvarconemap, varconeidx)
        elseif cone == :SDP
            d = getmatdim(length(idxs))
            k = 0
            blk += 1
            push!(blkdims, d)
            for i in 1:d
                for j in i:d
                    k += 1
                    # In the MPB conic model, those are scaled by sqrt(2)
                    coef = i == j ? 1.0 : inv(√2)
                    varmap[idxs[k]] = [(blk,i,j,coef)]
                end
            end
        else
            throw(ArgumentError("Unrecognized cone $cone"))
        end
    end
    @assert blk == length(blkdims)
    constr = 0
    # For the constraint at row index `row' in the conic model,
    # constrmap[row] gives the index of the constraint in the SD model,
    # a value of 0 meaning that it does not correspond to any constraint
    model.constrmap = constrmap = Vector{Int}(undef, m)
    constrmapcheck = BitSet()
    # slackmap[row] gives (blk,i,j,coef) indicating that a slack variable has been created at X[blk][i,j] with coefficient coef
    # blk=0 corresponds to no slack
    slackmap = Vector{Tuple{Int,Int,Int,Float64}}(undef, m)
    model.constrscaling = constrscaling = ones(Float64, m)
    for (cone,idxs) in constr_cones
        if cone == :Free
            for idx in idxs
                push!(constrmapcheck, idx)
            end
            constrmap[idxs] = 0
            slackmap[idxs] = 0
        else
            for idx in idxs
                constr += 1
                push!(constrmapcheck, idx)
                constrmap[idx] = constr
            end
            if cone == :Zero
                for idx in idxs
                    slackmap[idx] = (0,0,0,0.)
                end
            elseif cone == :NonNeg
                for idx in idxs
                    blk += 1
                    push!(blkdims, 1)
                    slackmap[idx] = (blk,1,1,1.)
                end
            elseif cone == :NonPos
                for idx in idxs
                    blk += 1
                    push!(blkdims, 1)
                    slackmap[idx] = (blk,1,1,-1.)
                end
            elseif cone == :SOC
                blk += 1
                push!(blkdims, length(idxs))
                for i in 1:length(idxs)
                    slackmap[idxs[i]] = (blk,1,i,i == 1 ? 1. : .5)
                end
                push!(socblks, blk)
                push!(socblksvarconemap, 0)
            elseif cone == :SOCRotated
                blk += 1
                push!(blkdims, length(idxs)-1)
                slackmap[idxs[1]] = (blk,1,1,1.)
                slackmap[idxs[2]] = (blk,2,2,.5)
                for i in 3:length(idxs)
                    slackmap[idxs[i]] = (blk,1,i-1,.5)
                end
                push!(socblks, blk)
                push!(socblksrotated, length(socblks))
                push!(socblksvarconemap, 0)
            elseif cone == :SDP
                d = getmatdim(length(idxs))
                k = 0
                blk += 1
                push!(blkdims, d)
                for i in 1:d
                    for j in i:d
                        k += 1
                        slackmap[idxs[k]] = (blk,i,j,i == j ? 1. : .5)
                        if i != j
                            constrscaling[idxs[k]] = 1/sqrt(2)
                        end
                    end
                end
            else
                throw(ArgumentError("Unrecognized cone $cone"))
            end
        end
    end
    if constrmapcheck != BitSet(1:m)
        throw(ArgumentError("Some variable have no cone"))
    end
    @assert blk == length(blkdims)

    socconstr = Vector{Int}(undef, length(socblks))
    for i in 1:length(socblks)
        blk = socblks[i]
        d = blkdims[blk]
        socconstr[i] = constr
        nconstr = d*(d-1)
        if i in socblksrotated
            nconstr -= 1
        end
        constr += div(nconstr, 2)
    end

    # Writing the sparse block diagonal matrices
    sdmodel = model.sdmodel
    MPB.loadproblem!(sdmodel, blkdims, constr)
    for row in 1:m
        if constrmap[row] != 0
            setconstrB!(sdmodel, b[row] * constrscaling[row], constrmap[row])
        end
        blk, i, j, coef = slackmap[row]
        if blk != 0
            @assert coef != 0
            setconstrentry!(sdmodel, coef, constrmap[row], blk, i, j)
        end
    end
    if isa(A, SparseMatrixCSC)
        rows = rowvals(A)
        vals = nonzeros(A)
        for col in 1:n
            for k in nzrange(A, col)
                row = rows[k]
                if constrmap[row] != 0 # Free constraint
                    val = vals[k]
                    for (blk, i, j, coef) in varmap[col]
                        @assert coef != 0
                        setconstrentry!(sdmodel, val*coef*constrscaling[row], constrmap[row], blk, i, j)
                    end
                end
            end
        end
    else
        for row in 1:m
            if constrmap[row] != 0
                for col in 1:n
                    val = A[row,col]
                    if val != 0
                        for (blk, i, j, coef) in varmap[col]
                            @assert coef != 0
                            setconstrentry!(sdmodel, val*coef*constrscaling[row], constrmap[row], blk, i, j)
                        end
                    end
                end
            end
        end
    end
    model.varnewconstrmap = varnewconstrmap = Dict{NTuple{3, Int}, Vector{Tuple{Int,Float64}}}()
    for k in 1:length(socblks)
        constr = socconstr[k]
        blk = socblks[k]
        diageq = k in socblksrotated ? 2 : 1
        d = blkdims[blk]
        for i in 2:d
            for j in i:d
                if i != j || i > diageq
                    constr += 1
                    setconstrB!(sdmodel, 0, constr)
                    setconstrentry!(sdmodel, i==j ? 1. : .5, constr, blk, i, j)
                    if i == j && i > diageq
                        varcone = socblksvarconemap[k]
                        if varcone != 0
                            _, idxs = var_cones[varcone]
                            key = (blk, diageq, diageq)
                            if !haskey(varnewconstrmap, key)
                                varnewconstrmap[key] = Tuple{Int, Float64}[]
                            end
                            push!(varnewconstrmap[key], (constr, -1.))
                        end
                        setconstrentry!(sdmodel, -1., constr, blk, diageq, diageq)
                    end
                end
            end
        end
    end
    for col in 1:n
        if c[col] != 0
            for (blk, i, j, coef) in varmap[col]
                # in SDP format, it is max and in MPB Conic format it is min
                setobjentry!(sdmodel, -coef*c[col], blk, i, j)
            end
        end
    end
end

MPB.optimize!(model::SDtoConicBridge) = MPB.optimize!(model.sdmodel)
MPB.status(model::SDtoConicBridge) = MPB.status(model.sdmodel)

function MPB.getobjval(model::SDtoConicBridge)
    -MPB.getobjval(model.sdmodel)
end

function MPB.getsolution(model::SDtoConicBridge)
    X = MPB.getsolution(model.sdmodel)
    n = size(model.A, 2)
    x = zeros(Float64, n)
    for col in 1:n
        for (blk, i, j, coef) in model.varmap[col]
            if i != j
                coef *= 2
            end
            x[col] += X[blk][i,j] * coef
        end
    end
    x
end

function MPB.getdual(model::SDtoConicBridge)
    y = MPB.getdual(model.sdmodel)
    constrmap = model.constrmap
    constrscaling = model.constrscaling
    m = size(model.A, 1)
    dual = Vector{Float64}(undef, m)
    for row in 1:m
        if constrmap[row] != 0
            dual[row] = y[constrmap[row]] * constrscaling[row]
        else
            dual[row] = 0
        end
    end
    dual
end

function MPB.getvardual(model::SDtoConicBridge)
    y = MPB.getdual(model.sdmodel)
    Z = MPB.getvardual(model.sdmodel)
    n = size(model.A, 2)
    z = zeros(Float64, n)
    for col in 1:n
        for (blk, i, j, coef) in model.varmap[col]
            cur = Z[blk][i,j]
            if haskey(model.varnewconstrmap, (blk, i, j))
                for (constr, ccoef) in model.varnewconstrmap[(blk, i, j)]
                    cur -= y[constr] * ccoef
                end
            end
            z[col] += cur / coef
        end
    end
    z
end

function MPB.getvartype(model::SDtoConicBridge, col)
    # they are all supposed to be the same so we take the first one
    blk, i, j, _ = first(model.varmap[col])
    MPB.getvartype(model.sdmodel, blk, i, j)
end

function MPB.setvartype!(model::SDtoConicBridge, vtype)
    for (col, vt) in enumerate(vtype)
        for (blk, i, j, _) in model.varmap[col]
            MPB.setvartype!(model.sdmodel, vt, blk, i, j)
        end
    end
end

for f in MPB.methods_by_tag[:rewrap]
    @eval MPB.$f(model::SDtoConicBridge) = MPB.$f(model.sdmodel)
end
