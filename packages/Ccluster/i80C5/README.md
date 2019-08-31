# Ccluster.jl

Ccluster.jl is a Julia wrapper for Ccluster (https://github.com/rimbach/Ccluster.git)
that implements a clustering algorithm for univariate polynomials whose
coefficients are complex numbers.

Ccluster.jl also provides a clustering function for triangular systems of polynomial
equations.

Ccluster.jl is compatible with julia >= 1.1.0.

The Branch compat-julia-v0.6 is compatible with julia 0.6, but is not intended to be maintained.

## Brief description

### Univariate solver

The main function provided by Ccluster.jl is **ccluster**.
It takes as input
a polynomial *P*, 
a square complex box *B*
and a precision *eps*.

It outputs a set of *natural clusters* of roots together with the sum of multiplicities
of the roots in each cluster.
A cluster is a complex disc *D* containing at least one root, 
and it is natural when *3D* contains the same roots
than *D*.
Each root of *P* in *B* is in exactly one cluster of the output, and clusters may contain
roots of *P* in *2B*.

The implemented algorithm is described here:
https://dl.acm.org/citation.cfm?id=2930939

Please cite:
https://link.springer.com/chapter/10.1007/978-3-319-96418-8_28
if you use it in your research.

### Solver for triangular systems

The notion of natural clusters is straightforwardly extended to the multivariate case.
Our function **tcluster** (t for triangular)
takes as input
a triangular polynomial system *P*, 
a vector of square complex boxes *B*
and a precision *eps*.

It outputs a set of *natural clusters* of solutions of P together with the sum of multiplicities
of the solutions in each cluster.
Each solution of *P* in *B* is in exactly one cluster of the output, and clusters may contain
solutions of *P* in *2B*.

The implemented algorithm is described here:
https://arxiv.org/abs/1806.10164

## Installation

Enter the packages manager with
```
]
```
then

```
add https://github.com/rimbach/Ccluster.jl
```
Ccluster depends on Nemo that will be automatically installed.

For graphical outputs, install the package CclusterPlot with
```
add https://github.com/rimbach/CclusterPlot.jl
```
in the packages manager.

CclusterPlot depends on PyCall and PyPlot, and requires that matplotlib is installed
on your system.
It is heavy both to install and to load.

## Usage: univariate solver

### Simple example: clustering the roots of a Mignotte-like polynomial
See the file examples/mignotte.jl
```
using Nemo

R, x = PolynomialRing(QQ, "x")

d=64
a=14
P = x^d - 2*((2^a)*x-1)^2 #mignotte polynomial

using Ccluster

bInit = [fmpq(0,1),fmpq(0,1),fmpq(4,1)] #box centered in 0 + sqrt(-1)*0 with width 4
precision = 53                          #get clusters of size 2^-53

Res = ccluster(P, bInit, precision, verbosity="silent");
                                        #verbosity can take value "silent" (default value),
                                        #                         "brief" (brief report),
                                        #                         "results" (clusters are printed)
```
Res in an array of couples (sum of multiplicity, disc):
```
63-element Array{Any,1}:
 Any[1, Nemo.fmpq[975//1024, 1025//1024, 15//2048]]      
 ⋮                                                      
 Any[1, Nemo.fmpq[-2995//4096, 4805//4096, 15//8192]] 
 Any[2, Nemo.fmpq[0, 0, 15//16384]]                     # the cluster with sum of multiplicity 2
 Any[1, Nemo.fmpq[6935//8192, -8955//8192, 15//16384]]
 Any[1, Nemo.fmpq[6935//8192, 8955//8192, 15//16384]]
```
each element of Res being an array which
* second element is a complex disc (defined by the real and
imaginary parts of its center and its radius)
* first element is the sum of multiplicities of the roots in the disk.

If you care about geometry, so do we.
If you have installed CclusterPlot.jl, you can plot the clusters with:
```
using CclusterPlot

plotCcluster(Res, bInit, focus=false)
```
The last argument is a flag telling the function wether to focus 
on clusters (when *true*) or not (when *false*).
You can also add *markers=false* as an optional argument
to avoid plotting approximations of the roots with markers.

### Other example: clustering the roots of a polynomial whose coefficients are roots of polynomials
See the file examples/coeffsBernoulli.jl
#### Find the 64 roots of the Bernoulli polynomial of degree 64
```
using Nemo

RR, x = PolynomialRing(Nemo.QQ, "x")

n = 64 #degree
P = zero(RR)
bernoulli_cache(n)
for k = 0:n
    global P
    coefficient = (binom(n,k))*(bernoulli(n-k))
    P = P + coefficient*x^k
end #P is now the Bernoulli polynomial of degree 64

using Ccluster

bInit = [fmpq(0,1),fmpq(0,1),fmpq(100,1)] #box centered in 0 + sqrt(-1)*0 with width 100
precision = 53                          #get clusters of size 2^-53
Coeffs = ccluster(P, bInit, precision)
```
#### Define an approximation function for the polynomial whose coefficients are the found roots
```
function getApproximation( dest::Ptr{acb_poly}, preci::Int )

    function getApp(prec::Int)::Nemo.acb_poly
        eps=fmpq(1,fmpz(2)^prec)
        R = Nemo.RealField(prec)
        C = Nemo.ComplexField(prec)
        CC, y = PolynomialRing(C, "y")
        res = zero(CC)
        for i=1:n
            btemp = [ Coeffs[i][2][1], Coeffs[i][2][2], 2*Coeffs[i][2][3] ]
            temp = ccluster(P, btemp, prec)
            approx::Nemo.acb = C( Nemo.ball(R(temp[1][2][1]),R(eps)), Nemo.ball(R(temp[1][2][2]),R(eps)))
            res = res + approx*y^(i-1)
        end
        return res
    end
    
    precTemp::Int = 2*preci
    poly = getApp(precTemp)
    
    while Ccluster.checkAccuracy( poly, preci ) == 0
            precTemp = 2*precTemp
            poly = getApp(precTemp)
    end
    
    Ccluster.ptr_set_acb_poly(dest, poly)
end
```
#### Cluster the roots
```
bInit = [fmpq(0,1),fmpq(0,1),fmpq(100,1)] #box centered in 0 + sqrt(-1)*0 with width 100
precision = 53                          #get clusters of size 2^-53
Roots = ccluster(getApproximation, bInit, precision, verbosity="brief")
```
Output (total time in s on a Intel(R) Core(TM) i7-7600U CPU @ 2.80GHz):
```
 -------------------Ccluster: ----------------------------------------
 -------------------Input:    ----------------------------------------
|box: cRe: 0                cIm: 0                wid: 100            |
|eps: 1/100                                                           |
|strat: newton tstarOpt predPrec anticip                              |
 -------------------Output:   ----------------------------------------
|number of clusters:                                 63               |
|number of solutions:                                63               |
 -------------------Stats:    ----------------------------------------
|total time:                                   1.802102               |
 ---------------------------------------------------------------------
63-element Array{Any,1}:
 Any[1, Nemo.fmpq[-3125//32768, 5125//8192, 375//65536]]    
 ⋮                                                              
 Any[1, Nemo.fmpq[211625//262144, -105125//262144, 375//524288]]
 ```

### Defining an approximation function
**ccluster** takes as input a function prototyped as:
```
function getApproximation( dest::Ptr{Nemo.acb_poly}, p::Int )
```
Here is an example for a polynomial with complex coefficients (see also the file examples/spiral.jl)
```
degr=64
function getApproximation( dest::Ptr{acb_poly}, precision::Int )
    
    function getAppSpiral( degree::Int, prec::Int )::Nemo.acb_poly
        CC = ComplexField(prec)
        R2, y = PolynomialRing(CC, "y")
        res = R2(1)
        for k=1:degree
            modu = fmpq(k,degree)
            argu = fmpq(4*k,degree)
            root = modu*Nemo.exppii(CC(argu))
            res = res * (y-root)
        end
        return res
    end
    
    precTemp::Int = 2*precision
    poly = getAppSpiral( degr, precTemp)
    
    while Ccluster.checkAccuracy( poly, precision ) == 0
            precTemp = 2*precTemp
            poly = getAppSpiral(degr, precTemp)
    end
    
    Ccluster.ptr_set_acb_poly(dest, poly)

end
```

### Defining an initial box  
The initial box is an array of three Nemo.fmpq defining respectively
the real part of the center,
the imaginary part of the center and
the width of the box.

The following code:
```
bInit = [fmpq(0,1),fmpq(0,1),fmpq(150,1)]
```
defines a box centered in 0+*i*0 with width 150.

### The precision

The precision is an integer *p*. Ccluster computes clusters of size *eps=2^-p*.

### The verbosity flag
The last, optional, argument of ccluster is a verbosity flag.
When no verbosity is given, ccluster is silent.
Values can be "brief" and "results".

## Usage: solver for triangular systems
### Simple example: clustering the roots of a Mignotte-like polynomial
See the file examples/triangularSys.jl
```
using Nemo
using Ccluster

Rx, x = PolynomialRing(QQ, "x") #Ring of polynomials in x with rational coefficients
Syx, y = PolynomialRing(Rx, "y") #Ring of polynomials in y with coefficients that are in Rx

d1=30
c = 10
delta=128
d2=10

twotodelta = fmpq(2,1)^(delta)
f  = Rx( x^d1 - (twotodelta*x-1)^(c) )
g = Syx( y^d2 - x^d2 )

precision = 53
bInitx = [fmpq(0,1),fmpq(0,1),fmpq(10,1)^40]

nbSols, clusters, ellapsedTime = tcluster( [f,g], [bInitx], precision, verbosity = "silent" );
```
nbSols is the total number of solutions (counted with multiplicity),
clusters is an array of clusters of solutions and
ellapsedTime is the time spent to solve the system.

Each element in clusters is an array which first element is the sum of multiplicities
of the solution in the cluster and second element is a *precision*-bit approximation
of the solutions (of type Nemo::acb).

You can print the clusters with:
```
printClusters(stdout, nbSols, clusters)
```
