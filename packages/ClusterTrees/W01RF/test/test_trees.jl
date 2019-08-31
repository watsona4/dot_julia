using ClusterTrees
using Test

N = ClusterTrees.SimpleTrees.TreeNode
nodes = N[
    N(8,"a"),
        N(2,"b"),
            N(0,"c"),
            N(0,"d"),
        N(4,"e"),
            N(0,"f"),
            N(2,"g"),
                N(0,"h"),
                N(0,"i")]

tree = ClusterTrees.SimpleTrees.SimpleTree(nodes)
ClusterTrees.print_tree(tree)

chdit = ClusterTrees.children(tree)

@test data(tree) == "a"
@test collect(data(ch) for ch in ClusterTrees.children(tree)) == ["b","e"]
@test collect(data(lv) for lv in ClusterTrees.leaves(tree)) == ["c","d","f","h","i"]


const N2 = ClusterTrees.PointerBasedTrees.Node
nodes2 = N2[
    N2("a",2,-1,-1,2),
        N2("b",2,5,1,3),
            N2("c",0,4,2,-1),
            N2("d",0,-1,2,-1),
        N2("e",2,-1,1,6),
            N2("f",0,7,5,-1),
            N2("g",2,-1,5,8),
                N2("h",0,9,7,-1),
                N2("i",0,-1,7,-1)]
tree2 = ClusterTrees.PointerBasedTrees.PointerBasedTree(nodes2,1)

@test data(tree2) == "a"
@test collect(data(tree2,ch) for ch in ClusterTrees.children(tree2)) == ["b","e"]
@test collect(data(tree2,lv) for lv in ClusterTrees.leaves(tree2)) == ["c","d","f","h","i"]

ClusterTrees.print_tree(tree2)
