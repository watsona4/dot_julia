using GeometryTypes
using SurfaceTopology
using LinearAlgebra

function quadraticform(vects,vnormal)
    
    Lx = [0 0 0; 0 0 -1; 0 1 0]
    Ly = [0 0 1; 0 0 0; -1 0 0]
    Lz = [0 -1 0; 1 0 0; 0 0 0]

    d = [0,0,1] + vnormal
    d /= norm(d)
        
    Ln = d[1]*Lx + d[2]*Ly + d[3]*Lz
    R = exp(pi*Ln)

    vects = copy(vects)
    for vj in 1:length(vects)
        vects[vj] = R*vects[vj]
    end

    ### Construction of the system
    A = Array{Float64}(undef,3,3)
    B = Array{Float64}(undef,3)

    vects_norm2 = Array{Float64}(undef,length(vects))
    for vj in 1:length(vects)
       vects_norm2[vj] = norm(vects[vj])^2
    end

    A[1,1] = sum((v[1]^4 for v in vects) ./ vects_norm2)
    A[1,2] = sum((v[1]^3*v[2] for v in vects) ./ vects_norm2)
    A[1,3] = sum((v[1]^2*v[2]^2 for v in vects) ./ vects_norm2)
    A[2,1] = A[1,2]
    A[2,2] = A[1,3]
    A[2,3] = sum( (v[2]^3*v[1] for v in vects) ./vects_norm2)
    A[3,1] = A[1,3]
    A[3,2] = A[2,3]
    A[3,3] = sum((v[2]^4 for v in vects) ./vects_norm2)

    
    B[1] = sum((v[3]*v[1]^2 for v in vects) ./vects_norm2)
    B[2] = sum((v[1]*v[2]*v[3] for v in vects) ./vects_norm2)
    B[3] = sum((v[2]^2*v[3] for v in vects) ./vects_norm2)
    
    C,D,E = A\B
    return C,D,E
end

function meancurvature(points,topology)
    curvatures = Array{Float64}(undef,length(points))
    for v in 1:length(points)

        s = Point(0,0,0)
        for (v1,v2) in EdgeRing(v,topology)
            s += cross(points[v2],points[v1])
        end
        normal = s ./ norm(s)

        vring = collect(VertexRing(v,topology))
        vects = [points[vi] - points[v] for vi in vring]

        C,D,E = quadraticform(vects,normal)

        A = [C D/2;D/2 E]
        k1,k2 = eigvals(-A)
        H = (k1 + k2)/2

        curvatures[v] = H
    end
    return curvatures
end

### Testing
t = ( 1 + sqrt( 5 ) ) / 2;

vertices = Point{3,Float64}[
    [ -1,  t,  0 ], [  1, t, 0 ], [ -1, -t,  0 ], [  1, -t,  0 ],
    [  0, -1,  t ], [  0, 1, t ], [  0, -1, -t ], [  0,  1, -t ],
    [  t,  0, -1 ], [  t, 0, 1 ], [ -t,  0, -1 ], [ -t,  0,  1 ]
] ./ sqrt(1 + t^2)

faces = Face{3,Int64}[
    [1, 12, 6], [1, 6, 2], [1, 2, 8], [1, 8, 11], [1, 11, 12], [2, 6, 10], [6, 12, 5], 
    [12, 11, 3], [11, 8, 7], [8, 2, 9], [4, 10, 5], [4, 5, 3], [4, 3, 7], [4, 7, 9],  
    [4, 9, 10], [5, 10, 6], [3, 5, 12], [7, 3, 11], [9, 7, 8], [10, 9, 2] 
]

### As paraboloid grows faster than sphere the estimated curvature for a coarse mesh would be lower
curvatures = meancurvature(vertices,faces)
