using ClusterTrees
#using Plots; plotlyjs()

p = rand(40)
p, tp = clustertree(p)

q = rand(40)
q, tq = clustertree(q)

depthfirst(tp) do b,l
    println(l, ": ", b[1].begin_idx:b[1].end_idx-1)
end

depthfirst(tq) do b,l
    println(l, ": ", b[1].begin_idx:b[1].end_idx-1)
end

@assert first(children((tp,tq)))[1] isa ClusterTrees.Tree
@assert first(children((tp,tq)))[2] isa ClusterTrees.Tree

S = zeros(length(p), length(p))
depthfirst((tp,tp)) do b,l
    I = b[1][1].begin_idx : b[1][1].end_idx-1
    J = b[2][1].begin_idx : b[2][1].end_idx-1
    println(l, ": ", I, "×", J)
    l == 5 && (S[I,J] = rand(1:20))
end

# Visual representation of the block partition at level 3
# heatmap(S)
nmin = 20
η = 1.5
function adm(b)
    I = b[1][1].begin_idx : b[1][1].end_idx-1
    J = b[2][1].begin_idx : b[2][1].end_idx-1
    length(I) < nmin && return true
    length(J) < nmin && return true
    ll1, ur1 = ClusterTrees.boundingbox(p[I]); c1 = (ll1+ur1)/2;
    ll2, ur2 = ClusterTrees.boundingbox(p[J]); c2 = (ll2+ur2)/2;
    diam1 = norm(ur1-c1)
    diam2 = norm(ur2-c2)
    dist12 = norm(c2-c1)
    return dist12 >= η*max(diam1, diam2)
end

P = admissable_partition((tp,tp), adm)
S = zeros(length(p), length(p))
for b in P
    I = b[1][1].begin_idx : b[1][1].end_idx-1
    J = b[2][1].begin_idx : b[2][1].end_idx-1
    S[I,J] += length(I) + length(J)
end

extrema(S)

# using Plots; plotlyjs();
# heatmap(S)

find(P) do b
    I = b[1][1].begin_idx : b[1][1].end_idx-1
    J = b[2][1].begin_idx : b[2][1].end_idx-1
    length(I) + length(J) == 40
end
