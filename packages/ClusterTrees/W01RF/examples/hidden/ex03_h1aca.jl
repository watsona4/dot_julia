using ClusterTrees, BEAST, CompScienceMeshes

a, h = 1.0, 0.061
#a, h = 1.0, 0.151
Γ1 = meshsphere(a, h)
Γ2 = CompScienceMeshes.translate(Γ1, point(2.10,0,0))

X1 = raviartthomas(Γ1)
X2 = raviartthomas(Γ2)

@show numfunctions(X1)
@show numfunctions(X2)

κ = 1.0; γ = κ*im;
t = Maxwell3D.singlelayer(gamma=γ)

A = ClusterTrees.h1compress(t,X1,X2)

sz = storedentries(A)
println("Compression: ",  sz/numfunctions(X1)/numfunctions(X2))

@time Z1 = assemble(t,X1,X2)
Z2 = ClusterTrees.reconstruct(A)

norm(Z1-Z2)
