var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "General",
    "title": "General",
    "category": "page",
    "text": ""
},

{
    "location": "#NetworkDynamics-1",
    "page": "General",
    "title": "NetworkDynamics",
    "category": "section",
    "text": ""
},

{
    "location": "#Overview-1",
    "page": "General",
    "title": "Overview",
    "category": "section",
    "text": "This package implements functions for defining and studying dynamics on networks. The key construction is a callable function compatible with the DifferentialEquations.jl calling syntax.nd = network_dynamics(vertices!::Array{VertexFunction}, edges!::Array{EdgeFunction}, g)\r\nnd(dx, x, p, t)The first two parameters are the functions, or function arrays from which a network dynamics is built. The types VertexFunction and EdgeFunction are specified on the next page. The last parameter g is a graph encoding the network constructed with the LightGraphs.jl package.This page is still in development. :)"
},

{
    "location": "Functions_and_Constructors/#",
    "page": "Functions",
    "title": "Functions",
    "category": "page",
    "text": ""
},

{
    "location": "Functions_and_Constructors/#Functions-1",
    "page": "Functions",
    "title": "Functions",
    "category": "section",
    "text": "The Dynamics for the whole Network is constructed from functions for the single vertices and edges. There are several types:ODEVertex(vertexfunction!, dimension, mass_matrix, sym)\r\nStaticEdge(edgefunction!, dimension)\r\nODEEdge(edgefunction!, dimension, mass_matrix, sym)"
},

{
    "location": "Functions_and_Constructors/#ODEVertex-1",
    "page": "Functions",
    "title": "ODEVertex",
    "category": "section",
    "text": "The arguments mean the following: vertexfunction! is catching the dynamics of a single vertex depending on the vertex value itself as well as in- and outgoing currents (or edges). An example for such a function would be:function vertexfunction!(dv, v, e_s, e_d, p, t)\r\n  dv .= 0\r\n  for e in e_s\r\n    dv .-= e\r\n  end\r\n  for e in e_d\r\n    dv .+= e\r\n  end\r\nendThe es and ed are arrays containing the edges that have the decribed vertex as source and destination. Other arguments coincide with the usual ODE function arguments. The vertexfunction given to ODEVertex always needs to have the shown argument structure. Note the importance of the broadcast structure of the equations (the dot before every operator), this is necessary due to the use of views in the internal functions, it further provides a boost to the performance of the solver.dimension is the number of Variables on the Vertex.mass_matrix is the mass matrix M, i.e.M*dv = vertexfunction!sym are the symbols of the Vertex. If one had for example a vertex with a frequency and some angle, one would construct sym via:sym = [:omega, :phi]This makes it easier to later fish out the interesting variables one wants to look at.One may also call ODEVertex via:ODEVertex(vertexfunction!, dimension)The function then defaults to using the identity as mass matrix and [:v for i in 1:dimension] as symbols."
},

{
    "location": "Functions_and_Constructors/#StaticEdge-1",
    "page": "Functions",
    "title": "StaticEdge",
    "category": "section",
    "text": "Static here means, that the edge value described by edgefunction! solely depends on the vertex values the edge connects. One very simple and natural example is a diffusive system:edgefunction! = (e, v_s, v_d, p, t) -> e .= v_s .- v_dvs and vd are the vertex values of the edges source and destination. There is no derivative of the edge value involved, hence we call these problems static.dimension: see ODEVertex"
},

{
    "location": "Functions_and_Constructors/#ODEEdge-1",
    "page": "Functions",
    "title": "ODEEdge",
    "category": "section",
    "text": "For Problems where edgefunction also contains the differential of an edge value , we use the ODEEdge function. Another simple and natural example for such a system is one that quickly diffuses to the static case:edgefunction! = (de, e, v_s, v_d, p, t) -> de .= 1000 * (v_s .- v_d .- e)dimension: see ODEVertexmass_matrix: see ODEVertexsym: see ODEVertexAlso, one can construct an ODEEdge by only giving the first two arguments:ODEEdge(edgefunction!, dimension)Then the function defaults to using the identity as mass matrix as well as using [:e for in 1:dimension] as sym."
},

