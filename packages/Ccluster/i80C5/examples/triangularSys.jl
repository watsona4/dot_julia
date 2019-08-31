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

print("time to solve the system: $ellapsedTime \n")
print("number of clusters: $(length(clusters))\n")
print("number of solutions: $(nbSols)\n")

printClusters(stdout, nbSols, clusters)
