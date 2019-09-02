
const Tv = Float64
const Ti = UInt32

mutable struct HMM
    dict::AhoCorasickAutomaton{Ti}
    words::Vector{String}
    user_words::Int
    tags::Vector{String}
    hpr::Vector{Tv}
    h2h::Matrix{Tv}
    h2v::Vector{Dict{Int, Tv}}
    INF::Vector{Tv}
end

function HMM(corpus)
        wmp, words, pmp, tags = Dict{String, Int}(), String[], Dict{String, Int}(), String[]
        for doc in corpus, sent in doc, (pos, word) in sent
                if !haskey(wmp, word) wmp[word] = length(wmp) + 1; push!(words, word) end
                if !haskey(pmp, pos) pmp[pos] = length(pmp) + 1; push!(tags, pos) end
        end
        np = length(pmp)
        hpr, h2h, h2v, INF = fill(Tv(0), np), fill(Tv(0), (np, np)), [DefaultDict{Int, Tv}(Tv(0)) for _ in 1:np], fill(Tv(0), np)
        for doc in corpus, sent in doc
                pp = 0
                for (pos, word) in sent
                        iw, ip = wmp[word], pmp[pos]
                        if pp == 0 hpr[ip] += 1 else h2h[pp,ip] += 1 end
                        pp = ip
                        h2v[ip][iw] += 1
                end
        end
        dict = AhoCorasickAutomaton{Ti}(words)
        return HMM(dict, words, 0, tags, hpr, h2h, h2v, INF)
end

function Kong(;user_dict_path="", user_dict_array=[], user_dict_weight=1, EPS::Tv=1e-9)
        file = joinpath(pathof(KongYiji), "..", "..", "data", "hmm.jld2")
        if !isfile(file) file = unzip7(joinpath(pathof(KongYiji), "..", "..", "data", "hmm.jld2.7z")) end
        @assert isfile(file)
        old = load(file)["hmm"]
        if !isfile(user_dict_path) && length(user_dict_array) == 0
                normalize!(old; EPS=EPS)
                return old
        end

        wmp, pmp = str2int(old.words), str2int(old.tags)
        max_cnt_h2v = [maximum(values(vs)) for vs in old.h2v]
        if isfile(user_dict_path)
               for line in eachline(user_dict_path)
                        cells = split(line)
                        word, pos = "", ""
                        if length(cells) > 0 word = cells[1] end
                        if length(cells) > 1 pos = cells[2] end
                        if pos != "" && !haskey(pmp, pos) error("Postag $(pos) not defined") end
                        if word == "" continue end
                        if pos == "" pos = "NR" end  #NOTE default pos NR
                        if !haskey(wmp, word) wmp[word] = length(wmp) + 1; push!(old.words, word); old.user_words += 1 end
                        iw, ip = wmp[word], pmp[pos]
                        old.h2v[ip][iw] = user_dict_weight * max_cnt_h2v[ip]
               end
        end
        if length(user_dict_array) > 0
                pos, word = "", ""
                for cell in user_dict_array
                        if cell isa String
                                word = cell
                        elseif cell isa Tuple || cell isa Pair
                                pos, word = cell
                        else
                                error("Not supported user_dict_array cell type (String || Pair{String, String} || Tuple{String, String})")
                        end
                        if pos == "" pos = "NR" end
                        if !haskey(pmp, pos) error("Postag $(pos) not defined") end
                        if !haskey(wmp, word) wmp[word] = length(wmp) + 1; push!(old.words, word); old.user_words += 1 end
                        iw, ip = wmp[word], pmp[pos]
                        old.h2v[ip][iw] = user_dict_weight * max_cnt_h2v[ip]
                end
        end
        old.dict = AhoCorasickAutomaton{Ti}(old.words)
        normalize!(old; EPS=EPS)
        return old
end

function normalize!(hmm::HMM; EPS::Tv=1e-9)
        xs = hmm.hpr
        xs .+= EPS;
        xs .= log.(xs ./ sum(xs))
        xs = hmm.h2h
        xs .+= EPS;
        xs .= log.(xs ./ sum(xs; dims=2))

        for (ih, vs) in enumerate(hmm.h2v) 
                tot = sum(values(vs)) + EPS * (length(vs) + 1)
                for (k, v) in vs
                        vs[k] = log((v + EPS) / tot) #todo race condition?
                end
                hmm.INF[ih] = log(EPS / tot)
        end
end

function str2int(xs::Vector{String})
        r = Dict{String, Int}()
        for (i, w) in enumerate(xs) r[w] = i end
        return r
end

function (hmm::HMM)(xs::Vector{String})
        nc_max = mapreduce(ncodeunits, max, xs)
        np = length(hmm.hpr)
        @assert np > 0
        dp = fill(Tv(-Inf), (nc_max + 1, np))
        pre = fill((1, 0), (nc_max + 1, np))
        return [hmm(x, dp, pre) for x in xs]
end

function (hmm::HMM)(x::String)
        return hmm([x])[1]
end

function (hmm::HMM)(x::String, dp::Matrix{Tv}, pre::Matrix{Tuple{Int, Int}})
        chrs = codeunits(x) #todo slow?
        vtxs = collect(eachmatch(hmm.dict, chrs))
        sort!(vtxs)
        nv, nc, np = length(vtxs), length(chrs), length(hmm.hpr)
        for i = 1:nc + 1, j in 1:np dp[i,j] = -Inf end
        pv = 1
        dp[1, :] = hmm.hpr
        pre_i = 1
        for i in 1:nc + 1
                if dp[i,1] != -Inf pre_i = i end
                while pv <= nv && vtxs[pv].s < i pv = pv + 1 end
                if !(pv <= nv && vtxs[pv].s == i || i == nc + 1) continue end
                if dp[i, 1] == -Inf
                        #@show i, pre_i
                        for pi = 1:np, pj = 1:np
                                maybe = dp[pre_i, pj] + hmm.INF[pj] + hmm.h2h[pj,pi]
                                if maybe > dp[i, pi] dp[i, pi] = maybe; pre[i, pi] = (pre_i, pj) end
                        end
                end
                while pv <= nv && vtxs[pv].s == i
                        vtx = vtxs[pv]
                        j = i + length(vtx)
                        for pi = 1:np
                                for pj = 1:np
                                        maybe = dp[i, pi] + hmm.h2h[pi,pj] + get(hmm.h2v[pi], vtx.i, hmm.INF[pi])
                                        if maybe > dp[j,pj] dp[j,pj] = maybe; pre[j,pj] = (i, pi) end
                                end
                        end
                        pv = pv + 1
                end
        end
        #===
        @show hmm
        @show maximum(dp[nc + 1, :])
        @show dp
        @show vtxs
        =###
        v = (nc + 1, argmax(dp[nc + 1,:]))
        ret = fill("", 0)
        while v[1] != 1
                pv = pre[v[1],v[2]]
                push!(ret, x[pv[1]:prevind(x, v[1])])
                v = pv
        end
        reverse!(ret)
        return ret
end

function ==(a::HMM, b::HMM)
        return all(fname -> getfield(a, fname) == getfield(b, fname), fieldnames(HMM))
end

#### Interfaces to ChTreebank

function (hmm::HMM)(sent::CtbSentence)
        return hmm(raw(sent))
end

function (hmm::HMM)(doc::CtbDocument)
        return hmm(raw(doc)) #todo split sentences???
end

function (hmm::HMM)(docs::Vector{CtbDocument})
        return hmm([raw(doc) for doc in docs])
end