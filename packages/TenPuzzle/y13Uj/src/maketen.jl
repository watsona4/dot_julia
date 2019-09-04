using DocStringExtensions
import Base
using DataStructures


"""
A node represents either a number or operator.
  If number, then the node is a leaf.
  If operator, then it has left and right nodes.
A mathematical expression can be represented by a binary tree of the nodes.
E.g.,
(1 + 2) * (7 - 2) is represented by

*   
├─ + 
│  ├─ 1
│  └─ 2
└─ -
   ├─ 7
   └─ 2
"""
struct Node
    value::Rational
    str::String
    isnumber::Bool
    left::Union{Node,Nothing}
    right::Union{Node,Nothing}

    Node(x::Rational) = new(x, replace(string(x), r"//" => "/"),
                            true, nothing, nothing)
    Node(x::Int) = new(Rational(x), string(x), true, nothing, nothing)
    Node(op, left::Node, right::Node) = new(op(left.value, right.value), 
                                            op == (//) ? "/" : string(op),
                                            false, left, right)
end

Base.:+(a::Node, b::Node) = Node(+, a, b)
Base.:-(a::Node, b::Node) = Node(-, a, b)
Base.:*(a::Node, b::Node) = Node(*, a, b)
Base.:/(a::Node, b::Node) = Node(//, a, b)


"""
Convert a tree into a mathematical expression
"""
function toexpr(node::Node, opprev::String, isright::Bool)::String
    if node.isnumber
        if occursin("/", node.str)
            # rational number should be treated as a chunk
            return "($(node.str))"
        else
            return node.str
        end
    end
    
    paren = needparen(opprev, node.str, isright)
    ret = ""
    paren && (ret *= "(")
    ret *= toexpr(node.left, node.str, false)
    ret *= " $(node.str) "
    ret *= toexpr(node.right, node.str, true)
    paren && (ret *= ")")
    ret
end

toexpr(node::Node) = toexpr(node, "", false)

needparen(opprev::String, op::String, isright::Bool) = 
    (op=="/" && opprev in ("*","/") && isright) ||
    (op in ("+", "-") && opprev in ("*","/")) ||
    (op in ("+", "-") && opprev=="-" && isright) 

#===================================================================================#


"""
Reduction iterator, given a set of nodes, generates a set of nodes reduced by one-step computation
"""
struct Reductions
    ctr::Accumulator{Node,Int}
    nodes::Vector{Node}
    counts::Vector{Int}
    
    function Reductions(ctr::Accumulator{Node,Int})
        nodes = [k for k in keys(ctr)]
        counts = [v for v in values(ctr)]
        new(ctr, nodes, counts)
    end
    Reductions(xs::Node...) = Reductions(counter(xs))
end

function Base.iterate(r::Reductions, state::Int)
    n = length(r.nodes)  # number of unique nodes
    (state >= 4*n*n) && return nothing

    k = div(state, n*n)
    i = div(state-n*n*k, n)
    j = state-n*n*k-n*i
    i += 1; j += 1; k += 1
    
    n1, n2 = r.nodes[i], r.nodes[j]
    op = (+,-,*,/)[k]
    
    # invalid cases
    # same node, but count is smaller than 2
    (i==j) && (r.counts[i] < 2) && return iterate(r, state+1)
    # + and * are order independent
    (i>j) && (op in (+,*)) && return iterate(r, state+1)
    # zero division
    (n2.value==Rational(0)) && (op == (/)) && return iterate(r, state+1)
    
    remain = copy(r.ctr)
    n = op(n1, n2)
    inc!(remain, n)
    dec!(remain, n1)==0 && delete!(remain.map, n1)
    dec!(remain, n2)==0 && delete!(remain.map, n2)
    remain, state+1        
end

Base.iterate(r::Reductions) = iterate(r, 0)

#===================================================================================#

"""
Extract only numbers from a set of nodes
"""
valueonly(xs::Accumulator{Node,Int}) = Set(Pair(n.value,c) for (n,c) = xs)

const NOTFOUND = "NOT FOUND"

"""
Solver of a ten puzzle
"""
function solve!(xs::Accumulator{Node,Int};
                tgt=Rational(10), failed=Set{Set{Pair{Rational,Int}}}())::String
    valueonly(xs) in failed && return NOTFOUND
    
    if (sum(xs)==1)
        node = collect(keys(xs))[1]
        return node.value==tgt ? toexpr(node) : NOTFOUND
    end
    for ys = Reductions(xs)
        ans = solve!(ys, tgt=tgt)
        ans == NOTFOUND ? push!(failed, valueonly(ys)) : return ans
    end
    NOTFOUND
end
#===================================================================================#


"""
$(SIGNATURES)

Make ten (or given target value) using given numbers and four arithmetic operations

#Examples
```julia-repl
julia> maketen(1,1,9,9)
"(1 / 9 + 1) * 9"
```
"""
maketen(xs::Union{Int,Rational}...; tgt=10) = solve!(counter(Node.(xs)), tgt=Rational(tgt))