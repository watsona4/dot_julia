
struct CtbTree
    label::String
    adj::Vector{CtbTree}
    # prob::Float64
end
   

isleaf(tree::CtbTree) = length(tree.adj) == 0

function dfstraverse(tree::CtbTree, visitor::Function)
    for chd in tree.adj
        dfstraverse(chd, visitor)
    end
    visitor(tree)
    return nothing
end

function label(s::String) #todo special cases
    t = findfirst(!isletter, s)
    return (t == nothing || t == 1) ? s : s[1:t - 1]
end

function CtbTree(chars::Vector{Char}; l = findfirst(isequal('('), chars), trim = label)
    nchar = length(chars)
    l += 1
    r = l
    while chars[r] != '(' && chars[r] != ')' r += 1 end
    if (chars[r] == ')')
        ss = split(join(chars[l:r - 1]))
        @assert length(ss) == 2
        leaf = CtbTree(String(ss[2]), CtbTree[])
        posn = CtbTree(trim(String(ss[1])), CtbTree[leaf])
        return posn
    else
        @assert chars[r] == '('
        ss = split(join(chars[l:r - 1]))
        # @assert length(ss) == 1 string(l, "  ", chars)
        if length(ss) == 0
            return CtbTree(chars; l = r)
        end
        @assert length(ss) == 1
        fa = CtbTree(trim(String(ss[1])), CtbTree[])
        # setlabel!(obj, cur, ss[1])
        nlb = 1
        while nlb > 0
            if (chars[r] == '(')
                if nlb == 1 l = r end
                nlb += 1
            elseif chars[r] == ')'
                nlb -= 1
                if nlb == 1
                    push!(fa.adj, CtbTree(chars; l = l, trim = trim))
                end
            end
            r += 1
        end
        return fa
    end
end

CtbTree(ct::String; trim = label) = CtbTree(collect(ct); trim = trim)

function ==(ta::CtbTree, tb::CtbTree)
        ta.label == tb.label && length(ta.adj) == length(tb.adj) && all(i -> ta.adj[i] == tb.adj[i], 1:length(ta.adj))
end

function size(tree::CtbTree)
    if isleaf(tree) return (1, 1)
    else
        h = w = 0
        for chd in tree.adj
            ch, cw = size(chd)
            h += ch; w = max(w, cw + 1)
        end
        return (h, w)
    end
end

function display(obj::CtbTree)
    xlim, ylim = size(obj)
    mat = fill("", xlim, ylim)
    ileaf = 1
    colors = Dict{String, Int}()
    edges = Vector{Tuple{Int, Int, Int, Int}}()
    function dfs(cur::CtbTree)
        if !haskey(colors, cur.label)
            colors[cur.label] = (1 + (length(colors) + 1) * 10) % 256
        end
        if isleaf(cur)
            mat[ileaf, ylim] = cur.label
            ileaf += 1
            return (ileaf - 1, ylim)
        else
            cxys = Vector{Tuple{Int, Int}}()
            x = xlim; y = ylim;
            for chd in cur.adj
                cx, cy = dfs(chd)
                x = min(x, cx)
                y = min(y, cy - 1)
                push!(cxys, (cx, cy))
            end
            for cxy in cxys push!(edges, (x, y, cxy[1], cxy[2])) end
            mat[x, y] = cur.label
            return (x, y)
        end
    end
    dfs(obj);
    for (lx, ly, rx, ry) in edges
        for x = lx + 1:rx - 1
            new = old = mat[x, ly]
            if old == "" new = "│" end
            if old == "└" new = "├" end
            mat[x, ly] = new
        end
        if lx < rx mat[rx, ly] = "└" end
        mat[rx, ly + 1:ry - 1] .= "─";
    end
    yw = mapreduce(length, max, mat; dims = 1) .+ 2
    for x = 1:xlim, y = 1:ylim
        s = mat[x, y]; ns = length(s)
        # words
        if y == ylim println(" ", s); continue end
        padl = div(yw[y] - ns, 2)
        if (y == ylim - 1)
            padl = yw[y] - ns
        end
        padr = yw[y] - ns - padl
        padlc = padrc = '─'
        if s == "" || s == "│"
            padlc = padrc = ' '
        elseif s == "└" || s == "├" || x == 1 && y == 1
            padlc = ' '
        end
        ns = padlc ^ padl * s * padrc ^ padr
        for i = 1:padl print(padlc) end
        if haskey(colors, s) printstyled(s; color = colors[s]) else print(s) end
        for i = 1:padr print(padrc) end
    end
    return nothing
end
   

# ctb = parsectb("data/ctb8.0")

# using DataFrames
# import Base.stat
# function stat(ctb::CtbTreeBank)
#     from = Vector{String}(); to = Vector{Vector{String}}()
#     from2 = Vector{String}(); to2 = Vector{String}()
#     function visitor(tree, cur)
#         nchds = length(tree.adj[cur])
#         if nchds > 0
#             if nchds == 1
#                 chd = tree.adj[cur][1]
#                 if length(tree.adj[chd]) == 0
#                     if tree.label[cur] != "-NONE-"
#                         push!(from2, tree.label[cur])
#                         push!(to2, tree.label[chd])
#                     end
#                 elseif tree.label[chd] != "-NONE-"
#                     push!(from, tree.label[cur])
#                     push!(to, tree.label[tree.adj[cur]])
#                 end
#             else
#                 push!(from, tree.label[cur])
#                 push!(to, tree.label[tree.adj[cur]])
#             end
#         end
#     end
#     for vec in ctb
#         for tree in vec
#             dfstraverse(tree, visitor)
#         end
#     end
#     function f(df::DataFrame)
#         return by(df, [:from, :to], tot = :from => length, sort = true)
#     end
#     inn = f(DataFrame(from = from, to = to))
#     pos = f(DataFrame(from = from2, to = to2))
#     inn, pos
# end

# CtbTreeNode = Union{InnerTreeNode, PosTreeNode, LeafTreeNode}
# CtbTreeNode(label::String, id::String) == InnerTreeNode(label, id, Int[], 0.0)

function cnf(root::CtbTree)::CtbTree
    nchd = length(root.adj)
    if nchd == 0
        return root
    elseif nchd <= 2
        newroot = CtbTree(root.label, CtbTree[])
        for i = 1:nchd push!(newroot.adj, cnf(root.adj[i])) end
        return newroot
    else
        newroot = CtbTree(root.label, CtbTree[])
        newright = CtbTree(join(map(x -> x.label, root.adj[2:end]), "+"), root.adj[2:end])
        push!(newroot.adj, cnf(root.adj[1]))
        push!(newroot.adj, cnf(newright))
        return newroot
    end
end

function decnf(root::CtbTree)
    nodes = decnf2(root)
    return length(nodes) == 1 ? nodes[1] : CtbTree(join(map(x -> x.label, nodes), "+"), nodes)
end

function decnf2(root::CtbTree)::Vector{CtbTree}
    nchd = length(root.adj)
    if nchd == 0 return CtbTree[root] end
    if nchd == 1
        newroot = CtbTree(root.label, decnf2(root.adj[1]))
        return CtbTree[newroot]
    end
    newroot = CtbTree(root.label, append!(decnf2(root.adj[1]), decnf2(root.adj[2])))
    istmp = in('+', root.label)
    return istmp ? newroot.adj : CtbTree[newroot]
end
