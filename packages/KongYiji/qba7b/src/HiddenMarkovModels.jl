###### legacy codes


struct HiddenMarkovModel{Tv <: AbstractFloat, Ti <: Integer}
    aca::AhoCorasickAutomaton{Ti}
    pos::Vector{String}
    hpr::Vector{Tv}
    h2h::Matrix{Tv}
    h2v::Vector{Dict{Int, Tv}}
    MAX::Tv
    sumhpr::Tv
    sumh2hdim1::Matrix{Tv}
    sumh2vdimv::Vector{Tv}
end

function HiddenMarkovModel{Tv, Ti}(;
    model::Union{String, Nothing} = joinpath(dirname(pathof(ChineseTokenizers)), "..", "chmm"),
    poswords::Union{String, Nothing} = nothing,
    userdict::Union{String, Nothing} = nothing) where {Tv, Ti}
    if model == nothing
        @assert poswords != nothing "poswords must not be nothing."
        dict = Dict{String, Int}()
        if userdict != nothing
            open(userdict, "r") do io
                for line in eachline(io)
                    cells = split(line, " ")
                    word = String(cells[1])
                    if !haskey(dict, word)
                        dict[word] = length(dict) + 1
                    end
                end
            end
        end
        poss = Dict{String, Int}()
        hpr = Tv[]
        h2h = Dict{Int, Tv}[]
        h2v = Dict{Int, Tv}[]
        open(poswords, "r") do io
            for line in eachline(io)
                nword = parse(Int, line)
                if nword <= 0 continue end
                poswords = Vector{Tuple{String, String}}()
                tmp = nword
                for line2 in eachline(io)
                    cells = split(line2)
                    pos  = String(split(cells[1], "-")[1])
                    word = String(cells[2])
                    push!(poswords, (pos, word))
                    tmp -= 1
                    if tmp == 0 break end
                end
                # hpr, h2h, h2v
                for i = 1:nword
                    pos  = poswords[i][1]
                    word = poswords[i][2]
                    ih = get(poss, pos, length(poss) + 1)
                    if ih == length(poss) + 1
                        poss[pos] = ih
                        push!(hpr, 0)
                        push!(h2h, Dict{Int, Tv}())
                        push!(h2v, Dict{Int, Tv}())
                    end
                    iw = get(dict, word, length(dict) + 1)
                    if iw == length(dict) + 1
                        dict[word] = iw
                    end
                    if i == 1 hpr[ih] += 1 end
                    if i > 1
                        ph = poss[poswords[i - 1][1]]
                        if !haskey(h2h[ph], ih) h2h[ph][ih] = 0 end
                        h2h[ph][ih] += 1
                    end
                    if !haskey(h2v[ih], iw) h2v[ih][iw] = 0 end
                    h2v[ih][iw] += 1
                end
            end
        end
        nword = length(dict)
        aca = AhoCorasickAutomaton{Ti}(dict; sort = true)
        npos = length(poss);
        pos = Vector{String}(undef, npos)
        for (p, i) in poss pos[i] = p end
        sumhpr = norm!(hpr)
        h2h2 = zeros(Tv, npos, npos)
        for (ih, hs) in enumerate(h2h)
            for (ih2, cnt) in hs
                h2h2[ih2, ih] += cnt
            end
        end
        sumh2hdim1 = norm!(h2h2)
        sumh2vdimv = norm!(h2v)
        MAX = mapreduce(x -> maximum(values(x)), max, h2v)
        return HiddenMarkovModel{Tv, Ti}(aca, pos, hpr, h2h2, h2v, MAX, sumhpr, sumh2hdim1, sumh2vdimv)
    else
        old = open(model, "r") do io read(io, HiddenMarkovModel) end
        if poswords == nothing && userdict == nothing return old end
        dict = Dict(collect(old.aca))
        posid = Dict{String, Int}(); for (id, pos) in enumerate(old.pos) posid[pos] = id end
        hpr = denorm!(old.hpr, old.sumhpr)
        h2h = denorm!(old.h2h, old.sumh2hdim1)
        h2v = denorm!(old.h2v, old.sumh2vdimv)
        if userdict != nothing
            open(userdict, "r") do io
                for line in eachline(io)
                    cells = split(line)
                    word = cells[1]
                    pos  = length(cells) > 1 ? cells[2] : "NN"
                    iw   = get(dict, word, length(dict) + 1)
                    if iw == length(dict) + 1 dict[word] = iw end
                    ih   = get(posid, pos, 0)
                    @assert ih != 0 "Userdict contains an unrecognizable POS - " * pos
                    if !haskey(h2v[ih], iw) h2v[ih][iw] = 0 end
                    h2v[ih][iw] += 1
                end
            end
        end
        if poswords != nothing
            open(poswords, "r") do io
                for line in eachline(io)
                    nword = parse(Int, line)
                    ph = 0
                    for i = 1:nword
                        cells = split(readline(io))
                        pos  = cells[1]
                        word = cells[2]
                        iw   = get(dict, word, length(dict) + 1)
                        if iw == length(dict) + 1 dict[word] = iw end
                        ih   = get(posid, pos, 0)
                        @assert ih != 0 "Poswords contains an unrecognizable POS - " * pos
                        if !haskey(h2v[ih], iw) h2v[ih][iw] = 0 end
                        h2v[ih][iw] += 1
                        if i == 1 hpr[ih] += 1 end
                        if i >  1 h2h[ih, ph] += 1 end
                        ph = ih
                    end
                end
            end
        end
        nword = length(dict)
        aca = AhoCorasickAutomaton{Ti}(dict; sort = true)
        pos = Vector{String}(undef, length(posid)); for (p, id) in posid pos[id] = p end
        sumhpr     = norm!(hpr)
        sumh2hdim1 = norm!(h2h)
        sumh2vdimv = norm!(h2v)
        MAX = mapreduce(x -> maximum(values(x)), max, h2v)
        return HiddenMarkovModel{Tv, Ti}(aca, pos, hpr, h2h, h2v, MAX, sumhpr, sumh2hdim1, sumh2vdimv)
    end
