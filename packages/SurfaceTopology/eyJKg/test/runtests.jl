using Test
using GeometryTypes
using SurfaceTopology

@info "Topology function tests"

faces =   Face{3,Int}[
    [6,   8,  11],
    [8,   6,   7],
    [5,   1,   4],
    [1,   5,   7],
    [5,   8,   7],
    [5,  10,  11],
    [8,   5,  11],
    [1,   3,   2],
    [3,   1,   7],
    [3,   6,   2],
    [6,   3,   7],
    [9,   5,   4],
    [5,  12,  10],
    [9,  12,   5],
    [10,  12,   4],
    [12,   9,   4]
]

triangles = []
for i in FaceRing(5,faces)
    push!(triangles,i)
end

@test sort(triangles)==[3,4,5,6,7,12,13,14]

triverticies = []
for i in EdgeRing(5,faces)
    #println("i")
    push!(triverticies,i)
end

@test (1,4) in triverticies

verticies = []
for i in VertexRing(5,faces)
    push!(verticies,i)
end

@test sort(verticies)==[1,4,7,8,9,10,11,12] #[1,2,6,7]

@info "Testing FaceDS"

# points = zero(faces)
fb = FaceDS(faces)

triangles = []
for i in FaceRing(5,fb)
    push!(triangles,i)
end
@test sort(triangles)==[3,4,5,6,7,12,13,14]

triverticies = []
for i in EdgeRing(5,fb)
    push!(triverticies,i)
end

@test Face(1,4) in triverticies

verticies = []
for i in VertexRing(5,fb)
     push!(verticies,i)
end

@test sort(verticies)==[1,4,7,8,9,10,11,12]

@info "Testing EdgeDS"

eb = EdgeDS(faces)

verticies = []
for i in VertexRing(5,eb)
     push!(verticies,i)
end

@test sort(verticies)==[1,4,7,8,9,10,11,12]

triverticies = []
for i in EdgeRing(5,eb)
    push!(triverticies,i)
end

@test Face(1,4) in triverticies

@info "Topology tests for Cached DS"

# At the moment limited to a closed surfaces

faces = Face{3,Int64}[
    [1, 12, 6], [1, 6, 2], [1, 2, 8], [1, 8, 11], [1, 11, 12], [2, 6, 10], [6, 12, 5], 
    [12, 11, 3], [11, 8, 7], [8, 2, 9], [4, 10, 5], [4, 5, 3], [4, 3, 7], [4, 7, 9],  
    [4, 9, 10], [5, 10, 6], [3, 5, 12], [7, 3, 11], [9, 7, 8], [10, 9, 2] 
]

cds = CachedDS(faces)

@test sort(collect(VertexRing(3,faces)))==sort(collect(VertexRing(3,cds)))

@test sort(collect(EdgeRing(3,faces)))==sort(collect(EdgeRing(3,cds)))

