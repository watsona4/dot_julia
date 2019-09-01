import GaussianMixtureTest
using Distributions
using KernelEstimator
using RCall

mu_true = [log(1/0.779 - 1)]
wi_true = [1.0]
sigmas_true = [1.2]
n = 282
m = MixtureModel(map((u, v) -> Normal(u, v), mu_true, sigmas_true), wi_true)

T1 = zeros(100)
P = zeros(100)
for b in 1:100
    srand(b)
    x = rand(m, n)
    T1[b], P[b] = GaussianMixtureTest.kstest(x, 1)
    print(b,"->", T1[b], " | ")
end

xs = linspace(0.01, 14, 500)
den2 = kerneldensity(T1, xeval=xs, kernel=gammakernel, lb=0.)


@rput xs den2 T1 P;
rprint(""" 
hist(T1, breaks=15, freq=F, ylim=c(0, .4))
rug(T1)
lines(xs, dchisq(xs, 2))
lines(xs, den2, lwd=2, col="blue")
""")



import GaussianMixtureTest
using Distributions
using KernelEstimator
using RCall

mu_true = [-2.0858,-1.4879]
wi_true = [0.0828,0.9172]
sigmas_true = [0.6735,0.2931]
n = 282
m = MixtureModel(map((u, v) -> Normal(u, v), mu_true, sigmas_true), wi_true)
srand(35);x = rand(m, n);GaussianMixtureTest.kstest(x, 2)

T1 = zeros(100)
P = zeros(100)
for b in 1:100
    srand(b)
    x = rand(m, n)
    T1[b], P[b] = GaussianMixtureTest.kstest(x, 2)
    print(b,"->", T1[b], " | ")
end

x = rand(m, n)
wi,mu,sigmas= GaussianMixtureTest.gmm(x, 2)
Ttrue = GaussianMixtureTest.asymptoticdistribution(x, wi, mu, sigmas)

xs = linspace(0.01, 14, 500)
den1=kerneldensity(Ttrue, xeval=xs, kernel=gammakernel, lb=0.)
den2 = kerneldensity(T1, xeval=xs, kernel=gammakernel, lb=0.)


@rput xs den1 den2 T1 P;
rprint(""" 
hist(T1, breaks=15, freq=F, ylim=c(0, .4))
rug(T1)
lines(xs, den1, lwd=2)
lines(xs, den2, lwd=2, col="blue")
""")

rprint("""
z = qnorm(1-P)
hist(z, freq=F, xlim=c(-4,4))
lines(density(z))
curve(dnorm, -4, 4, col="red",add=T)
NULL
""")


### The components

import GaussianMixtureTest
using Distributions
using KernelEstimator
using RCall

mu_true = [log(1/0.779 - 1)/3 - 4.0, log(1/0.779 - 1)/3 + 1.0, log(1/0.779 - 1)/3 + 4.0;]
wi_true = [.3, .4, .3]
sigmas_true = [1.2, .8, .9]
n = 282
m = MixtureModel(map((u, v) -> Normal(u, v), mu_true, sigmas_true), wi_true)
#srand(35);x = rand(m, n);GaussianMixtureTest.kstest(x, 2)

T1 = zeros(100)
P = zeros(100)
for b in 1:100
    srand(b)
    x = rand(m, n)
    T1[b], P[b] = GaussianMixtureTest.kstest(x, 3)
    print(b,"->", T1[b], " | ")
end

x = rand(m, n)
wi,mu,sigmas= GaussianMixtureTest.gmm(x, 3)
Ttrue = GaussianMixtureTest.asymptoticdistribution(x, wi, mu, sigmas);

xs = linspace(0.01, 14, 500);
den1=kerneldensity(Ttrue, xeval=xs, kernel=gammakernel, lb=0.);
den2 = kerneldensity(T1, xeval=xs, kernel=gammakernel, lb=0.);


@rput xs den1 den2 T1 P;
rprint(""" 
hist(T1,freq=F, xlim=c(0, 15), ylim=c(0, .22))
rug(T1)
lines(xs, den1, lwd=2)
lines(xs, den2, lwd=2, col="blue")
""")


## The fitting

import GaussianMixtureTest
using Distributions
using KernelEstimator
using RCall

mu_true = [log(1/0.779 - 1)/3 - 4.0, log(1/0.779 - 1)/3 + 1.0, log(1/0.779 - 1)/3 + 4.0;]
wi_true = [.3, .4, .3]
sigmas_true = [1.2, .8, .9]
m = MixtureModel(map((u, v) -> Normal(u, v), mu_true, sigmas_true), wi_true)

x = rand(m, 500)
wi, mu, sigmas = GaussianMixtureTest.gmm(x, 3)
mhat = MixtureModel(map((u, v) -> Normal(u, v), mu, sigmas), wi)

xs = linspace(-6, 5, 500)
dentrue = pdf(m, xs)
denhat = pdf(mhat, xs)

@rput xs dentrue denhat
rprint(""" 
plot(xs, dentrue, lwd=2, type="l")
lines(xs, denhat, lwd=2, col="blue")
""")

Ttrue = GaussianMixtureTest.asymptoticdistribution(x, wi_true, mu_true, sigmas_true)
xs = linspace(0.01, 14, 500)
den1=kerneldensity(Ttrue, xeval=xs, kernel=gammakernel, lb=0.)

@rput xs den1
rprint(""" 
plot(xs, den1, type="l")
""")
