const Td = Dict
const Tf = Float64

struct CykModel
    nrule::Int
    base2::Int
    labelid::Td{String, Int}
    idlabel::Vector{String}
    fa2lr::Vector{Vector{Tuple{Int, Int, Tf}}}
    ss2fa::Vector{Vector{Tuple{Int, Tf}}}
    lr2fa::Td{Int, Vector{Tuple{Int, Tf}}}
    l2far::Vector{Vector{Tuple{Int, Int, Tf}}}
end

function CykModel(ctb::ChTreebank)
    labelid = Td{String, Int}()
    falr = Td{Tuple{Int, Int, Int}, Tf}()
    fass = Td{Tuple{Int, Int}, Tf}()
    function visitor(cur::ChTree)::Nothing
        nchd = length(cur.adj)
        if isleaf(cur) || isposn(cur)
            ;
        elseif nchd == 1
            key = (cur.label, cur.adj[1].label)
            for pos in key if !haskey(labelid, pos) labelid[pos] = length(labelid) + 1 end end
            key = map(x -> labelid[x], key)
            fass[key] = Base.get(fass, key, 0) + 1
        else
            key = (cur.label, cur.adj[1].label, cur.adj[2].label)
            for pos in key if !haskey(labelid, pos) labelid[pos] = length(labelid) + 1 end end
            key = map(x -> labelid[x], key)
            falr[key] = Base.get(falr, key, 0) + 1
        end
        return nothing
    end
    for vt in ctb
        for tree in vt
            tree = cnf(tree)
            dfstraverse(tree, visitor)
        end
    end
    npos = length(labelid)
    base2 = 1; while (1 << base2) <= npos base2 += 1 end;
    # smoothing?
    fatot = Td{Int, Tf}()
    for (key, cnt) in falr
        fa = key[1]
        fatot[fa] = Base.get(fatot, fa, 0) + 1
    end
    for (key, cnt) in fass
        fa = key[1]
        fatot[fa] = Base.get(fatot, fa, 0) + 1
    end
    for (key, cnt) in falr
        fa = key[1]
        prob = -log(cnt / fatot[fa])
        falr[key] = prob
    end
    for (key, cnt) in fass
        fa = key[1]
        prob = -log(cnt / fatot[fa])
        fass[key] = prob
    end
    return CykModel(base2, labelid, falr, fass)
end
import Base.length
length(model::CykModel) = model.nrule

function CykModel(base2::Int, labelid::Td{String, Int}, falr::Td{Tuple{Int, Int, Int}, Tf}, fass::Td{Tuple{Int, Int}, Tf})
    idlabel = Vector{String}(undef, length(labelid))
    for (pos, id) in labelid idlabel[id] = pos end
    lr2fa = Td{Int, Vector{Tuple{Int, Tf}}}()
    for ((fa, l, r), prob) in falr
        lr = (l << base2) + r
        if !haskey(lr2fa, lr) lr2fa[lr] = Vector{Tuple{Int, Tf}}() end
        fas = lr2fa[lr]
        push!(fas, (fa, prob))
    end
    for ((fa, ss), prob) in fass
        if !haskey(lr2fa, ss) lr2fa[ss] = Vector{Tuple{Int, Tf}}() end
        fas = lr2fa[ss]
        push!(fas, (fa, prob))
    end
    nlabel = length(labelid)
    l2far = Vector{Vector{Tuple{Int, Int, Tf}}}(undef, nlabel)
    for i = 1:nlabel l2far[i] = Vector{Tuple{Int, Int, Tf}}() end
    for ((fa, l, r), prob) in falr
        push!(l2far[l], (fa, r, prob))
    end
    fa2lr = Vector{Vector{Tuple{Int, Int, Tf}}}(undef, nlabel)
    for i = 1:nlabel fa2lr[i] = Vector{Tuple{Int, Int, Tf}}() end
    for ((fa, l, r), prob) in falr
        push!(fa2lr[fa], (l, r, prob))
    end
    ss2fa = Vector{Vector{Tuple{Int, Tf}}}(undef, nlabel)
    for i = 1:nlabel ss2fa[i] = Vector{Tuple{Int, Tf}}() end
    for ((fa, ss), prob) in fass
        push!(ss2fa[ss], (fa, prob))
    end
    return CykModel(length(falr), base2, labelid, idlabel, fa2lr, ss2fa, lr2fa, l2far)
end

import Base: read, write, ==
==(x::CykModel, y::CykModel) = length(x) == length(y) && x.idlabel == y.idlabel && x.base2 == y.base2 && x.fa2lr == y.fa2lr && x.ss2fa == y.ss2fa

