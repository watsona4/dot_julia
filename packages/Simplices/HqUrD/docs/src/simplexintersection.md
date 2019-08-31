# How to compute intersections?

The intersection between two n-dimensional simplices is calculated boundary triangulation.

## Boundary triangulation method
Intersections are computed as follows.

1. Find minimal set of points generating the intersection volume. These points form a convex polytope Pᵢ.
2. Triangulate the faces of Pᵢ into simplices.
3. Then combine each resulting boundary simplex with an interior point in Pᵢ. The set of all such combinations now form a triangulation of Pᵢ.
4. Calculate the volume of each simplex in the resulting triangulation. Summing over these volumes given the volume of the intersection.
