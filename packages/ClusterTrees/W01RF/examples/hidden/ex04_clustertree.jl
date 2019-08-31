using ClusterTrees, BEAST, CompScienceMeshes

a, h = 1.0, 0.25
Γ1 = meshsphere(a, h)
Γ2 = CompScienceMeshes.translate(Γ1, point(2.5,0,0))

tfs = raviartthomas(Γ1)
bfs = raviartthomas(Γ2)

p = positions(tfs)
q = positions(bfs)

p, tp, permp = clustertree(p)
q, tq, permq = clustertree(q)

# Collect all boxes at depth 5
B = Array{typeof(tp)}(0)
depthfirst(tp) do t, level
  level == 5 && push!(B,t)
end

using MATLAB

# Plot points in the boxes at depth 5 in different colours
@matlab figure()
@matlab hold("on")
for b in B
  ps = p[b[1].begin_idx : b[1].end_idx-1]
  ps = [p[i] for p in ps, i in 1:3]
  @mput ps
  #@matlab plot3(ps[:,1],ps[:,2],ps[:,3],'.')
  mat"plot3(ps(:,1),ps(:,2),ps(:,3),'.')"
end


function adm(b)
    nmin = 20
    η = 1.5
    I = b[1][1].begin_idx : b[1][1].end_idx-1
    J = b[2][1].begin_idx : b[2][1].end_idx-1
    length(I) < nmin && return true
    length(J) < nmin && return true
    ll1, ur1 = ClusterTrees.boundingbox(p[I]); c1 = (ll1+ur1)/2;
    ll2, ur2 = ClusterTrees.boundingbox(q[J]); c2 = (ll2+ur2)/2;
    diam1 = norm(ur1-c1)
    diam2 = norm(ur2-c2)
    dist12 = norm(c2-c1)
    @show (diam1, diam2, dist12)
    return dist12 >= η*max(diam1, diam2)
end

# Plot the pair of clusters making up block n
tb = ClusterTrees.admissable_partition((tp,tq),adm)
n = 1
τ, σ = tb[n][1][1], tb[n][2][1]
@matlab figure()
@matlab hold("on")
ps = [p[i] for p in p[τ.begin_idx:τ.end_idx-1], i in 1:3]
qs = [q[i] for q in q[σ.begin_idx:σ.end_idx-1], i in 1:3]
@mput ps qs
mat"""
plot3(ps(:,1),ps(:,2),ps(:,3),'.')
plot3(qs(:,1),qs(:,2),qs(:,3),'.')
axis('equal','square')
"""
# @matlab begin
#   plot3(ps[:,1],ps[:,2],ps[:,3],'.')
#   plot3(qs[:,1],qs[:,2],qs[:,3],'.')
#   axis("equal","square")
# end

# Visualise the blocktree by filling in the matrix with random entries,
# one per block.
A = zeros(numfunctions(tfs), numfunctions(bfs))
for b in tb
    τ, σ = b[1][1], b[2][1]
    I = τ.begin_idx : τ.end_idx-1
    J = σ.begin_idx : σ.end_idx-1
    A[I,J] += rand(1:10)
end

using Plots
plotlyjs()
heatmap(A)
