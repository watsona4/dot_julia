# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/FEMBeam.jl/blob/master/LICENSE

datadir = joinpath(Pkg.dir("FEMBeam"), "test", first(splitext(basename(@__FILE__))))

"""
    read_mtx(fn)

Read matrix file written using ABAQUS:

*MATRIX GENERATE, STIFFNESS, MASS, LOAD
*MATRIX OUTPUT, STIFFNESS, MASS, LOAD

"""
function read_mtx(fn; dim=error("dofs / node missing: pass argument dim::Int64"))
    I = Int64[]
    J = Int64[]
    V = Float64[]
    open(fn) do fid
        for ln in eachline(fid)
            i,idof,j,jdof,value = map(parse, split(ln, ','))
            if i < 1 || j < 1
                continue
            end
            push!(I, (i-1)*dim+idof)
            push!(J, (j-1)*dim+jdof)
            push!(V, value)
        end
    end
    return sparse(I,J,V)
end

function read_mtx!(A, fn)
    open(fn) do fid
        for ln in eachline(fid)
            i,idof,j,jdof,value = map(parse, split(ln, ','))
            A[i,idof,j,jdof] = value
        end
    end
    return A
end

K = read_mtx(joinpath(datadir, "eb3arxs4_STIF1.mtx"); dim=6)
# K1 = read_mtx(joinpath(datadir, "stif.mtx"); dim=2)
# K2 = zeros(2, 2, 2, 2)
# read_mtx!(K2, joinpath(datadir, "stif.mtx"))

println(K)
