using ClusterTrees
using StaticArrays
using AdaptiveCrossApproximation

p = rand(SVector{2,Float64}, 100)
q, tree = AdaptiveCrossApproximation.clustertree(p)

using Plots
gr()


rectangle(ll, ur) = [ll[1],ur[1],ur[1],ll[1],ll[1]], [ll[2],ll[2],ur[2],ur[2],ll[2]]

plot()
level = 1
clrs = [:blue, :red, :green, :black, :cyan, :yellow]
state = [(0,tree[1].num_children)]
for (i,b) in enumerate(tree)
    ll, ur = ClusterTrees.boundingbox(q[b.data.begin_idx:b.data.end_idx-1])
    x, y = rectangle(ll, ur)
    level == 5 && plot!(x,y,color=clrs[level])
    level == 4 && println(level, ": ", b.data.begin_idx:b.data.end_idx-1)
    state[end] = (state[end][1] + b.num_children + 1, state[end][2])
    if b.num_children != 0
         level += 1
         push!(state, (0,b.num_children))
     else
         while state[end][1] == state[end][2]
             level -= 1
             pop!(state)
         end
     end
     plot!()
end


x = [r[1] for r in q]
y = [r[2] for r in q]
scatter!(x,y)
plot!(axis=:none,legend=:none)
plot!(title="level 4 ACA clusters")

ClusterTrees.print_tree(tree)
