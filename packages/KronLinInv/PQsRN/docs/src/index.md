

# Manual outline

```@contents
Pages = ["index.md","publicapi.md"]
Depth = 2
``` 

# User guide

This document describes the Julia version of the code KronLinInv.
 
Kronecker-product-based linear inversion of geophysical (or other kinds of) data under Gaussian and separability assumptions. The code computes the posterior mean model and the posterior covariance matrix (or subsets of it) in an efficient manner (parallel algorithm) taking into account 3-D correlations both in the model parameters and in the observed data.
 
If you use this code for research or else, please cite the related paper: 

Andrea Zunino, Klaus Mosegaard (2018), **An efficient method to solve large linearizable inverse problems under Gaussian and separability assumptions**, *Computers & Geosciences*. ISSN 0098-3004, <https://doi.org/10.1016/j.cageo.2018.09.005>.

See the above mentioned paper for a detailed description.

# Theoretical background

KronLinInv solves the *linear inverse problem* with Gaussian uncertainties
represented by the following objective function
```math
S( \mathbf{m}) = \frac{1}{2} ( \mathbf{G} \mathbf{m} - \mathbf{d}_{\sf{obs}} )^{\sf{T}} \mathbf{C}^{-1}_{\rm{D}} ( \mathbf{G} \mathbf{m} - \mathbf{d}_{\sf{obs}} ) + \frac{1}{2} ( \mathbf{m} - \mathbf{m}_{\sf{prior}} )^{\sf{T}} \mathbf{C}^{-1}_{\rm{M}} ( \mathbf{m} - \mathbf{m}_{\sf{prior}} )
```
under the following separability conditions (for a 3-way decomposition):
```math
\mathbf{C}_{\rm{M}} = \mathbf{C}_{\rm{M}}^{\rm{x}} \otimes 
\mathbf{C}_{\rm{M}}^{\rm{y}} \otimes \mathbf{C}_{\rm{M}}^{\rm{z}} 
, \quad
\mathbf{C}_{\rm{D}} = \mathbf{C}_{\rm{D}}^{\rm{x}} \otimes 
\mathbf{C}_{\rm{D}}^{\rm{y}} \otimes \mathbf{C}_{\rm{D}}^{\rm{z}} 

\quad \textrm{ and } \quad

\mathbf{G} = \mathbf{G}^{\rm{x}} \otimes \mathbf{G}^{\rm{y}} \otimes \mathbf{G}^{\rm{z}} \, .
```

From the above, the posterior covariance matrix is given by 
```math 
 \mathbf{\widetilde{C}}_{\rm{M}} =  \left( \mathbf{G}^{\sf{T}} \,
\mathbf{C}^{-1}_{\rm{D}} \, \mathbf{G} + \mathbf{C}^{-1}_{\rm{M}} \right)^{-1}
```
  and the center of posterior gaussian is 
```math
 \mathbf{\widetilde{m}}  
 = \mathbf{m}_{\rm{prior}}+ \mathbf{\widetilde{C}}_{\rm{M}} \, \mathbf{G}^{\sf{T}} \, \mathbf{C}^{-1}_{\rm{D}} \left(\mathbf{d}_{\rm{obs}} - \mathbf{G} \mathbf{m}_{\rm{prior}} \right) \, .
```
KronLinInv solves the inverse problem in an efficient manner, with a very low memory imprint, suitable for large problems where many model parameters and observations are involved.

The paper describes how to obtain the solution to the above problem as shown hereafter. First the following matrices are computed

```math
 \mathbf{U}_1 \mathbf{\Lambda}_1  \mathbf{U}_1^{-1}  
 = \mathbf{C}_{\rm{M}}^{\rm{x}} (\mathbf{G}^{\rm{x}})^{\sf{T}}
(\mathbf{C}_{\rm{D}}^{\rm{x}})^{-1} \mathbf{G}^{\rm{x}}
```