end

HiddenMarkovModel() = HiddenMarkovModel{Float32, Int32}(;)

function display(obj::HiddenMarkovModel{Tv, Ti}) where Tv where Ti
    title = string(typeof(obj), " ", (nword = length(obj.aca), npos = length(obj.pos), nbyte = Base.format_bytes(Base.summarysize(obj))))
    println(title)
    rows = Any[["POS", "nhead", "tot", "unique", "examples"]]
    description = stat(obj)
    for i = 1:length(obj.pos)
        r = description[i]
        push!(rows, [r.pos, r.nhead, r.tot, length(r.vs), r.pos == "URL" ? "Omitted." : string(r.vs[1:min(5, end)])])
    end
    return display(Markdown.MD(Markdown.Table(rows, Symbol[:l, :r, :r, :r, :l])))
end

function split(text::AbstractString, obj::HiddenMarkovModel{Tv, Ti}) where {Tv, Ti}
    codes = codeunits(text)
    nc = length(codes)
    aca = obj.aca; pos = obj.pos;
    hpr = obj.hpr; h2h = obj.h2h;
    INF = obj.MAX * nc; h2v = obj.h2v;
    matches = collect(eachmatch(aca, text))
    sort!(matches)
    nm = length(matches)
    nh = length(pos)
    dp = fill(Tv(Inf), nh, nc)
    bk = fill((0, 0), nh, nc)
    cover = fill(false, nc)
    for m in matches cover[m.s:m.t] .= true end
    pm = 1
    sc = 1
    while sc <= nc
        if !cover[sc]
            tc = sc + 1
            while tc <= nc && !cover[tc] tc += 1 end
            tc -= 1
            for sh in 1:nh
                for th in 1:nh
                    cur = (sc == 1 ? hpr[sh] : dp[sh, sc - 1]) + h2h[th, sh] + get(h2v[th], 0, INF)
                    if cur < dp[th, tc]
                        dp[th, tc] = cur
                        bk[th, tc] = (-sh, sc - 1)
                    end
                end
            end
            sc = tc + 1
        else
            while pm <= nm && matches[pm].s < sc pm += 1 end
            while pm <= nm && matches[pm].s == sc
                m = matches[pm]
                tc = m.t
                iw = m.i
                for sh in 1:nh
                    for th in 1:nh
                        cur = (sc == 1 ? hpr[sh] : dp[sh, sc - 1]) + h2h[th, sh] + get(h2v[th], iw, INF)
                        if cur < dp[th, tc]
                            dp[th, tc] = cur
                            bk[th, tc] = (sh, sc - 1)
                        end
                    end
                end
                pm += 1
            end
            sc += 1
        end
    end
    poss = String[]
    word = String[]
    th = findmin(dp[:, nc])[2]
    tc = nc
    while 1 <= tc
        sh = bk[th, tc][1]
        sc = bk[th, tc][2]
        if sh < 1
            sh = -sh
            push!(poss, pos[th] * "?")
            push!(word, String(codes[sc + 1:tc]))
        else
            push!(poss, pos[th])
            push!(word, String(codes[sc + 1:tc]))
        end
        th = sh
        tc = sc
    end
    reverse!(poss)
    reverse!(word)
    # return (res = segs, dp = dp, segs = map(x -> String(codes[x.s:x.t]), matches))
    return hcat(poss, word)
end