function read(io::IO, ::Type{CykModel})
    base2 = 0; labelid = Td{String, Int}(); lr2fa = Td{Int, Td{Int, Tf}}()
    fa2lr = Td{Tuple{Int, Int, Int}, Tf}()
    fa2ss = Td{Tuple{Int, Int}, Tf}()

    for line in eachline(io)
        cells = split(line); ncell = length(cells)
        if ncell == 1 base2 = parse(Int, cells[1]) end
        if ncell == 2 labelid[cells[1]] = parse(Int, cells[2]) end
        if ncell == 3
            fa = parse(Int, cells[1])
            ss = parse(Int, cells[2])
            prob = parse(Tf, cells[2])
            fa2ss[(fa, ss)] = prob
        end
        if ncell == 4
            fa = parse(Int, cells[1])
            l = parse(Int, cells[2])
            r = parse(Int, cells[3])
            prob = parse(Tf, cells[4])
            fa2lr[(fa, l, r)] = prob
        end
    end
    return CykModel(base2, labelid, fa2lr, fa2ss)
end

function write(io::IO, obj::CykModel)
    println(io, obj.base2)
    for (pos, id) in obj.labelid
        println(io, pos, " ", id)
    end
    for (falr, prob) in obj.fa2lr
        fa = falr[1]; l = falr[2]; r = falr[3];
        println(io, fa, " ", l, " ", r, " ", prob)
    end
    for (fass, prob) in obj.fa2ss
        fa = fass[1]; ss = fass[2];
        println(io, fa, " ", ss, " ", prob)
    end
end

import Base.get

const single = Td{String, Tf}()
get(model::CykModel, l::Int, r::Int) = get(model.lr2fa, (l << model.base2) + r, single)
get(model::CykModel, ss::Int) = get(model.lr2fa, ss, single)

function cyk(poswords::Vector{Tuple{String, String}}, model::CykModel)
    nrule = model.nrule
    labelid = model.labelid
    fa2lr = model.fa2lr
    ss2fa = model.ss2fa
    l2far = model.l2far
    nlabel = length(labelid)
    nword = length(poswords)
    Tf = Float64
    Td = Dict{Int, Tf}
    dp = Matrix{Td}(undef, nword, nword)
    Td2 = Dict{Int, Union{Tuple{Int, Int, Int}, Tuple{Int, Int}, Tuple{String}}}
    nx = Matrix{Td2}(undef, nword, nword)
    @inbounds begin
        for len = 1:nword
            @show len
            for i = 1:nword - len + 1
                res = Td()
                res2 = Td2()
                if len == 1
                    pos = labelid[poswords[i][1]]
                    res[pos] = 0.0
                    res2[pos] = (poswords[i][2],)
                else
                    for k = 1:len - 1
                        dpl = dp[i, k]; dpr = dp[i + k, len - k]
                        # @show length(dpl) * length(dpr), length(model.fa2lr)
                        if length(dpl) * length(dpr) << 1 >= nrule
                            # if false
                            for fa = 1:nlabel
                                for (l, r, prob) in fa2lr[fa]
                                    if haskey(dpl, l) && haskey(dpr, r)
                                        old = get(res, fa, Inf)
                                        lp = dpl[l]
                                        rp = dpr[r]
                                        new = lp + rp + prob
                                        if new < old
                                            res[fa] = new
                                            res2[fa] = (l, r, k)
                                        end
                                    end
                                end
                            end
                        else
                            for (l, pl) in dpl
                                for (fa, r, prob) in l2far[l]
                                    if haskey(dpr, r)
                                        old = get(res, fa, Inf)
                                        new = pl + dpr[r] + prob
                                        if new < old
                                            res[fa] = new
                                            res2[fa] = (l, r, k)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                while true
                    upd = false
                    for (ss, pss) in res
                        for (fa, prule) in ss2fa[ss]
                            old = get(res, fa, Inf)
                            new = prule + pss
                            if new < old res[fa] = new; res2[fa] = (ss, len); upd = true end
                        end
                    end
                    if !upd break end
                end
                dp[i, len] = res
                nx[i, len] = res2
            end
        end
    end
    start = findmin(dp[1, nword])
    function dfs(s, o, ilabel)::ChTree
        cur = ChTree(model.idlabel[ilabel], ChTree[])
        nxt = nx[s, o][ilabel]; nnxt = length(nxt)
        if nnxt == 1
            push!(cur.adj, ChTree(nxt[1], ChTree[]))
        elseif nnxt == 2
            push!(cur.adj, dfs(s, o, nxt[1]))
        else
            no = nxt[3]
            push!(cur.adj, dfs(s, no, nxt[1]))
            push!(cur.adj, dfs(s + no, o - no, nxt[2]))
        end
        return cur
    end
    return (start[1], dfs(1, nword, start[2]))
end