```math
\mathbf{U}_2 \mathbf{\Lambda}_2  \mathbf{U}_2^{-1}
=  \mathbf{C}_{\rm{M}}^{\rm{y}} (\mathbf{G}^{\rm{y}})^{\sf{T}}
(\mathbf{C}_{\rm{D}}^{\rm{y}})^{-1} \mathbf{G}^{\rm{y}}
```

```math
\mathbf{U}_3 \mathbf{\Lambda}_3  \mathbf{U}_3^{-1}
= \mathbf{C}_{\rm{M}}^{\rm{z}} (\mathbf{G}^{\rm{z}})^{\sf{T}}
(\mathbf{C}_{\rm{D}}^{\rm{z}})^{-1} \mathbf{G}^{\rm{z}}  \, .
```

The posterior covariance is then expressed as

```math 
\mathbf{\widetilde{C}}_{\rm{M}} = 
\left(  
\mathbf{U}_1 \otimes \mathbf{U}_2 \otimes \mathbf{U}_3 
\right)
 \big( 
\mathbf{I} + \mathbf{\Lambda}_1 \! \otimes \! \mathbf{\Lambda}_2 \! \otimes \! \mathbf{\Lambda}_3 
\big)^{-1} 
\big( 
\mathbf{U}_1^{-1}  \mathbf{C}_{\rm{M}}^{\rm{x}} \otimes 
\mathbf{U}_2^{-1} \mathbf{C}_{\rm{M}}^{\rm{y}} \otimes 
\mathbf{U}_3^{-1} \mathbf{C}_{\rm{M}}^{\rm{z}} 
\big) \, .
```
and the posterior mean model as
```math 
\mathbf{\widetilde{m}} =  
 \mathbf{m}_{\rm{prior}} +  
 \Big[ \!
 \left(  
\mathbf{U}_1 \otimes \mathbf{U}_2 \otimes \mathbf{U}_3 
\right)
 \big( 
\mathbf{I} + \mathbf{\Lambda}_1\!  \otimes \! \mathbf{\Lambda}_2 \!  \otimes\!  \mathbf{\Lambda}_3 
\big)^{-1} \\ 
\times \Big( 
\left( \mathbf{U}_1^{-1}  \mathbf{C}_{\rm{M}}^{\rm{x}} (\mathbf{G}^{\rm{x}})^{\sf{T}} (\mathbf{C}_{\rm{D}}^{\rm{x}})^{-1} \right) \!    \otimes 
\left( \mathbf{U}_2^{-1} \mathbf{C}_{\rm{M}}^{\rm{y}}  (\mathbf{G}^{\rm{y}})^{\sf{T}} (\mathbf{C}_{\rm{D}}^{\rm{y}})^{-1}  \right)   \!   
\\ 
\otimes  \left( \mathbf{U}_3^{-1} \mathbf{C}_{\rm{M}}^{\rm{z}} (\mathbf{G}^{\rm{z}})^{\sf{T}} (\mathbf{C}_{\rm{D}}^{\rm{z}})^{-1} \right)
\Big)
\Big] \\
\times \Big( \mathbf{d}_{\rm{obs}} - \big( \mathbf{G}^{\rm{x}} \otimes \mathbf{G}^{\rm{y}} \otimes \mathbf{G}^{\rm{z}} \big) \, \mathbf{m}_{\rm{prior}} \Big) \, .
```
These last two formulae are those used by the KronLinInv algorithm.

Several function are exported by the module KronLinInv:

- [`calcfactors()`](@ref): Computes the factors necessary to solve the inverse problem

- [`posteriormean()`](@ref): Computes the posterior mean model using the previously computed "factors" with [`calcfactors()`](@ref).

- [`blockpostcov()`](@ref): Computes a block (or all) of the posterior covariance using the previously computed "factors" with [`calcfactors()`](@ref).

- [`bandpostcov()`](@ref): NOT YET IMPLEMENTED! Computes a band of the posterior covariance the previously computed "factors" with [`calcfactors()`](@ref).



