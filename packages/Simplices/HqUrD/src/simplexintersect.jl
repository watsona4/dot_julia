
"""
	  simplexintersection(S1::Array{Float64, 2}, S2::Array{Float64, 2};
        tolerance::Float64 = 1/10^10) -> Float64

Computes the volume of intersection between two n-dimensional simplices
by boundary triangulation. The simplices `S1` and `S2` are arrays of
(n, n+1), where each column is a vertex.

Note: the returned volume is not corrected. It should be divided by factorial(dim)
to obtain the true volume.

## How are intersections computed?
Intersections are computed as follows:

1. Find minimal set of points generating the intersection volume. These points form
a convex polytope Pᵢ.
2. Triangulate the faces of Pᵢ into simplices.
3. Combine each boundary simplex with an interior point in Pᵢ. The set of
all such combinations form a triangulation of Pᵢ.
4. Calculate the volume of each simplex in the resulting triangulation. The
sum of these volumes is the volume of the intersection.
"""
function simplexintersection(simplex1, simplex2; tol::Float64 = 1/10^10)
  # Nasty hack until we re-do everything for vectors of vectors.
  S1 = Array(simplex1)
  S2 = Array(simplex2)

  # Dimension
  n = size(S1, 1)

  # Centroid and radii
  c1 = Circumsphere(S1)[2:n+1]
  c2 = Circumsphere(S2)[2:n+1]
  r1 = Circumsphere(S1)[1]
  r2 = Circumsphere(S2)[1]

  # Orientation of simplices
  orientation_S1 = det([ones(1, n + 1); S1])
  orientation_S2 = det([ones(1, n + 1); S2])

  if abs(orientation_S1) < tol || abs(orientation_S2) < tol
    return 0.0
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
    # Find the number of points of each simplex contained within the
    # circumsphere of the other simplex

    vertices1InCircum2 = SomeVertexInCircumsphere(S1, r2, c2)
    vertices2InCircum1 = SomeVertexInCircumsphere(S2, r1, c1)

    # At least one circumsphere contains vertices of the other simplex
    #println("")

    if vertices1InCircum2 + vertices2InCircum1 >= 1
      βs1in2, βs2in1, ordered_vertices1, ordered_vertices2, numof1in2, numof2in1 =
        BarycentricCoordinates(S1,S2,orientation_S1,orientation_S2,tol)
      # Trivial intersections
      TriviallyContained = heaviside0([numof1in2 numof2in1] .- (n+1))
      IsSomeContained = sum(TriviallyContained, dims=2)[1]

      if IsSomeContained == 2.0 # The simplices coincide
        IntVol = abs(orientation_S1)
      elseif IsSomeContained == 1.0 # One simplex is contained in the other

        if TriviallyContained[1] == 1.0 # Simplex1 is contained in Simplex2
          IntVol = abs(orientation_S1)
        else # Simplex2 is contained in Simplex1
          IntVol = abs(orientation_S2)
        end
      else # No simplex contains the other

        #print("SharedVertices\t\t\t")

        Ncomm, ordered_vertices1, ordered_vertices2 = SharedVertices(βs1in2,ordered_vertices1,ordered_vertices2,numof1in2,numof2in1)

        # Is there any shared face?
        if Ncomm == n
          IntVol = SharedFaceVolume(S2, βs1in2, ordered_vertices1, ordered_vertices2)
        else # The simplices do not share a face.
          IntVert, ConvexExpIntVert = IntersectionOfBoundaries_NoStorage(S1,S2,βs1in2,βs2in1, ordered_vertices1, ordered_vertices2, numof1in2, numof2in1, Ncomm, tol)
          if !isempty(IntVert)
            IntVert,ConvexExpIntVert = PolytopeGeneratingVertices(S1,S2,IntVert,ConvexExpIntVert,βs1in2,βs2in1,ordered_vertices1,ordered_vertices2,numof1in2,numof2in1,Ncomm);
            IntVol = VolumeComputation(IntVert, ConvexExpIntVert)
          end
        end
      end
    else
      #println("No circumsphere of either simplex contains vertices of the other simplex")
    end
  end

  return IntVol
end

export simplexintersection