{
    "location": "Functions_and_Constructors/#Constructor-1",
    "page": "Functions",
    "title": "Constructor",
    "category": "section",
    "text": "The central constructor of this package is network_dynamics(), this function demands an array of VertexFunction and EdgeFunction as well as a graph (see LightGraphs), and returns an ODEFunction which one can easily solve via the tools given in DifferentialEquations.jl. One calls it via:network_dynamics(Array{VertexFunction}, Array{EdgeFunction}, graph)VertexFunction and EdgeFunction are the Unions of all the Vertex and Edge Functions we specified in the previous section. Let\'s look at an example. First we define our graph as well as the differential systems connected to its vertices and edges:\r\nusing LightGraphs\r\n\r\ng = barabasi_albert(10,5) # The graph is a random graph with 10 vertices and 25 Edges.\r\n\r\nfunction vertexfunction!(dv, v, e_s, e_d, p, t)\r\n  dv .= 0\r\n  for e in e_s\r\n    dv .-= e\r\n  end\r\n  for e in e_d\r\n    dv .+= e\r\n  end\r\nend\r\n\r\nfunction edgefunction! = (de, e, v_s, v_d, p, t) -> de .= 1000 .*(v_s .- v_d .- e)\r\n\r\nvertex = ODEVertex(vertexfunction!, 1)\r\nvertexarr = [vertex for v in vertices(g)]\r\n\r\nedge = ODEEdge(edgefunction!, 1)\r\nedgearr = [edge for e in edges(g)]\r\n\r\nnd = network_dynamics(vertexarr, edgearr, g)Now we have an ODEFunction nd that we can solve with well-known tools from DifferentialEquations. To solve the defined system, we further need an array with initial values x0 as well as a time span tspan in which we solve the problem:\r\nusing DifferentialEquations\r\n\r\nx0 = rand(10 + 25) #10 for the vertices and 25 for the edges\r\ntspan = (0.,2.)\r\n\r\nprob = ODEProblem(nd,x0,tspan)\r\nsol = solve(prob)\r\n\r\nusing Plots\r\nplot(sol, legend = false, vars = 1:10) # vars gives us x[1:10] in the plotThe Plot shows the classic diffusive behaviour."
},

{
    "location": "Functions_and_Constructors/#Mass-Matrix-1",
    "page": "Functions",
    "title": "Mass Matrix",
    "category": "section",
    "text": "One thing one has to know when working with mass matrices is best described via an example, let\'s consider the same problem as before with solely changed edge and vertex:vertex = ODEVertex(vertexfunction!, 2, [2 1; -1 1], nothing)\r\nedge = ODEEdge(edgefunction!, 2)We now have two dimensional vertex and edge variables, we additionally added a mass matrix for every vertex. The Constructor builds one big mass matrix from all the given ones. If one now wants to solve the problem, one has to specify the solving algorithm for the solver as the default solver can\'t handle mass matrices. The DAE solvers are fit for these kind of problems. One has to be especially aware of putting the variable autodiff inside the algorithm to false, hence one has to write the solver like this:sol = solve(prob, Rodas4(autodiff = false)) # Rodas4 is just an exemplary DAE solving algorithm, there are many more.#With that, everything works just fine. One has to put autodiff to false, because the structure of the lastly given equations is not of the standard form that the DAE solvers can handle just like that."
},

{
    "location": "StaticEdges/#",
    "page": "Static edges",
    "title": "Static edges",
    "category": "page",
    "text": ""
},

{
    "location": "StaticEdges/#Static-edges-1",
    "page": "Static edges",
    "title": "Static edges",
    "category": "section",
    "text": ""
},

{
    "location": "StaticEdges/#Scalar-variables-1",
    "page": "Static edges",
    "title": "Scalar variables",
    "category": "section",
    "text": "We will first look into the case where there is only a scalar variable on each vertex. A dynamical network with static edges (static meaning that the current on an edge depends solely on the values on the vertices it connects) is created via the ndODEStatic_scalar function:ssl = nd_ODE_Static_scalar(vertices!, edges!, g)The functions vertices! and edges! are of the form:vertices![n](dv[n],v[n],e_s[n],e_t[n],p,t)\r\nedges![m](e[m],v_s,v_t,p,t)  Specifically, the given variables are:e_s[n] = [e[m] if s[m] == n for m in 1:length(edges!)]\r\ne_t[n] = [e[m] if t[m] == n for m in 1:length(edges!)]\r\nv_s= v[s[m]]\r\nv_t= v[t[m]]The vectors s and t contain the information about the source and target of each edge, i.e. s[1] == 2 -> The source of edge 1 is vertex 2. The function creates these vectors from the given graph, they can be accessed via the calling syntax ssl.se or ssl.te. The vectors es[n] and et[n] are containing the in- and outgoing edge values (or currents) of vertex n in the form of an array. Thus, one would classically sum over these in vertices!, but one is not restricted on doing this.For example, a system of equations describing a simple diffusive network would be:using LightGraphs\r\ng= barabasi_albert(10,5)\r\nvertices! = [(dv,v,l_s,l_t,p,t) -> dv .= sum(e_s) .- sum(e_t) for vertex in vertices(g)]\r\nedges! = [(e,v_s,v_t,p,t) -> e .= v_s .- v_t for edge in edges(g)]Here, the diffusiveness lies within the edges! function. It states that there is only a current between two vertices if these vertices have a non-equal value. This current then ultimatively leads to an equilibrium in which the value on any connected vertex is equal.Note that one should (for performance reasons) and actually needs to put a dot before the mathematical operators. This is due to the use of views in the internals of the ndODEStatic_scalar function.We finally want to solve the defined diffusive system. This we do by using the well-known package DifferentialEquations.jl (see here). We also need to specify a set of initial values x0 as well as a time interval t for which we are solving the problem:using DifferentialEquations\r\nusing Plots\r\nx0 = rand(10)\r\nt = (0.,2.)\r\nssl = nd_ODE_Static_scalar(vertices!,edges!,g)\r\nssl_prob = ODEProblem(ssl,x0,t)\r\nsol = solve(ssl_prob)\r\nplot(sol, legend = false)(Image: )As one would expect in a diffusive network, the values on the vertices converge."
},

