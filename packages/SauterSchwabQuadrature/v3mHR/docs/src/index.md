# SauterSchwabQuadrature.jl


This package can be used to solve problems of following type:

```math
\int_{\Gamma}\int_{\Gamma'}b_i(\textbf{x})\,k(\textbf{x},\textbf{y})\, b_j(\textbf{y})\;da_\textbf{y}\,da_\textbf{x}
```.

The above expression is a double area-integral over two triangles (curved or flat) ``\Gamma`` and ``\Gamma'`` in 3D Space. The integrand consists of two basisfunctions, ``b_i(\textbf{x})`` and ``b_i(\textbf{y})``, and the kernel ``k(\textbf{x},\textbf{y})``.   

This kind of integral occures in the area of Boundary Element Methods for solving elliptic partial differential equations. It can be interpreted as the interaction of the two basisfunctions, with respect to their triangles. For this reason in this package, ``\Gamma`` is called the testtriangle and ``\Gamma'`` the sourcetriangle, and the same goes for the two basisfunctions as well; they are called test- and sourcefunction. The triangles correspond to the cells of a meshed surface.

As the solving algorithm works for a wide range of basisfunctions and kernels, all the requirements for the kernel, basisfunctions and the integration areas will be given:

1.Requirements for the triangles:
* The triangles must be either equal, have two vertices in common, have one vertex in common or do not touch at all. A partial overlap is forbidden.

2.Requirements for the basisfunctions:
* The basisfunctions must be real and non-singular on their respective triangles.
* The basisfunctions map vectors on scalars.

3.The kernel must be Cauchy singular.

Depending on the input data, this package contains two different implementations of the integral. The first one is very convenient to handle and does not need a parameterization, but it works only for flat triangles Additionally, the user has to be familiar with the functions `simplex()` and `point()` of the package CompScienceMeshes. For more information about CompScienceMeshes and its functions the user should visit its GitHub page (https://github.com/krcools/CompScienceMeshes.jl) and its documentation (https://krcools.github.io/CompScienceMeshes.jl/latest/). The second implementation only contains the integration rules; so the user has to build the parameterization by himself, but therefore it also works for curved triangles.

The first implementation is called by a function, which looks like:  

`function(sourcechart, testchart, integrand, information)`.

`sourcechart` and `testchart` are the mappings from a reference triangle onto the real triangles in space. `integrand` is the original integrand, and the last argument contains information about how accurate the integration shall be done and the type of integration.

The second implementation is called by a function, which looks like:

`function(integrand, information)`.

`integrand` is the parameterized version of the original integrand. The last argument contains information about how accurate the integration shall be done and the type of integration.

On the pages 'Non-Parameterized' and 'Parameterized', the user will find more information about the two implementations and how to operate these.

As soon as this package is added to a local machine, CompScinceMeshes will be added as well.  

This documentation does not derive the integration rules and how the integration is done; it only shows how to handle this package. If the user wants to know more about how this package operates, he has to go inside the src folder and look up for the book quoted in the README file.
