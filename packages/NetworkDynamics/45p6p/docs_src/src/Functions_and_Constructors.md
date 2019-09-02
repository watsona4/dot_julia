# Functions

The Dynamics for the whole Network is constructed from functions for the single vertices and edges. There are several types:

```@docs
ODEVertex(vertexfunction!, dimension, mass_matrix, sym)
StaticEdge(edgefunction!, dimension)
ODEEdge(edgefunction!, dimension, mass_matrix, sym)
```


### ODEVertex

The arguments mean the following: **vertexfunction!** is catching the dynamics of a single vertex depending on the vertex value itself as well as in- and outgoing currents (or edges). An example for such a function would be:

```julia
function vertexfunction!(dv, v, e_s, e_d, p, t)
  dv .= 0
  for e in e_s
    dv .-= e
  end
  for e in e_d
    dv .+= e
  end
end
```

The e_s and e_d are arrays containing the edges that have the decribed vertex as source and destination. Other arguments coincide with the usual ODE function arguments. The vertexfunction given to ODEVertex always needs to have the shown argument structure. Note the importance of the broadcast structure of the equations (the dot before every operator), this is necessary due to the use of views in the internal functions, it further provides a boost to the performance of the solver.

**dimension** is the number of Variables on the Vertex.

**mass_matrix** is the mass matrix M, i.e.

```@docs
M*dv = vertexfunction!
```

sym are the symbols of the Vertex. If one had for example a vertex with a frequency and some angle, one would construct sym via:

```@docs
sym = [:omega, :phi]
```

This makes it easier to later fish out the interesting variables one wants to look at.

One may also call ODEVertex via:

```@docs
ODEVertex(vertexfunction!, dimension)
```

The function then defaults to using the identity as mass matrix and [:v for i in 1:dimension] as symbols.


### StaticEdge

Static here means, that the edge value described by **edgefunction!** solely depends on the vertex values the edge connects. One very simple and natural example is a diffusive system:

```@julia
edgefunction! = (e, v_s, v_d, p, t) -> e .= v_s .- v_d
```

v_s and v_d are the vertex values of the edges source and destination. There is no derivative of the edge value involved, hence we call these problems static.

**dimension**: see ODEVertex

### ODEEdge

For Problems where **edgefunction** also contains the differential of an edge value , we use the ODEEdge function. Another simple and natural example for such a system is one that quickly diffuses to the static case:

```@julia
edgefunction! = (de, e, v_s, v_d, p, t) -> de .= 1000 * (v_s .- v_d .- e)
```

**dimension**: see ODEVertex

**mass_matrix**: see ODEVertex

**sym**: see ODEVertex

Also, one can construct an ODEEdge by only giving the first two arguments:

```@docs
ODEEdge(edgefunction!, dimension)
```

Then the function defaults to using the identity as mass matrix as well as using [:e for in 1:dimension] as sym.




## Constructor

The central constructor of this package is network_dynamics(), this function demands an array of VertexFunction and EdgeFunction as well as a graph (see LightGraphs), and returns an ODEFunction which one can easily solve via the tools given in DifferentialEquations.jl. One calls it via:

```@docs
network_dynamics(Array{VertexFunction}, Array{EdgeFunction}, graph)
```

VertexFunction and EdgeFunction are the Unions of all the Vertex and Edge Functions we specified in the previous section. Let's look at an example. First we define our graph as well as the differential systems connected to its vertices and edges:

```julia

using LightGraphs

g = barabasi_albert(10,5) # The graph is a random graph with 10 vertices and 25 Edges.

function vertexfunction!(dv, v, e_s, e_d, p, t)
  dv .= 0
  for e in e_s
    dv .-= e
  end
  for e in e_d
    dv .+= e
  end
end

function edgefunction! = (de, e, v_s, v_d, p, t) -> de .= 1000 .*(v_s .- v_d .- e)

vertex = ODEVertex(vertexfunction!, 1)
vertexarr = [vertex for v in vertices(g)]

edge = ODEEdge(edgefunction!, 1)
edgearr = [edge for e in edges(g)]

nd = network_dynamics(vertexarr, edgearr, g)
```

Now we have an ODEFunction nd that we can solve with well-known tools from DifferentialEquations. To solve the defined system,
we further need an array with initial values x0 as well as a time span tspan in which we solve the problem:

```julia

using DifferentialEquations

x0 = rand(10 + 25) #10 for the vertices and 25 for the edges
tspan = (0.,2.)

prob = ODEProblem(nd,x0,tspan)
sol = solve(prob)

using Plots
plot(sol, legend = false, vars = 1:10) # vars gives us x[1:10] in the plot
```

The Plot shows the classic diffusive behaviour.

### Mass Matrix

One thing one has to know when working with **mass matrices** is best described via an example, let's consider
the same problem as before with solely changed edge and vertex:

```julia
vertex = ODEVertex(vertexfunction!, 2, [2 1; -1 1], nothing)
edge = ODEEdge(edgefunction!, 2)
```

We now have two dimensional vertex and edge variables, we additionally added a mass matrix for every vertex. The Constructor builds one
big mass matrix from all the given ones. If one now wants to solve the problem, one has to specify the solving algorithm for the solver as the
default solver can't handle mass matrices. The DAE solvers are fit for these kind of problems. One has to be especially aware of putting the variable autodiff inside the algorithm to false, hence one has to write the solver like this:

```julia
sol = solve(prob, Rodas4(autodiff = false)) # Rodas4 is just an exemplary DAE solving algorithm, there are many more.#
```

With that, everything works just fine. One has to put autodiff to false, because the structure of the lastly given equations is not of the standard form that the DAE solvers can handle just like that.
