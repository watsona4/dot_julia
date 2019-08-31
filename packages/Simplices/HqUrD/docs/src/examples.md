
## Examples

We'll use a few of the functions used for testing the package to demonstrate its usage. These are
1. `simplices_sharing_vertices`. Generate a set of simplices which intersect in some arbitrary way, but sharing at least one vertex.
2. `nontrivially_intersecting_simplices`. Generate a set of non-trivially intersecting simplices (i.e. intersections are not only along boundaries or vertices).
3. `childsimplex(parentsimplex)`. Generate a simplex completely contained within `parentsimplex`.

Note that these functions take as inputs simplices of shape `(dim + 1, dim)`. This will be fixed in a future release.

In the examples, some of the functions used to generate simplices return the simplex arrays with rows as columns. Therefore, we transpose the simplices before calling [`simplexintersection`](@ref).

### Simplices sharing vertices
Let's compute the intersection between a set of simplices that share at least one vertex.

```@repl
using Simplices
s₁, s₂ = transpose.(simplices_sharing_vertices(3))

simplexintersection(s₁, s₂)
```

### Nontrivially intersecting simplices
Simplices can also intersect in nontrivial ways, meaning that they have an  intersection beyond a common boundary or vertex.

```@repl
using Simplices
s₁, s₂ = transpose.(nontrivially_intersecting_simplices(3))
simplexintersection(s₁, s₂)
```

### One simplex fully contained within the other
We'll generate a random simplex s₁, then generate a simplex s₂ fully
contained within that simplex. If s₂ is fully contained, the intersection
volume should be the volume of s₂.

```@repl
using Simplices

Ds =  2:10;
intersection_vols = zeros(Float64, length(Ds));
analytical_vols   = zeros(Float64, length(Ds));
for i = 1:length(Ds)
    s₁ = rand(Ds[i] + 1, Ds[i])
    s₂ = childsimplex(s₁)
    intersection_vols[i] = simplexintersection(s₁.', s₂.')
    analytical_vols[i] = volume(s₂)
end
hcat(intersection_vols, analytical_vols)


# Within numerical error, the results should be the same.

all([isapprox(intersection_vols[i], analytical_vols[i];
    atol = 1e-9) for i = 1:length(Ds)])
```

### Simplices are identical
If simplices are identical, the intersection volume should equal the volume of either simplex:

```@repl
using Simplices

s₁ = rand(4, 3); s₂ = s₁;

simplexintersection(s₁.', s₂.') .≈ volume(s₁) .≈ volume(s₂)
```
