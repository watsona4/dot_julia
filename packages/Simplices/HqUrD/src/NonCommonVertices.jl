"""
    NonCommonVertices()

    Given the indices of vertices of a source simplex inside the circumsphere of a target simplex,
    find the indices of the vertices that are not shared between simplices, but still lie
    inside the circumference of the target simplex.


Input arguments
---------------
IndexIn::Array{Int, 1}              Row vector. Indices of the vertices of the source simplex inside the circumsphere of the target simplex.
InternalComIndex::Array{Int, 1}     Row vector. Indices of the vertices that both simplices share, but in the 'IndexIn' row vector of indices instead of the 'IndexComVert' vector.
Nin::Int                            Integer. Number of vertices inside the circumsphere of the target simplex. REDUNDANT? Essentially, length(IndexIn) - but remember to check for zeros
Ncomm::Int                          Integer. Number of common vertices between between source and target simplices.

Returns
-------
Res                                 Row vector. Indices of the vertices of the source simplex that are inside the circumsphere of the target simplex, but is not shared between the simplices.
"""

function NonCommonVertices(InternalComIndex,IndexIn,
                          n_vertices_in_circumsphere,
                          n_commonvertices)
  # IndexComVert: indices of the common vertices
  # IndexIn: indices of the vertices contained in the circumsphere
  # InternalComIndex: Indices of IndexComVert in IndexIn
  # Nin: number of vertices in the circumsphere

  # OUTCOME
  @show n_vertices_in_circumsphere
  @show n_commonvertices
  @show IndexIn
  @show InternalComIndex
  # Res: indices of the non common vertices still inside the circumsphere
  # if Res is empty, it returns 0
  if n_commonvertices == 0
    #println("n_commonvertices == 0")
    return IndexIn
  else
      if n_commonvertices == n_vertices_in_circumsphere
        #println("Number of vertices in circumsphere equals number of common vertices")
        return [0]
      else
        #println("Number of vertices in circumsphere does not equal number of common vertices")
        return IndexIn[complementary(InternalComIndex, n_vertices_in_circumsphere)]
     end
 end

end
