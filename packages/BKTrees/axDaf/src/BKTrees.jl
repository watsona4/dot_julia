module BKTrees

using DataStructures: Deque
import Base: show

if VERSION < v"1.0"
    import Base: find
end

export BKTree, Node, add!, find

include("tree.jl")

end # module
