using Test

import TreeViews: hastreeview, numberofnodes, treelabel, nodelabel, treenode

# test for sane defaults
struct TVT_default
    a
    b
    c
    d
end

teststruct = TVT_default(1, "asd", UInt8(2), 22.22)

hastreeview(x::TVT_default) = true

@test hastreeview(teststruct) == true
@test numberofnodes(teststruct) == 4
@test sprint(io -> treelabel(io, teststruct)) == "TVT_default"
@test sprint(io -> nodelabel(io, teststruct, 3)) == "c"
@test treenode(teststruct, 3) == teststruct.c

# customization
struct TVT_customized
    a
    b
    c
    d
end

teststruct = TVT_customized(1, "asd", UInt8(2), 22.22)

hastreeview(::TVT_customized) = true

numberofnodes(x::TVT_customized) = 2
treelabel(io::IO, x::TVT_customized, ::MIME"text/plain") = print(io, "customized")
treelabel(io::IO, x::TVT_customized, ::MIME"text/html") = print(io, "HTML")

function nodelabel(io::IO, x::TVT_customized, i::Integer, ::MIME"text/plain")
    i <= 2 || throw(BoundsError(x, i))
    print(io, "customized$i")
end
function nodelabel(io::IO, x::TVT_customized, i::Integer, ::MIME"text/html")
    i <= 2 || throw(BoundsError(x, i))
    print(io, "HTML$i")
end

function treenode(x::TVT_customized, i::Integer)
    i == 1 && return x.a
    i == 2 && return TVT_default(x.b, x.c, x.c, x.d)
end

@test numberofnodes(teststruct) == 2
@test sprint(io -> treelabel(io, teststruct)) == "customized"
@test sprint(io -> treelabel(io, teststruct, "text/html")) == "HTML"
@test sprint(io -> treelabel(io, teststruct, MIME"text/html"())) == "HTML"
@test_throws BoundsError sprint(io -> nodelabel(io, teststruct, 3))
@test sprint(io -> nodelabel(io, teststruct, 2)) == "customized2"
@test treenode(teststruct, 1) == teststruct.a
@test treenode(teststruct, 2) == TVT_default(teststruct.b, teststruct.c, teststruct.c, teststruct.d)

@test_deprecated(@test sprint(io -> treelabel(io, teststruct, 1)) == "customized1")
@test_deprecated(@test sprint(io -> treelabel(io, teststruct, 1, "text/html")) == "HTML1")
