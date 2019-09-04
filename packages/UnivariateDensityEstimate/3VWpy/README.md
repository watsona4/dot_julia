# UnivariateDensityEstimate.jl

Package for univariate density estimation with combinatorial constraints, based on Bernstein polynomials. 

<h2> Installing the package </h2>

Run the following code to install the package.


```julia
import Pkg
Pkg.clone("https://github.com/visuddhi/UnivariateDensityEstimate.jl")
```

You need to also have Julia v1.1 installed (the package does not support the syntax for older Julia versions before v1.0) to be able to use this package.

<h2> The mirror-descent (MD) algorithm </h2>

It is recommended to use `BernsteinEstimate_MD(Y,m,a,b,k,e,T,MaxIter,obj,flag,Reg)` when combinatorial constraints are not imposed.

* Y: data
* m: number of Bernstein basis
* [a,b]: domain of the estimator
* k: number of modes (only k=0,1 is supported for 'BernsteinEstimate_MD' now; k=0 means vanilla density estimation, k=1 means unimodal density estimation)
* e: tolerance of error, 1e-4 by default
* T: maximum computational time (in sceonds), 10e10 by default
* MaxIter: maximum number of iterations
* obj: "Log" or "Quad", "Log" -> maximum log likelihood estimator; "Quad" -> Anderson-Darling estimator
* flag: "Acc" or "NonAcc", only applicable for k=0, "Acc" -> accelerated mirror descent, "NonAcc" -> nonaccelerated mirror descent
* Reg: coefficient of the L2 regularizer

<h2> The mixed-integer-qudratic-optimization (MIQO) algorithm </h2>

It is recommended to use `BernsteinEstimate_MIQO(Y,m,a,b,k,e,T)` when there are combinatorial constraints.

* Y: data
* m: number of Bernstein basis
* [a,b]: domain of the estimator
* k: number of modes, k can be arbitrary positive integer
* e: MIP gap
* T: maximum computational time (in sceonds)

Caution: you need to install Gurobi and maintain a valid license in order for the MIQO algorithm to work.

<h2> An example </h2>
The provided notebook (https://github.com/visuddhi/UnivariateDensityEstimate.jl/blob/master/Example.ipynb) contains a basic example of how to use the package to do density estimation, based on a tweet timing real dataset.

```julia
import Pkg
using UnivariateDensityEstimate, Statistics, Plots
```

After importing the package, we read the dataset:

```julia
using DelimitedFiles
Y1 = readdlm("data/tweet_data.txt",',');
Y1 = log.(Y1[:,2])
Y1 = Y1[Y1.>6]
Y1 = sort(vec(Y1));
a = Float64(minimum(Y1)-Statistics.std(Y1)/length(Y1)^0.5)
b = Float64(maximum(Y1)+Statistics.std(Y1)/length(Y1)^0.5)
```

We first plot the histogram of the dataset: it can be seen the empirical distribution has several modes.
```julia
histogram(Y1, label = "tweet data")
```
![tweet_histogram](https://github.com/visuddhi/UnivariateDensityEstimate.jl/blob/master/fig/tweet_histogram.png)

Then we compute the solution from both the MD algorithm and MIQO algorithm for different number of modes:
```julia
m = 250  
sol_MD_0, obj_MD_0 = BernsteinEstimate_MD(Y1,m,a,b,0,-1,10e10,15000,"Log","Acc",0);
sol_MIQO_0 = BernsteinEstimate_MIQO(Y1,m,a,b,0,0,500);
sol_MIQO_1 = BernsteinEstimate_MIQO(Y1,m,a,b,1,0,500);
sol_MIQO_2 = BernsteinEstimate_MIQO(Y1,m,a,b,2,0,500);
sol_MIQO_3 = BernsteinEstimate_MIQO(Y1,m,a,b,3,0,500);

D = 1000

val_MD_0 = vec(zeros(D,1))
val_MIQO_0 = vec(zeros(D,1))
val_MIQO_1 = vec(zeros(D,1))
val_MIQO_2 = vec(zeros(D,1))
val_MIQO_3 = vec(zeros(D,1))
x = range(a,stop = b, length = D)
for i = 1:D
    for j = 1:m
        val_MD_0[i] = val_MD_0[i]+sol_MD_0[j]*betapdf(j, m-j+1, (x[i]-a)/(b-a))/(b-a);
        val_MIQO_0[i] = val_MIQO_0[i]+sol_MIQO_0[j]*betapdf(j, m-j+1, (x[i]-a)/(b-a))/(b-a);
        val_MIQO_1[i] = val_MIQO_1[i]+sol_MIQO_1[j]*betapdf(j, m-j+1, (x[i]-a)/(b-a))/(b-a);
        val_MIQO_2[i] = val_MIQO_2[i]+sol_MIQO_2[j]*betapdf(j, m-j+1, (x[i]-a)/(b-a))/(b-a);
        val_MIQO_3[i] = val_MIQO_3[i]+sol_MIQO_3[j]*betapdf(j, m-j+1, (x[i]-a)/(b-a))/(b-a);
    end
end
```
We plot the estimated density functions and we see when no combinatorial constraints are imposed, the estimated density is close to the empirical denstiy; and when we constrain the number of modes, the estimated density become more regular (less significant modes are eliminated).

```julia
plot(x,val_MD_0,label="MD pdf (k=0)")
plot!(x,val_MIQO_0,label="QO pdf (k=0)")
plot!(x,val_MIQO_1,label="MIQO pdf (k=1)")
plot!(x,val_MIQO_2,label="MIQO pdf (k=2)")
plot!(x,val_MIQO_3,label="MIQO pdf (k=3)")
```
![tweet_pdf](https://github.com/visuddhi/UnivariateDensityEstimate.jl/blob/master/fig/tweet_pdf_estimated.png)
