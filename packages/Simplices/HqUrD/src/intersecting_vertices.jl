function intersectingvertices(S1, S2; tol::Float64 = 1/10^10)
    # Dimension
    n = size(S1, 1)
    # Centroid and radii
	 c1, c2 = Circumsphere(S1)[2:n+1], Circumsphere(S2)[2:n+1]
  	 r1, r2 = Circumsphere(S1)[1], Circumsphere(S2)[1]

  	 # Orientation of simplices
  	 orientation_S1 = det([ones(1, n + 1); S1])
  	 orientation_S2 = det([ones(1, n + 1); S2])

  	 if abs(orientation_S1) < tol || abs(orientation_S2) < tol
        return Array{Float64, 2}(undef, 0, 0)
  	 end

  	# Set volume to zero initially. Change only if there is intersection
  	 IntVol = 0.0

    # -------------------------------------
    # Simplices intersect in some way
    # -------------------------------------

    # If the (distance between centroids)^2-(sum of radii)^2 < 0,
    # then the simplices intersect in some way.
    dist_difference::Float64 = (transpose(c1 - c2) * (c1 - c2) - (r1 + r2)^2)[1]

    if dist_difference < 0
        #@show "The simplices intersect in some way (possibly only along a boundary, with zero volume intersection)"
        # Find the number of points of each simplex contained within the
        # circumsphere of the other simplex
        vertices1InCircum2 = SomeVertexInCircumsphere(S1, r2, c2)
        vertices2InCircum1 = SomeVertexInCircumsphere(S2, r1, c1)

        if vertices1InCircum2 + vertices2InCircum1 >= 1
            βs1in2, βs2in1, ordered_vertices1, ordered_vertices2, numof1in2, numof2in1 =
            BarycentricCoordinates(S1,S2,orientation_S1,orientation_S2,tol)
            # Trivial intersections
            TriviallyContained = heaviside0([numof1in2 numof2in1] .- (n+1))
            IsSomeContained = sum(TriviallyContained, dims=2)[1]

            if IsSomeContained == 2.0 # The simplices coincide
                #@show "The simplices coincide"
                return copy(transpose(S1))
            elseif IsSomeContained == 1.0 # One simplex is contained in the other
                if TriviallyContained[1] == 1.0 # Simplex1 is contained in Simplex2
                    #@show "Simplex 1 is contained in simplex 2"
                    return copy(transpose(S1))
                else # Simplex2 is contained in Simplex1
                    #@show "Simplex 2 is contained in simplex 1"
                    return copy(transpose(S2))
                end
            else # No simplex contains the other
                #@show "No simplex contains the other"
                Ncomm, ordered_vertices1, ordered_vertices2 = SharedVertices(βs1in2,ordered_vertices1,ordered_vertices2,numof1in2,numof2in1)

                # Is there any shared face?
                if Ncomm == n
                    #@show "The simplices share a face"
                    IntVol = SharedFaceVolume(S2, βs1in2, ordered_vertices1, ordered_vertices2)
                    return transpose(SharedFaceVertices(S2, βs1in2, ordered_vertices1, ordered_vertices2))
                else # The simplices do not share a face.
                    #@show "The simplices do not share a face"
                    IntVert, ConvexExpIntVert = IntersectionOfBoundaries_NoStorage(S1,S2,βs1in2,βs2in1, ordered_vertices1, ordered_vertices2, numof1in2, numof2in1, Ncomm, tol)

                    if !isempty(IntVert)
                        IntVert,ConvexExpIntVert = PolytopeGeneratingVertices(S1,S2,IntVert,ConvexExpIntVert,βs1in2,βs2in1,ordered_vertices1,ordered_vertices2,numof1in2,numof2in1,Ncomm);
                        IntVol = VolumeComputation(IntVert, ConvexExpIntVert)

                        return IntVert

                    else
                        return Array{Float64, 2}(undef, 0, 0)
                    end
                end
            end
        else
            IntVert = Array{Float64, 2}(undef, 0, 0)
        end
    else
        IntVert = Array{Float64, 2}(undef, 0, 0)
    end

    return IntVert
end
