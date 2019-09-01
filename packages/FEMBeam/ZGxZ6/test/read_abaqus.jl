# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/FEMBeam.jl/blob/master/LICENSE

# Read ABAQUS .mtx files

s = """
** Assembled nodal loads
*CLOAD, REAL
2,3,  5.400000000000027e+04
2,5,  9.000000000000071e+03
"""

t = """
-1,1, -1,1,  3.333333333333317e+01
-1,2, -1,1, -8.333333333333492e+00
1,1, -1,1,  2.500000000000002e+01
2,1, -1,1, -2.500000000000002e+01
-1,2, -1,2,  3.333333333333316e+01
1,1, -1,2,  2.500000000000003e+01
2,1, -1,2, -2.500000000000003e+01
1,1, 1,1,  1.000000000000000e+36
2,1, 1,1, -3.000000000000020e+02
1,2, 1,2,  1.000000000000000e+36
1,6, 1,2,  5.999999999999996e+00
2,2, 1,2, -1.199999999999999e+01
2,6, 1,2,  5.999999999999996e+00
1,3, 1,3,  1.000000000000000e+36
1,5, 1,3, -8.999999999999996e+00
2,3, 1,3, -1.799999999999999e+01
2,5, 1,3, -8.999999999999996e+00
1,4, 1,4,  1.000000000000000e+36
2,4, 1,4, -2.400000000000012e-01
1,5, 1,5,  1.000000000000000e+36
2,3, 1,5,  8.999999999999996e+00
2,5, 1,5,  2.999999999999990e+00
1,6, 1,6,  1.000000000000000e+36
2,2, 1,6, -5.999999999999996e+00
2,6, 1,6,  1.999999999999993e+00
2,1, 2,1,  3.000000000000020e+02
2,2, 2,2,  1.199999999999999e+01
2,6, 2,2, -5.999999999999996e+00
2,3, 2,3,  1.799999999999999e+01
2,5, 2,3,  8.999999999999996e+00
2,4, 2,4,  2.400000000000012e-01
2,5, 2,5,  6.000000000000006e+00
2,6, 2,6,  4.000000000000004e+00
"""

function read_mtx(data; dim=0)
    if dim == 0
        for ln in eachline(copy(data))
            i,idof,j,jdof,value = map(Meta.parse, split(ln, ','))
            dim = max(dim, idof, jdof)
        end
    end
    I = Int64[]
    J = Int64[]
    V = Float64[]
    for ln in eachline(data)
        i,idof,j,jdof,value = map(Meta.parse, split(ln, ','))
        if i < 1 || j < 1
            continue
        end
        push!(I, (i-1)*dim+idof)
        push!(J, (j-1)*dim+jdof)
        push!(V, value)
    end
    A = Matrix(sparse(I, J, V))
    A += transpose(tril(A,-1))
    return A
end

function read_mtx_from_str(data)
    read_mtx(IOBuffer(data))
end

#A = read_mtx(IOBuffer(t))
#display(A)
