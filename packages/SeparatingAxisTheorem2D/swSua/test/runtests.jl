using SeparatingAxisTheorem2D
using CoordinateTransformations
using StaticArrays
using Test

v = SVector(.5, .5)
w = SVector(1.5, 1.5)
B = AABB((0., 1.), (0., 1.))
L = LineSegment(v, w)
P = Polygon((0., 0.), (1.5, 0.), (0., 1.5))
C = Circle((1.4, 1.4), .2)
S = CompoundShape(B, P, C)

@test  intersecting(v, B)
@test  intersecting(v, P)
@test !intersecting(v, C)
@test  intersecting(v, S)
@test !intersecting(w, B)
@test !intersecting(w, P)
@test  intersecting(w, C)
@test  intersecting(w, S)
@test  intersecting(B, L)
@test  intersecting(B, P)
@test !intersecting(B, C)
@test  intersecting(L, P)
@test  intersecting(L, C)
@test !intersecting(P, C)