# Usage examples

The input needed is represented by the set of three covariance matrices of the model parameters, the three covariances of the observed data, the three forward model operators, the observed data (a vector) and the prior model (a vector).
_The **first** thing to compute is always the set of "factors" using the function [`calcfactors()`](@ref). 
Finally, the posterior mean (see [`posteriormean()`](@ref)) and/or covariance (or part of it) can be computed (see [`blockpostcov()`](@ref)).

- [2D example](@ref twodexample)
- [3D example](@ref threedexample)


## [2D example](@id twodexample)

An example of how to use the code for 2D problems is shown in the following. Notice that the code is written for a 3D problem, however, by setting some of the matrices as identity matrices with size of 1``\times``1, a 2D problem can be solved without much overhead.

### Creating a test problem
First, we create some input data to simulate a real problem. 
```@example twodex
# set the sizes of the problem
nx = 1
ny = 20
nz = 30
nxobs = 1
nyobs = 18
nzobs = 24

nothing # hide
```

We then construct some covariance matrices and a forward operator. The "first" covariance matrices for model parameters (``\mathbf{C}_{\rm{M}}^{\rm{x}} \, , 
\mathbf{C}_{\rm{M}}^{\rm{y}} \, , \mathbf{C}_{\rm{M}}^{\rm{z}}``) and observed data (``\mathbf{C}_{\rm{D}}^{\rm{x}} \, , \mathbf{C}_{\rm{D}}^{\rm{y}} \, , \mathbf{C}_{\rm{D}}^{\rm{z}}``) are simply an identity matrix of shape 1``\times``1, since it is a 2D problem.
The forward relation (forward model) is created from three operators (``\mathbf{G}^{\rm{x}} \, , \mathbf{G}^{\rm{y}} \, , \mathbf{G}^{\rm{z}}``). Remark: the function `mkCovSTAT` used in the following example is *not* part of KronLinInv.

```@example twodex
function mkCovSTAT(sigma::Array{Float64,1},nx::Integer,ny::Integer,nz::Integer,
                   corrlength::Array{Float64,1},kind::String) 
    function cgaussian(dist,corrlength)
        if maximum(dist)==0.0
            return 1.0
        else
            @assert(corrlength>0.0)
            return exp.(-(dist./corrlength).^2)
        end
    end
    function cexponential(dist,corrlength)
        if maximum(dist)==0.0
            return 1.0
        else
            @assert(corrlength>0.0)
            return exp.(-(dist./corrlength))
        end
    end
    
    npts = nx*ny*nz
    x = [float(i) for i=1:nx]
    y = [float(i) for i=1:ny]
    z = [float(i) for i=1:nz]
    covmat_x = zeros(nx,nx)
    covmat_y = zeros(ny,ny)
    covmat_z = zeros(nz,nz)

    if kind=="gaussian" 
        calccovfun = cgaussian
    elseif kind=="exponential" 
        calccovfun = cexponential
    else 
        println("Error, no or wrong cov 'kind' specified")
        exit()
    end

    for i=1:nx
        covmat_x[i,:] .= sigma[1]^2 .* 
            calccovfun(sqrt.((x.-x[i]).^2),corrlength[1])
    end
    for i=1:ny
        covmat_y[i,:] .= sigma[2]^2 .* 
            calccovfun(sqrt.(((y.-y[i])).^2),corrlength[2])
    end
    for i=1:nz
        covmat_z[i,:] .= sigma[3]^2 .* 
            calccovfun(sqrt.(((z.-z[i])).^2),corrlength[3])
    end
    
    return covmat_x,covmat_y,covmat_z
 end
 nothing # hide
```

