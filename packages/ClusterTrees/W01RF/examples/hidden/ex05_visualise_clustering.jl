using ClusterTrees, BEAST, CompScienceMeshes

a, h = 1.0, 0.25
Γ1 = meshsphere(a, h)
Γ2 = CompScienceMeshes.translate(Γ1, point(2.1,0,0))

X1 = lagrangecxd0(Γ1)
X2 = lagrangecxd0(Γ2)

p = positions(X1)
q = positions(X2)

p, tp, permp = clustertree(p)
q, tq, permq = clustertree(q)

function adm(b) # p and q are passed in implicitly
    nmin = 20
    I = b[1][1].begin_idx : b[1][1].end_idx-1
    J = b[2][1].begin_idx : b[2][1].end_idx-1
    length(I) < nmin && return true
    length(J) < nmin && return true
    ll1, ur1 = ClusterTrees.boundingbox(p[I]); c1 = (ll1+ur1)/2;
    ll2, ur2 = ClusterTrees.boundingbox(q[J]); c2 = (ll2+ur2)/2;
    diam1 = norm(ur1-c1)
    diam2 = norm(ur2-c2)
    dist12 = norm(c2-c1)
    return dist12 >= η*max(diam1, diam2)
end

blocktree, η = (tp,tq), 2.0
P = admissable_partition(blocktree, adm)

# sanity check on the tree
for (τ,σ) in P
    tree_size = 0
    depthfirst(τ) do c,l
        tree_size += 1
    end
    @assert τ[1].num_children+1 == tree_size
end

depthfirst(tp) do τ,l
    I = τ[1].begin_idx : τ[1].end_idx-1
    for c in children(τ)
        J = c[1].begin_idx : c[1].end_idx-1
        @assert J ⊆ I
    end
end

# gather all the observer clusters that participate in an interaction pair
Q = Vector{typeof(P[1][1])}()
for (i,p) in enumerate(P)
    τ1, _ = p[1], p[2]
    I = τ1[1].begin_idx : τ1[1].end_idx-1
    descendant = false
    for q in P
        τ2, _ = q[1], q[2]
        J = τ2[1].begin_idx : τ2[1].end_idx-1
        # Can τ2 be reached from τ1?
        descendant = ((J != I) && (J ⊆ I))
        !isempty(intersect(I,J)) && !(J ⊆ I) && !(I ⊆ J) && (@show I J)
        descendant && break
    end
    !descendant && push!(Q,τ1)
end
Q = unique(Q)
length(Q)
length(P)

balance = zeros(numfunctions(X1))
for q in Q
    I = q[1].begin_idx : q[1].end_idx-1
    balance[permp[I]] .+= 1
end
@show extrema(balance)

using MATLAB
mat"figure()"
mat"hold("on")"
V = [v[i] for v in Γ1.vertices, i in 1:3]
F = [f[i] for f in Γ1.faces, i in 1:3]
@mput V F
for (r,q) in enumerate(Q)

    I = q[1].begin_idx : q[1].end_idx-1
    I = permp[I]
    @mput I r
    mat"patch("Vertices",V,"Faces",F[I,:],"FaceColor",rand(3,1))"
end


## Another sanity check: everything can be reached from the root
for (i,τ) in enumerate(tp)
    reached = false
    depthfirst(tp) do st,l
        st[1] == τ && (reached = true)
    end
    if !reached
        @show τ
        @show i
        error()
    end
end
