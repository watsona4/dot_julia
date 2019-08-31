"""
    Triangulate the polytope faces.

`βs` is an npoints-by-(2*dim + 2) dimensional array of convex expansion coefficients of the
polytope generators (vertices) in terms of the original simplices s₁ and s₂. The first
(dim + 1) columns correspond to s₁, while the remaining (dim + 1) columns correspond to s₂.

`n` is the the dimension of the space, and `dim` number of generators of the polytope.
"""
function TriangulationPolytopeFaces(βs::AbstractArray{Float64, 2}, n_generators::Int, dim::Int)
    # We adopt the notations
    # NSF ≡ Nonsimplicial faces
    # APF ≡ All polytope faces.
    triang_NSF = zeros(Int, 0, dim + 1)
    triang_APF = zeros(Int, 0, dim + 1)

    faces_containing_intvers = βs[βs .== 0]

    # Find the faces containing intersecting vertices.
    faces_containing_intvers = zeros(Int, size(βs))
    faces_containing_intvers[βs .== 0] .= 1 # set zero convex parameters to 1
    faces_containing_intvers[βs .> 0] .= 0 # set positive convex parameters to 0

    # What is the number of intersecting points in each of the faces?
    n_intpoints_ineachface = ones(Int, 1, n_generators) * faces_containing_intvers
    n_intpoints_ineachface = sum(faces_containing_intvers, dims=1)

    # Indices of the potential faces of the polytope. Different indices might correspond
    # to the same face.
    faceindices = transpose(heaviside0(n_intpoints_ineachface .- dim)) .* (1:2*dim+2)
    faceindices = (LinearIndices(faceindices))[findall(x->x!=0, faceindices)]

    # The number of faces of the intersecting volume polytope
    numofPolFaces = length(faceindices)

    # The number vertices furnishing each polytope face.
    n_intpoints_ineachface = round.(Int64, n_intpoints_ineachface[faceindices])

    # The indices of the intersecting points (in IntVert) furnishing each polytope face.
    # Array of dimension dim x numofPolFaces. Each column represents a potential polytope face.
    npts_eachface = faces_containing_intvers[:, faceindices] .*
                            repeat(collect(1:n_generators), 1, numofPolFaces)


    # Go through each faces and decide whether it is a true face or a boundary of a face.
    # Disregard stuff if it is not a true face. 'NSF_inds' starts out with only
    # zeros. If the potential polytope face is a true face, then set the value for that
    # face to 1.
    NSF_inds = classify_faces(numofPolFaces, βs, dim, npts_eachface, faceindices)
    n_NSF = length(NSF_inds) # The number of nonsingular faces

    if n_NSF >= dim + 1
        # all these arrays contain the corresponding information but only for the
        # non singular faces. And therefore, the second dimension goes over 1:n_NSF
        NonSingularPolytopeFaces = faceindices[NSF_inds]
        NumOfVertInEachFace = n_intpoints_ineachface[NSF_inds]
        NonSingularPointsInEachFace = npts_eachface[1:end, vec(NSF_inds)]
        # THe number of polytope faces that are actually simplices
        Simplicial = vec(findall(x->x!=0, heaviside0(dim .- NumOfVertInEachFace) .* collect(1:n_NSF)))
        NonSimplicialFaces = 0

        if length(Simplicial) == 0
            #println("No polytope faces are simplices")
            NonSimplicialFaces = NonSingularPolytopeFaces
            NonSimplicial = 1:n_NSF
            VerticesSFaces = 0
        elseif length(Simplicial) == n_NSF
            #println("All polytope faces are simplices")

            VerticesSFaces = NonSingularPointsInEachFace
            inner = reshape(VerticesSFaces, size(Simplicial, 1) * n_generators, 1)
            inner_nonzeros = inner[findall(x->x!=0, inner)]
            inner_reshaped_transposed = copy(transpose(reshape(inner_nonzeros, dim, size(Simplicial, 1))))
            VerticesSFaces = inner_reshaped_transposed
        else
            #println("Some polytope faces are simplices")

            VerticesSFaces = NonSingularPointsInEachFace[:, Simplicial]
            inner = reshape(VerticesSFaces, size(Simplicial, 1)*n_generators, 1)

            inner_nonzeros = inner[(LinearIndices(inner))[findall(x->x!=0, inner)]]
            inner_reshaped_transposed = transpose(reshape(inner_nonzeros, dim, size(Simplicial, 1)))
            VerticesSFaces = inner_reshaped_transposed
            NonSimplicial = complementary(Simplicial, n_NSF)
            NonSimplicialFaces = NonSingularPolytopeFaces[NonSimplicial]
        end

        if NonSimplicialFaces[1] > 0
            #println("One or more nonsimplical faces.")
            VerticesNSFaces = NonSingularPointsInEachFace[:, NonSimplicial]
            SimplexIndexNS = round.(Int64, ceil.(NonSimplicialFaces / (dim + 1)))
            SimplexFaceIndexNS = round.(Int64, NonSimplicialFaces .- (SimplexIndexNS .- 1) * (dim + 1))
            #t1 = time_ns()
            triang_NSF = TriangulationNonSimplicialFaces(VerticesNSFaces, SimplexIndexNS, SimplexFaceIndexNS, βs, dim)
            #t2 = time_ns()
            #println("Triangulation of nonsimplicial faces took ", (t2 - t1)/10^6, " ms")
        end
        if !isempty(triang_NSF)
            triang_APF = Update(VerticesSFaces, triang_NSF)
        end
    else
        #println("# Non-simplicial faces < n + 1\n")
    end
    return triang_APF, n_NSF
end



"""
Go through each faces and decide whether it is a true face or a boundary of a face.
Returns a vector of length equal to the number of faces in the intersecting polytope.
The ith entry of this vector is _i_ if the corresponding face is a true face, 0 otherwise.
"""
function classify_faces(numofPolFaces::Int,
                        βs::AbstractArray{Float64, 2},
                        dim::Int,
                        npts_eachface::AbstractArray{Int, 2},
                        faceindices::AbstractArray{Int, 1})

    NSF_inds = zeros(Int, 0)

    # Loop over faces.
    for faceindex = 1:numofPolFaces
        inds = findall(x->x!=0, npts_eachface[:, faceindex])
        Aux = heaviside0(-sum(βs[inds, :], dims=1))
        multiplicity = [Aux * ones(2*dim + 2, 1);
                        Aux * [ones(dim + 1, 1);
                        2 * ones(dim + 1, 1)]]
        #multiplicity(1): number of times that the face with index faceindices(a) appears
        #multiplicity(2): (number of faces of simplex1 containing the face) +
        #                   2*(number of faces of simplex2 containing the face)
        if multiplicity[1] == 1 || (multiplicity[1] == 2 && multiplicity[2] == 3 &&
                                    faceindices[faceindex] <= dim + 1)
            push!(NSF_inds, faceindex)
        end
    end

    return NSF_inds
end