```@example twodex
# standard deviations
sigmaobs  = [1.0, 0.1, 0.1] # notice the 1.0 as first element (2D problem)
sigmam    = [1.0, 0.8, 0.8] # notice the 1.0 as first element (2D problem)
# correlation lengths
corlenobs = [0.0, 1.4, 1.4] # notice the 0.0 as first element (2D problem)
corlenm   = [0.0, 2.5, 2.5] # notice the 0.0 as first element (2D problem)
# create the covariance matrices on observed data
Cd1,Cd2,Cd3 = mkCovSTAT(sigmaobs,nxobs,nyobs,nzobs,corlenobs,"gaussian")
# create the covariance matrices on model parameters
Cm1,Cm2,Cm3 = mkCovSTAT(sigmam,nx,ny,nz,corlenm,"gaussian") 

# forward model operator
G1 = rand(nxobs,nx) # notice that nx=1 and nxobs=1 (2D problem)
G2 = rand(nyobs,ny)
G3 = rand(nzobs,nz)

nothing # hide
```

Finally, a "true/reference" model, in order to compute some synthetic "observed" data and a prior model.

```@example twodex
# create a reference model
refmod = rand(nx*ny*nz)

# create a prior model
mprior = copy(refmod) .+ 0.3*randn(length(refmod)) 

# create some "observed" data
dobs = kron(G1,kron(G2,G3)) * refmod 
# add some noise to make it more realistic
dobs = dobs .+ 0.02.*randn(length(dobs)) 

#nothing # hide
```
Now we have create a synthetic example to play with, which we can solve as shown in the following.


### Solving the 2D problem
In order to solve the inverse problem using KronLinInv, we first need to compute the "factors" using the function [`calcfactors()`](@ref), which takes as inputs two `struct`s containing the covariance matrices and the forward operators.
```@example twodex
using KronLinInv

# create the covariance matrix structure
Covs = CovMats(Cd1,Cd2,Cd3,Cm1,Cm2,Cm3)

# forward model operator
Gfwd = FwdOps(G1,G2,G3)

# calculate the required factors
klifac = calcfactors(Gfwd,Covs)

nothing # hide
```

Now the inverse problem can be solved. We first compute the posterior mean and then a subset of the posterior covariance.
 
```@example twodex
# calculate the posterior mean model
postm = posteriormean(klifac,Gfwd,mprior,dobs)

# calculate the posterior covariance
npts = nx*ny*nz
astart, aend = 1,div(npts,3) # set of rows to be computed
bstart, bend = 1,div(npts,3) # set of columns to be computed

# compute the block of posterior covariance
postC = blockpostcov(klifac,astart,aend,bstart,bend)

nothing # hide
```


## [3D example](@id threedexample)


An example of how to use the code for 3D problems is shown in the following. It follows closely the 3D example.

### Creating a test problem
First, we create some input data to simulate a real problem. 
```@example threedex
# set the sizes of the problem
nx = 7
ny = 9
nz = 7
nxobs = 6
nyobs = 8
nzobs = 9

nothing # hide
```

We then construct some covariance matrices for model parameters (``\mathbf{C}_{\rm{M}}^{\rm{x}} \, , 
\mathbf{C}_{\rm{M}}^{\rm{y}} \, , \mathbf{C}_{\rm{M}}^{\rm{z}}``) and observed data (``\mathbf{C}_{\rm{D}}^{\rm{x}} \, , \mathbf{C}_{\rm{D}}^{\rm{y}} \, , \mathbf{C}_{\rm{D}}^{\rm{z}}``). The forward relation (forward model) is created from three operators (``\mathbf{G}^{\rm{x}} \, , \mathbf{G}^{\rm{y}} \, , \mathbf{G}^{\rm{z}}``). Remark: the function `mkCovSTAT` used in the following example is *not* part of KronLinInv.

