module TikzQTrees

import TikzPictures: TikzPicture
import Base: show, showable, iterate, eltype, IteratorSize, map

export TikzQTree, value, children, leafs, @qtree
export SimpleTree

######################
### Abstract Trees ###
######################

"""
    AbstractTree{T}

abstract type for trees with values of type T

# Methods to implement
- `value(tree)`:
  Returns the value of the root of the tree
- `children(tree)`:
  Returns an iterator over the children of the root of the tree
"""
abstract type AbstractTree{T} end

"""
    value(tree)

Returns the value of the root of the tree
"""
function value(tree) 
    tree.value
end

"""
    children(tree)

Returns an iterator over the children of the root of the tree
"""
function children(tree)
    tree.children
end

isleaf(tree) = isempty(children(tree))

eltype(Tree::Type{<:AbstractTree{T}}) where T = Tree
IteratorSize(::Type{<:AbstractTree{T}}) where T = Base.SizeUnknown()

function iterate(tree::AbstractTree, state = [tree])
    if isempty(state)
        nothing
    else
        state[1], prepend!(state[2:end], children(state[1]))
    end
end

leafs(tree::AbstractTree) = [node for node in tree if isleaf(node)]

####################
### Simple Trees ###
####################

mutable struct SimpleTree{T} <: AbstractTree{T}
    value    :: T
    children :: Vector{SimpleTree{T}}
end

SimpleTree(value, T::Type=typeof(value)) = SimpleTree(value, SimpleTree{T}[])

# implement tree interface
value(tree::SimpleTree)    = tree.value
children(tree::SimpleTree) = tree.children

function map(f, tree::SimpleTree; uniform_type=true)
    node = if uniform_type
        SimpleTree(f(value(tree)))
    else
        SimpleTree(f(value(tree)), Any)
    end
    for child in children(tree)
        push!(children(node), map(f, child; uniform_type=uniform_type))
    end
    node
end

###################
### Tikz QTrees ###
###################

struct TikzQTree{T} <: AbstractTree{T}
    tree :: T
end

# implement tree interface
value(t::TikzQTree)    = value(t.tree)
children(t::TikzQTree) = map(TikzQTree, children(t.tree))

function map(f, qtree::TikzQTree; uniform_type=true)
    TikzQTree(map(f, qtree.tree, uniform_type=uniform_type))
end

function show(io::IO, t::TikzQTree)
    if isleaf(t)
        print(io, value(t), ' ')
    else
        print(io, '[', '.', value(t), ' ')
        foreach(children(t)) do child
            print(io, child)
        end
        print(io, ']', ' ')
    end
end

# show TikzQTrees using TikzPictures.jl
showable(::MIME"image/svg+xml", ::TikzQTree) = true

function show(io::IO, ::MIME"image/svg+xml", t::TikzQTree)
    show(io, MIME"image/svg+xml"(), TikzPicture(t))
end

function TikzPicture(t::TikzQTree)
    TikzPicture(string("\\Tree ", t), preamble="\\usepackage{tikz-qtree}")
end

# construct TikzQTrees from Julia expressions using @qtree
latex_string(x...) = string('{', x..., '}')

_tree(x) = SimpleTree(latex_string(x))

_tree(n::LineNumberNode) = SimpleTree(latex_string("line", n.line))

function _tree(expr::Expr)
    if expr.head == :call
        head = expr.args[1] == :^ ? "\\textasciicircum" : expr.args[1]
        SimpleTree(latex_string(head), map(_tree, expr.args[2:end]))
    else
        SimpleTree(latex_string(expr.head), map(_tree, expr.args))
    end
end

macro qtree(expr)
    :( $(TikzQTree(_tree(expr))) )
end

end # module
