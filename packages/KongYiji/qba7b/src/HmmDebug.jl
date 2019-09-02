

function (hmm::HMM)(input::String, dlm::String)
        standard = split(input, dlm)
        x = join(standard)
        return hmm(x, standard)
end

function (hmm::HMM)(x::String, standard::Vector)
        chrs = codeunits(x)
        vtxs = collect(eachmatch(hmm.dict, chrs))
        sort!(vtxs)
        nv, nc, np = length(vtxs), length(chrs), length(hmm.hpr)
        dp = fill(-Inf, (nc + 1, np))
        pre = fill((1, 0), (nc + 1, np))
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
        v = (nc + 1, argmax(dp[nc + 1,:]))
        output = fill("", 0)
        while v[1] != 1
                pv = pre[v[1],v[2]]
                push!(output, x[pv[1]:prevind(x, v[1])])
                v = pv
        end
        reverse!(output)
        
        #print debug infos
        println("Standard : " * join(standard, "  "))
        println("Output   : " * join(output, "  "))

        v = (nc + 1, argmax(dp[nc + 1,:]))
        info = Matrix{Any}(undef, (length(x), 5))
        nr = 1
        while v[1] != 1
                pv = pre[v[1],v[2]]
                word, postag, source, prob_h2v, prob_add = "", "", "", 0., 0.

                s, t = pv[1], v[1]
                word = x[s:prevind(x, t)]
                postag_id = pv[2]
                postag = hmm.tags[postag_id]
                word_id = 0
                begin
                        vtx_id = searchsortedfirst(vtxs, ACMatch(s, t, -1))
                        if vtx_id < nv + 1 && vtxs[vtx_id].s == s && vtxs[vtx_id].t == t
                                word_id = vtxs[vtx_id].i
                        end
                        if word_id == 0 source = "algorithm"
                        else source = ifelse(word_id > length(hmm.words) - hmm.user_words, "usr.dict", "CTB")
                        end
                end
                prob_h2v = word_id == 0 ? hmm.INF[postag_id] : hmm.h2v[postag_id][word_id]
                prob_add = dp[v[1],v[2]] - dp[pv[1],pv[2]]
                prob_h2v, prob_add = map(x->trunc(exp(x); digits=6), [prob_h2v, prob_add])
                info[nr,:] = [word, postag, source, prob_h2v, prob_add]
                nr += 1
                v = pv
        end
        nr -= 1
        println(UselessTable(reverse(info[1:nr,:]; dims=1); cnames=["word", "pos.tag", "source", "prob.h2v", "Prob.Add."],
                                         heads=["KongYiji(1) Debug Table",], 
                                         foots=["neg.log.likelihood = $(-maximum(dp[nc + 1,:]))"]
                            )
        )
        match_mat = Matrix{Any}(undef, (nv, 3))
        match_mat[:,1] = [(v.s,v.t) for v in vtxs]
        match_mat[:,2] = [x[v] for v in vtxs]
        match_mat[:,3] = [(v.i > length(hmm.words) - hmm.user_words ? "user.dict" : "CTB") for v in vtxs]
        println(UselessTable(match_mat; cnames=["UInt8.range", "word", "source"], heads=["AhoCorasickAutomaton Matched Words"]))
end