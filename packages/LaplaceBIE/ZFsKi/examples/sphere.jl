using GeometryTypes
using LinearAlgebra

"""
    subdivide(msh::HomogenousMesh,f::Function)

Returns a subdived triangular mesh from passed mesh `msh` and interpolator function `f`. The interpolator `f` is expected to accept two vertex indicies of the edge and to return a tuple of coordinates of the middle point (as one wishes to define it).
"""
function subdivide(msh::HomogenousMesh,f::Function)
    edges = filter(x->x[1]<x[2],decompose(Face{2,Int},msh))
    epoint(v1,v2) = findfirst(x->x==(v2>v1 ? Face(v1,v2) : Face(v2,v1)), edges) + length(msh.vertices)

    newfaces = Face{3,Int}[]

    newvertices = copy(msh.vertices)
    resize!(newvertices,length(msh.vertices) + length(edges))

    for (v1,v2,v3) in msh.faces

        ev3 = epoint(v1,v2)
        ev1 = epoint(v2,v3)
        ev2 = epoint(v3,v1)

        ### Usually, does assignment twice but is important if the surface is not tightly connected
        newvertices[ev3] = Point(f(v1,v2)...)
        newvertices[ev1] = Point(f(v2,v3)...)
        newvertices[ev2] = Point(f(v3,v1)...)

        push!(newfaces,Face(v1,ev3,ev2))
        push!(newfaces,Face(v2,ev1,ev3))
        push!(newfaces,Face(v3,ev2,ev1))
        push!(newfaces,Face(ev1,ev2,ev3))
    end

    return HomogenousMesh(newvertices,newfaces)
end

"""
    unitsphere(n)

Returns a sphere mesh made out of icosahedron subdivided `n` times.
"""
function unitsphere(subdivissions::Int64)
    t = ( 1 + sqrt( 5 ) ) / 2;

    vertices = Point{3,Float64}[
        [ -1,  t,  0 ], [  1, t, 0 ], [ -1, -t,  0 ], [  1, -t,  0 ],
        [  0, -1,  t ], [  0, 1, t ], [  0, -1, -t ], [  0,  1, -t ],
        [  t,  0, -1 ], [  t, 0, 1 ], [ -t,  0, -1 ], [ -t,  0,  1 ]
    ]

    faces = Face{3,Int64}[
        [1, 12, 6], [1, 6, 2], [1, 2, 8], [1, 8, 11], [1, 11, 12], [2, 6, 10], [6, 12, 5],
        [12, 11, 3], [11, 8, 7], [8, 2, 9], [4, 10, 5], [4, 5, 3], [4, 3, 7], [4, 7, 9],
        [4, 9, 10], [5, 10, 6], [3, 5, 12], [7, 3, 11], [9, 7, 8], [10, 9, 2]
    ]

    msh = HomogenousMesh(vertices ./ sqrt(1+t^2),faces)

    function sf(msh,v1,v2)
        p1 = msh.vertices[v1]
        p2 = msh.vertices[v2]
        return (p1 + p2)/norm(p1+p2)
    end


    for i in 1:subdivissions
        msh = subdivide(msh,(v1,v2)->sf(msh,v1,v2))
    end

    return msh
end

