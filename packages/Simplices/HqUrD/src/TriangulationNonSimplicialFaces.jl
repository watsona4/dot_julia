include("Delaunay.jl")
using .Delaunay


#TODO:: Needs revision. Doesn't work.
function TriangulationNonSimplicialFaces(VerticesNSFaces,SimplexIndexNS,SimplexFaceIndexNS,ConvexExpIntVert,n)
    #println("\n\n@TriangulationNonSimplicialFaces...\n\n")
    TriangNSFaces = [0]
    numofNSFaces = size(VerticesNSFaces, 2)

    for a = 1:numofNSFaces
        # Contains the indices of the elements in IntVert generating the corresponding
        # polytope face.
        Indices = findall(x->x!=0, VerticesNSFaces[:, a])

        FaceVert = complementary(SimplexFaceIndexNS[a], n + 1) .+ (SimplexIndexNS[a] - 1) * (n + 1)
        BarCoordinates = ConvexExpIntVert[Indices, FaceVert]

        # The rows of this array contain the (strictly positive) concvex exp. coefficients of
        # the IntPoints generating the polytope face, in terms of the vertices
        # generating the simplex sharing the boundary with the polytope face
        i = size(BarCoordinates, 1)
        BarCoordinates = [ones(1, i); transpose(BarCoordinates)]

        # The columns of Null form a basis of the Null space of BarCoordinates
        # PermC is a permutation of the columns of BarCoordinates (or the
        # rows of Null) such that Null(PermC,:)=[M;eye(N)] with M some
        # matrix and N the number of columns in Null.
        Null, PermC = NullSpace(BarCoordinates, n)

        CopBarCoord = zeros(n, i)
        CopBarCoord[:, PermC[1:n]] = Matrix(1.0I, n, n)
        CopBarCoord[:, PermC[(n + 1):i]] = - Null[PermC[1:n], :]

        CoplanarCoord = CopBarCoord[2:n, :]
        CoplanarCoord[:, PermC[1]] .= 0.0

        # Triangulating
        simplices = delaunayn(copy(transpose(CoplanarCoord)))
        # Notice that the order in the argument of delaunayn
        # corresponds to the order given by Indices
        # The rows of simplices contain the indices of the vertices generating
        # the corresponding simplex in the order given by Indices, on the other hand
        # the entries of Indices correspond to the indices of the original intersecting
        # points in IntVert
        d = size(simplices, 1)

        # Triangulation of the non simplicial face a. The indices of the vertices generating
        # the simplices now correspond to the order given by IntVert
        Aux = reshape(transpose(simplices), n * d, 1)
        simplices = transpose(reshape(Indices[Aux], n, d))

        if a == 1
            TriangNSFaces = simplices;
        else
            TriangNSFaces = [TriangNSFaces; simplices]
        end
    end
    return TriangNSFaces
end
