
struct AhoCorasickAutomaton{T <: Unsigned}
    base::Vector{T}
    from::Vector{T}
    ikey::Vector{T}
    deep::Vector{T}
    back::Vector{T}
    arcs::Vector{Vector{UInt8}}
end

function AhoCorasickAutomaton{T}() where T
    base = T[1]
    from = T[1]
    ikey = T[0]
    deep = T[0]
    back = T[0]
    arcs = [UInt8[]]
    return AhoCorasickAutomaton{T}(base, from, ikey, deep, back, arcs)
end

function AhoCorasickAutomaton{T}(keys::Vector, sort::Bool) where T
        obj = AhoCorasickAutomaton{T}()
        if sort && !issorted(keys) Base.sort!(keys) end
        for (key, i) in keys
                addkey!(obj, codeunits(key), T(i))
        end
        shrink!(obj)
        @inbounds fillback!(obj)
        validate(obj)
        resize!(obj.arcs, 0)
        return obj
end

function AhoCorasickAutomaton{T}(keys::AbstractDict{String, Ti}; sort::Bool = true) where {T, Ti}
        return AhoCorasickAutomaton{T}(collect(keys), sort)
end

function AhoCorasickAutomaton{T}(keys::Vector{String}; sort::Bool = true) where T
    return AhoCorasickAutomaton{T}(collect(zip(keys, 1:length(keys))), sort)
end

function ==(x::AhoCorasickAutomaton, y::AhoCorasickAutomaton)
    return x.base == y.base && x.from == y.from && x.ikey == y.ikey && x.deep == y.deep && x.back == y.back
end

function in(key::AbstractString, obj::AhoCorasickAutomaton{T})::Bool where T
    return get(obj, key, T(0)) > 0
end

function in(key::DenseVector{UInt8}, obj::AhoCorasickAutomaton{T})::Bool where T
    return get(obj, key, T(0)) > 0
end

function get(obj::AhoCorasickAutomaton{T}, key::DenseVector{UInt8}, default::T)::T where T
    cur::T = 1
    n::T = length(obj.from)
    for c in key
        nxt = obj.base[cur] + c
        if (nxt <= n && obj.from[nxt] == cur)
            cur = nxt
        else
            return default
        end
    end
    return obj.ikey[cur]
end

function get(obj::AhoCorasickAutomaton{T}, key::AbstractString, default::T)::T where T
    return get(obj, codeunits(key), default)
end

function length(obj::AhoCorasickAutomaton{T}) where T
    return count(!iszero, obj.ikey)
end

function collect(obj::AhoCorasickAutomaton{T}) where T
    base = obj.base
    from = obj.from
    ikey = obj.ikey
    res = Pair{String, Int}[]
    for i = 1:length(ikey)
        if ikey[i] == 0 continue end
        codes = UInt8[]
        j = i
        while j > 1
            c = j - base[from[j]]
            push!(codes, c)
            j = from[j]
        end
        push!(res, String(reverse!(codes)) => ikey[i])
    end
    return res
end

function keys(obj::AhoCorasickAutomaton{T}) where T
    return map(first, collect(obj))
end

function values(obj::AhoCorasickAutomaton{T}) where T
    return filter(!iszero, obj.ikey)
end

function shrink!(obj::AhoCorasickAutomaton{T})::T where T
    actlen = findlast(!iszero, obj.from)
    if (actlen < length(obj.from))
        resize!(obj.base, actlen)
        resize!(obj.from, actlen)
        resize!(obj.ikey, actlen)
        resize!(obj.deep, actlen)
        resize!(obj.back, actlen)
        resize!(obj.arcs, actlen)
    end
    return actlen
end

function enlarge!(obj::AhoCorasickAutomaton{T}, newlen::T)::T where T
    base = obj.base; from = obj.from; deep = obj.deep; back = obj.back; ikey = obj.ikey; arcs = obj.arcs;
    oldlen::T = length(obj.base)
    newlen2 = oldlen
    while newlen2 < newlen newlen2 *= 2 end
    if (oldlen < newlen2)
        resize!(base, newlen2)
        resize!(from, newlen2)
        resize!(ikey, newlen2)
        resize!(deep, newlen2)
        resize!(back, newlen2)
        resize!(arcs, newlen2)
        # for i = oldlen + 1:newlen2 base[i] = i end
        base[oldlen + 1:newlen2] .= 0
        from[oldlen + 1:newlen2] .= 0
        ikey[oldlen + 1:newlen2] .= 0
        deep[oldlen + 1:newlen2] .= 0
        back[oldlen + 1:newlen2] .= 0
        for i in oldlen + 1:newlen2
            arcs[i] = UInt8[]
        end
    end
    return newlen2
end

function addkey!(obj::AhoCorasickAutomaton{T}, code::Base.CodeUnits{UInt8,String}, icode::T)::Nothing where T
    base = obj.base; from = obj.from; deep = obj.deep; back = obj.back; ikey = obj.ikey; arcs = obj.arcs;
    cur::T = 1
    nxt::T = 0
    for c in code
        nxt = base[cur] + c
        enlarge!(obj, nxt)
        if (from[nxt] == 0)
            from[nxt] = cur
            push!(arcs[cur], c)
            deep[nxt] = deep[cur] + 1
            cur = nxt
        elseif (from[nxt] == cur)
            cur = nxt
        else # from[nxt] != cur
            push!(arcs[cur], c)
            if length(arcs[cur]) <= length(arcs[from[nxt]]) || from[nxt] == from[cur]
                rebase!(obj, cur)
                nxt = base[cur] + c
            else
                rebase!(obj, from[nxt])
            end
            from[nxt] = cur
            deep[nxt] = deep[cur] + 1
            cur = nxt
        end
    end
    ikey[cur] = icode
    return nothing
