export tensor

function Base.binomial(d, alpha::Vector{Int64})
  r = binomial(d, alpha[1])
  for i in 2:length(alpha)
      d -= alpha[i-1]
      r *= binomial(d, alpha[i])
  end
  r
end


"""
```
tensor(w, Xi, V, d) -> Polynomial{true,T} 
```
Compute ``∑ wᵢ (ξ_{i,1} V₁ + ... + ξ_{i,n} Vₙ)ᵈ`` where 

- `Xi` is a column-wise matrix of r points, 
- `V`  is a vector of variables,
- `d`  is a degree.

## Example

```
using MultivariateSeries
X = @ring x0 x1 x2
w = rand(5)
Xi = rand(3,5)
tensor(w,Xi,X,4)
```
"""
function tensor(w::Vector{T}, Xi::Matrix{U}, V::Vector, d::Int64) where {T,U}
    r = length(w)
    p = sum( w[i]* dot(Xi[:,i],V)^d for i in 1:r)
end
"""
```
tensor(w, Xi, V, d) -> MultivariatePolynomial
```
Compute ``∑ wᵢ Π_j(ξ_{i,j,1} V[j][1] + ... + ξ_{i,j,n_j} V[j][n_j])^d[j]`` where 
- `Xi` is a vector of matrices of points, 
- `V`  is a vector of vectors of variables,
- `d`  is a vector of degrees.

## Example

```
using MultivariateSeries
X = @ring x0 x1 x2
Y = @ring y0 y1
w = rand(5)
Xi0 = rand(3,5)
Xi1 = rand(2,5)
tensor(w,[Xi0,Xi1],[X,Y],[4,2])
```
"""
function tensor(w::Vector{T}, Xi::Vector{Matrix{U}}, V::Vector, d::Vector{Int64}) where {T,U}
    r = length(w)
    sum( w[i]*prod( dot(Xi[j][:,i],V[j])^d[j] for j in 1:length(d)) for i in 1:r)
end