{
    "location": "DynamicEdges/#",
    "page": "Dynamic edges",
    "title": "Dynamic edges",
    "category": "page",
    "text": ""
},

{
    "location": "DynamicEdges/#Dynamic-edges-1",
    "page": "Dynamic edges",
    "title": "Dynamic edges",
    "category": "section",
    "text": ""
},

{
    "location": "DynamicEdges/#Scalar-variables-1",
    "page": "Dynamic edges",
    "title": "Scalar variables",
    "category": "section",
    "text": "In general, currents do not solely depend on the vertex values they are connecting, but rather depend on its own value in some sort. For the case of scalar variables, we may use the function ndODEODE_scalar:sdl = nd_ODE_ODE_scalar(vertices!,edges!,g)The function arguments are now of the following form:vertices![n](dv[n],v[n],e_s[n],e_t[n],p,t)\r\nedges![m](de[m],e[m],v_s,v_t,p,t)Compared to the static edges case with scalar variables, the vertices! function keeps its structure whereas the edges! function gets the new argument de[m]. This de[m] is the derivative of the edge value of edge m. Let\'s look at a simple example: A system with dynamic edges which decay to the usual diffusive system:vertices! = [(dv,v,l_s,l_t,p,t) -> dv .= sum(e_s) .- sum(e_t) for vertex in vertices(g)]\r\nedges! = [(de,e,v_s,v_t,p,t) -> de .= 1000*(v_s .- v_t .- e) for edge in edges(g)]The change compared to the example for the static case should be clear; the factor of 1000 is just accelerating the decay. Again, we can quite simply solve this system. One has to be aware though that now one needs initial values for the vertices and the edges! These are given in the order x0 = [vertex1,vertex2,...,edge1,edge2,...]:g = barabasi_albert(10,5) #generates a graph with 10 vertices and 25 edges\r\nx0 = rand(10 + 25)\r\nt = (0.,2.)\r\nsdl = nd_ODE_ODE_scalar(vertices!,edges!,g)\r\nsdl_prob = ODEProblem(sdl,x0,t)\r\nsol = solve(sdl_prob)\r\nplot(sol, legend = false , vars = 1:10)(Hier sollte ein Bild sein)We see that the plot looks pretty much the same as for the static edges case. That is, because we included the factor of 1000 in the edges! function. Note that we added the argument vars to the plot function, this gives us solely the first 10 arguments of x which are the vertices. One could also get just the edge values by writing vars = 11:35 if one wishes."
},

{
    "location": "DynamicEdges/#Vector-variables-1",
    "page": "Dynamic edges",
    "title": "Vector variables",
    "category": "section",
    "text": "The step here is not a hard one, if one read through the previous Vector variables section. We can treat a system of vector variables with dynamic edges with the function dynamic_edges:dl = dynamic_edges(vertices!,edges!,g,dim_v,dim_e)One has to apply the same change to the vertices! function as for the static_edges function. Otherwise, everything should be clear. For the example, we take the decaying dynamic edges and just make two independent networks as for the Static edges:dim_v = 2 * ones(Int32, length(vertices!))\r\ndim_e = 2 * ones(Int32, length(edges!))\r\ng = barabasi_albert(10,5)\r\n\r\nfunction vertex!(dv, v, e_s, e_d, p, t)\r\n    dv .= 0\r\n    for e in e_s\r\n        dv .-= e\r\n    end\r\n    for e in e_d\r\n        dv .+= e\r\n    end\r\n    nothing\r\nend\r\n\r\nvertices! = [vertex! for vertex in vertices(g)]\r\nedges! = [(de,e,v_s,v_t,p,t) -> de .= 1000*(v_s .- v_t .- e) for edge in edges(g)]\r\n\r\ndl = dynamic_edges(vertices!,edges!,g,dim_v,dim_e)\r\n\r\nx0 = rand(10 + 10 + 25 + 25)\r\nt= (0.,2.)\r\ndl_prob = ODEProblem(dl,x0,t)\r\nsol= solve(dl_prob)\r\nplot(sol, legend = false, vars = 1:20)(Bild)We get the same pattern as for the scalar case, just twice."
},

]}
