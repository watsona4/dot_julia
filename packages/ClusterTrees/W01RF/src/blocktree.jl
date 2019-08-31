module BlockTrees

import ClusterTrees

struct BlockTree{T}
    test_cluster::T
    trial_cluster::T
end

testcluster(blocktree::BlockTree) = blocktree.test_cluster
trialcluster(blocktree::BlockTree) = blocktree.trial_cluster

ClusterTrees.root(t::BlockTree) = (ClusterTrees.root(testcluster(t)), ClusterTrees.root(trialcluster(t)))
function ClusterTrees.data(t::BlockTree, n)
    (
        ClusterTrees.data(testcluster(t), n[1]),
        ClusterTrees.data(trialcluster(t), n[2]))
end

function ClusterTrees.children(b::BlockTree, node)
    test_chds = ClusterTrees.children(testcluster(b), node[1])
    trial_chds = ClusterTrees.children(testcluster(b), node[2])
    ((ch[1],ch[2]) for ch in Iterators.product(test_chds, trial_chds))
end

function ClusterTrees.haschildren(b::BlockTree, node)
    !ClusterTrees.haschildren(testcluster(b), node[1]) && return false
    !ClusterTrees.haschildren(trialcluster(b), node[2]) && return false
    return true
end

function ClusterTrees.LevelledTrees.numlevels(bt)
    num_test_levels = ClusterTrees.LevelledTrees.numlevels(testcluster(bt))
    num_trial_levels = ClusterTrees.LevelledTrees.numlevels(trialcluster(bt))
    @assert num_test_levels == num_trial_levels
    return num_test_levels
end

end # module BlockTrees