```@example threedex
function mkCovSTAT(sigma::Array{Float64,1},nx::Integer,ny::Integer,nz::Integer,
                   corrlength::Array{Float64,1},kind::String) 
    function cgaussian(dist,corrlength)
        if maximum(dist)==0.0
            return 1.0
        else
            @assert(corrlength>0.0)
            return exp.(-(dist./corrlength).^2)
        end
    end
    function cexponential(dist,corrlength)
        if maximum(dist)==0.0
            return 1.0
        else
            @assert(corrlength>0.0)
            return exp.(-(dist./corrlength))
        end
    end
    
    npts = nx*ny*nz
    x = [float(i) for i=1:nx]
    y = [float(i) for i=1:ny]
    z = [float(i) for i=1:nz]
    covmat_x = zeros(nx,nx)
    covmat_y = zeros(ny,ny)
    covmat_z = zeros(nz,nz)

    if kind=="gaussian" 
        calccovfun = cgaussian
    elseif kind=="exponential" 
        calccovfun = cexponential
    else 
        println("Error, no or wrong cov 'kind' specified")
        exit()
    end

    for i=1:nx
        covmat_x[i,:] .= sigma[1]^2 .* 
            calccovfun(sqrt.((x.-x[i]).^2),corrlength[1])
    end
    for i=1:ny
        covmat_y[i,:] .= sigma[2]^2 .* 
            calccovfun(sqrt.(((y.-y[i])).^2),corrlength[2])
    end
    for i=1:nz
        covmat_z[i,:] .= sigma[3]^2 .* 
            calccovfun(sqrt.(((z.-z[i])).^2),corrlength[3])
    end
    
    return covmat_x,covmat_y,covmat_z
 end
 nothing # hide
```

```@example threedex
# standard deviations
sigmaobs  = [0.1, 0.1, 0.1] 
sigmam    = [0.7, 0.8, 0.8] 
# correlation lengths
corlenobs = [1.3, 1.4, 1.4] 
corlenm   = [2.5, 2.5, 2.5] 
# create the covariance matrices on observed data
Cd1,Cd2,Cd3 = mkCovSTAT(sigmaobs,nxobs,nyobs,nzobs,corlenobs,"gaussian")
# create the covariance matrices on model parameters
Cm1,Cm2,Cm3 = mkCovSTAT(sigmam,nx,ny,nz,corlenm,"gaussian") 

# Forward model operator
G1 = rand(nxobs,nx)
G2 = rand(nyobs,ny)
G3 = rand(nzobs,nz)

 nothing # hide
```

Finally, a "true/reference" model, in order to compute some synthetic "observed" data and a prior model.

```@example threedex
# create a reference model
refmod = rand(nx*ny*nz)

# create a prior model
mprior = copy(refmod) .+ 0.3.*randn(length(refmod)) 

# create some "observed" data
dobs = kron(G1,kron(G2,G3)) * refmod 
# add some noise to make it more realistic
dobs = dobs .+ 0.02.*randn(length(dobs)) 

#nothing # hide
```
Now we have create a synthetic example to play with, which we can solve as shown in the following.


### Solving the 3D problem
In order to solve the inverse problem using KronLinInv, we first need to compute the "factors" using the function [`calcfactors()`](@ref), which takes as inputs two `struct`s containing the covariance matrices and the forward operators.
```@example threedex
using KronLinInv

# create the covariance matrix structure
Covs = CovMats(Cd1,Cd2,Cd3,Cm1,Cm2,Cm3)

# forward model operator
Gfwd = FwdOps(G1,G2,G3)

# Calculate the required factors
klifac = calcfactors(Gfwd,Covs)

nothing # hide
```

Now the inverse problem can be solved. We first compute the posterior mean and then a subset of the posterior covariance.
 
```@example threedex

# Calculate the posterior mean model
postm = posteriormean(klifac,Gfwd,mprior,dobs)

# Calculate the posterior covariance
npts = nx*ny*nz
astart, aend = 1,div(npts,3) # set of rows to be computed
bstart, bend = 1,div(npts,3) # set of columns to be computed

# compute the block of posterior covariance
postC = blockpostcov(klifac,astart,aend,bstart,bend)

nothing # hide
```





```@meta
Author = "Andrea Zunino"
```