end

function rebase!(obj::AhoCorasickAutomaton{T}, cur::T)::Nothing where T
    base = obj.base; from = obj.from; deep = obj.deep; back = obj.back; ikey = obj.ikey; arcs = obj.arcs;
    oldbase = base[cur]
    @assert length(arcs[cur]) > 0 string(cur)
    newbase = findbase(obj, cur)
    enlarge!(obj, newbase + maximum(arcs[cur]))
    for i = eachindex(arcs[cur])
        # arc = arcs[cur][i]
        newson = newbase + arcs[cur][i]
        from[newson] = cur
        oldson = oldbase + arcs[cur][i]
        if (from[oldson] != cur) continue end
        base[newson] = base[oldson]
        ikey[newson] = ikey[oldson]
        deep[newson] = deep[oldson]
        z = arcs[newson]; arcs[newson] = arcs[oldson]; arcs[oldson] = z;
        # grandsons
        for arc in arcs[newson]
            from[base[newson] + arc] = newson
        end
        # oldson
        base[oldson] = from[oldson] = ikey[oldson] = deep[oldson] = 0
    end
    base[cur] = newbase
    return nothing
end

function findbase(obj::AhoCorasickAutomaton{T}, cur::T)::T where T
    base = obj.base; from = obj.from; deep = obj.deep; back = obj.back; ikey = obj.ikey; arcs = obj.arcs;
    n::T = length(from)
    for b = max(cur + 1, base[cur]):n
        ok = true
        for arc in arcs[cur]
            @inbounds ok &= arc + b > n || from[arc + b] == 0
        end
        if (ok)
            return b
        end
    end
    return T(n + 1)
end

function fillback!(obj::AhoCorasickAutomaton{T})::Nothing where T
    base = obj.base; from = obj.from; deep = obj.deep; back = obj.back; ikey = obj.ikey; arcs = obj.arcs;
    #println(arcs)
    n::T = length(arcs)
    root::T = 1
    que = similar(base); head::T = 1; tail::T = 2;
    que[1] = root; back[root] = root;
    while head < tail
        cur = que[head]; head += 1;
        for arc in arcs[cur]
            chd = base[cur] + arc
            chdback = root
            if (cur != root)
                chdback = back[cur]
                while chdback != root && (base[chdback] + arc > n || from[base[chdback] + arc] != chdback)
                    chdback = back[chdback]
                end
                if base[chdback] + arc <= n && from[base[chdback] + arc] == chdback
                    chdback = base[chdback] + arc
                end
            end
            back[chd] = chdback
            que[tail] = chd; tail += 1;
        end
    end
    return nothing
end

function validate(obj::AhoCorasickAutomaton{T})::Nothing where T
    base = obj.base; from = obj.from; deep = obj.deep; back = obj.back; ikey = obj.ikey; arcs = obj.arcs;
    root = 1
    que = similar(base); head = 1; tail = 2;
    que[1] = root;
    while head < tail
        cur = que[head]; head += 1;
        for arc in arcs[cur]
            chd = base[cur] + arc
            # @assert from[chd] == cur && back[chd] != chd && back[chd] != 0 string(chd, " fa=", cur, " from=", from[chd], " back=", back[chd])
            @assert from[chd] == cur string("cur=", cur, " chd=", chd, " from=", from[chd])
            que[tail] = chd; tail += 1;
        end
    end
    return nothing
end

"""
ACMatch has 3 fields:

    1. s : start of match
    2. t : stop of match, [s, t), using str[s:prevind(str, t)] to get matched patterns
    3. i : index of the key in *obj*, which is the original insertion order of keys to *obj*

The field *i* may be use as index of external property arrays, i.e., the AhoCorasickAutomaton
can act as a `Map{String, Any}`.
"""
struct ACMatch
    s::Int
    t::Int
    i::Int
end

import Base.length
length(x::ACMatch) = x.t - x.s

function isless(x::ACMatch, y::ACMatch)::Bool
    return x.s < y.s || x.s == y.s && x.t < y.t || x.s == y.s && x.t == y.t && x.i < y.i
end

function eachmatch(obj::AhoCorasickAutomaton{T}, text::AbstractString)::Vector{ACMatch} where T
    return eachmatch(obj, codeunits(text))
end

function eachmatch(obj::AhoCorasickAutomaton{T}, codes::DenseVector{UInt8})::Vector{ACMatch} where T
    base = obj.base; from = obj.from; deep = obj.deep; back = obj.back; ikey = obj.ikey; arcs = obj.arcs;
    n = length(base)
    root = cur = T(1)
    res = ACMatch[]
    for i = 1:length(codes)
        c = codes[i]
        while cur != root && (base[cur] + c > n || from[base[cur] + c ] != cur)
            cur = back[cur]
        end
        if (base[cur] + c <= n && from[base[cur] + c] == cur)
            cur = base[cur] + c
        end
        # if (ikey[cur] > 0)
            node = cur
            while node != root
                if (ikey[node] > 0) push!(res, ACMatch(i + 1 - deep[node], i + 1, ikey[node])) end
                node = back[node]
            end
        # end
    end
    return res
end

import Base.getindex
getindex(xs::String, match::ACMatch) = xs[match.s:prevind(xs, match.t)]
