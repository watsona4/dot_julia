
"""
Is there zero intersection between two simplices?
"""
function zerointersection(S1::AbstractArray{Float64, 2}, S2::AbstractArray{Float64, 2})
    if toofaraparattointersect(S1, S2) == true
      return(true)
    end

    # If some simplex is singular, they cannot intersect
    if somesimplexissingular(S1, S2) == true;
      return(true)
    end
end



"""
Checks whether two simplices are too far apart to intersect.
"""
function toofaraparattointersect(S1::AbstractArray{Float64, 2}, S2::AbstractArray{Float64, 2})

      r1 = Geometry.squaredradius(S1)
      r2 = Geometry.squaredradius(S2)
      c1 = Geometry.centroid(S1)
      c2 = Geometry.centroid(S2)

      dist = norm(c1 - c2) - (sqrt(r1) + sqrt(r2))
      if dist >= 0
        return(true)
      else
        return(false)
      end
end


"""
Checks whether at least one of the two simplices defined by the vertices
in  'X' and 'Y' are singular. X and Y are matrices of dimension nx(n+1).
"""
function somesimplexissingular(X::Array{Float64, 2}, Y::Array{Float64, 2})
    n = size(X)[1]
    if (vcat(ones(1, n+1), X) == vcat(ones(1, n + 1), Y))
      print("At least one of the simplices is singular!")
      return true
    else
      return false
    end
end



"""
Make sure simplices are of the same dimension
"""
function validatesimplices(S1::Array{Float64, 2}, S2::Array{Float64, 2})
    assert(size(S1)[1] == size(S1)[1])
end
