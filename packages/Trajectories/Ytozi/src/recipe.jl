using RecipesBase
@recipe function f(X::Trajectory{<:AbstractVector,<:AbstractVector})
  X.t, X.x
end
