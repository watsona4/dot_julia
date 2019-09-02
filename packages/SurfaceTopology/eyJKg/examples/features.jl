# # Intorduction

# As we know, triangular meshes can be stored in a computer in multiple different ways, each having strength and weaknesses in a particular case at hand. But it is not always clear which data structure would be most suitable for a specific task. Thus it is wise to write a data structure generic code which is the precise purpose of this package for closed oriented closed surfaces. 

# The most straightforward representation of triangular mesh topology is in array `Array{Faces{3,Int},1}` containing a list of triangular faces which are defined by their vertices. That as name stands allows quick iteration over faces and also edges. However, often in a numerical code one wants not only to iterate over faces or vertices but also in case of singularity subtraction, integration and local property estimation like in normal vector and curvature calculations to know what are neighbouring vertices surrounding a given vertex while keeping track of the orientation of the normals. Also, one wishes to modify the topology itself by collapsing, flipping and splitting edges. And that is why different data structures are needed for different problems.

# Fortunately, it is possible to abstract mesh topology queries through iterators:
# ```@docs
# Faces
# Edges
# ```
# and circulators:
# ```@docs
# VertexRing
# EdgeRing
# ```


# ## API

# The package implements multiple kinds of data structures. The simplest one is `PlainDS` one which stores a list of faces and is just an alias to `Array{Faces{3,Int},1}`. As an example of how that works, let's define the data structure.

using GeometryTypes
using SurfaceTopology

faces = Face{3,Int64}[
    [1, 12, 6], [1, 6, 2], [1, 2, 8], [1, 8, 11], [1, 11, 12], [2, 6, 10], [6, 12, 5], 
    [12, 11, 3], [11, 8, 7], [8, 2, 9], [4, 10, 5], [4, 5, 3], [4, 3, 7], [4, 7, 9],  
    [4, 9, 10], [5, 10, 6], [3, 5, 12], [7, 3, 11], [9, 7, 8], [10, 9, 2] 
]


# We can use the data structure `PlainDS` for the queries. The iterators, for example.
collect(Faces(faces))
# and
collect(Edges(faces))
# giving us desirable output.

# We can also ask what neighbouring vertices and edges for a particular vertex by using circulators. For this simple data structure that requires us to do a full lookup on the face list, which is nicely abstracted away:
collect(VertexRing(3,faces))
# and
collect(EdgeRing(3,faces))
# In practice, one should use `EdgeRing` over `VertexRing` since, in the latter one, vertices are not ordered and thus can not be used for example to deduce the direction of the normal vector. 

# ## Data structures

# The same API works for all other data structures. There is a data structure `CachedDS` built on top of `PlainDS` stores closest vertices (vertex ring). Then there is a data structure `FaceDS` which with `PlainDS` also stores neighbouring faces which have a common edge. And then there is the most commonly used data structure in numerics `HalfEdgeDS` (implemented as `EdgeDS`).

# The most straightforward extension of `PlainDS` is just a plain caching of neighbouring vertices for each vertex which are stored in `CacheDS` also with the list of faces. 
# ```@docs
# CachedDS
# CachedDS(::SurfaceTopology.PlainDS)
# ```
# which can be initialised from `PlainDS`
cachedtopology = CachedDS(faces)
# And the same API can be used for querries:
collect(VertexRing(3,cachedtopology))

# A more advanced data structure is a face based data structure `FaceDS` which additionally for each face stores three neighbouring face indices. 
# ```@docs
# FaceDS
# FaceDS(::SurfaceTopology.PlainDS)
# ```
# which again can be initialised from `PlainDS`
facedstopology = FaceDS(faces)
# and what would one expect
collect(VertexRing(3,facedstopology))
# works.

# All previous ones were some forms of face-based data structures. More common (by my own impression) the numerical world uses edge-based data structures. This package implements half-edge data structure `EdgeDS` which stores a list of edges by three numbers - base vertex index, next edge index and twin edge index.
# ```@docs
# EdgeDS
# ```
# To initialise this datastructure one executes:
edgedstopology = EdgeDS(faces)
# 
collect(VertexRing(3,edgedstopology))

# ## Wishlist

# At the moment the package is able only to answer queries, but it would be desirable also to be able to do topological surgery operations. For completeness, those would include.

#   + `edgeflip(topology,edge)`
#   + `edgesplit(topology,edge)`
#   + `edgecollapse(topology,edge)`

# And with them even a method for `defragmenting` the topology (actually trivial if we generalize constructors as in `CachedDS`). Unfortunately, at the moment, I am not working with anything geometry related thus the development of that on my own will be slow. I hope that the clarity and simplicity of this package could serve someone as a first step, and so eventually, topological operations would be implemented out of necessity.
