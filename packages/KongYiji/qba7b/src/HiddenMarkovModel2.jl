###### legacy codes


function splits(text::AbstractString, obj::HiddenMarkovModel; ntrial = 2, pos = true)
    codes = codeunits(text)
    aca = obj.aca; pos = obj.pos;
    hpr = obj.hpr; h2h = obj.h2h;
    alpha = obj.alpha; h2v = obj.h2v;
    positions = collect(eachmatch(aca, text))
    if (length(positions) == 0) return [String(text)] end
    ncode = length(codes); npos = length(pos);
    dp = Array{Float64, 3}(undef, ntrial, npos, ncode + 1); dp .= 1.0 / 0.0; dp[1, 1, ncode + 1] = 0.0;
    nx = Array{Tuple{Int, Int, Int}, 3}(undef, ntrial, npos, ncode + 1)
    j = length(positions)
    charindexes = collect(eachindex(text)); push!(charindexes, ncode + 1);
    k = nchar = length(charindexes) - 1
    for i = ncode:-1:1
        while j > 0 && i < positions[j].t j -= 1 end
        while j > 0 && i == positions[j].t
            iword = positions[j].i
            s = positions[j].s
            t = positions[j].t
            for ipos = 1:npos
                res = view(dp, :, ipos, s)
                H2V = get(h2v[ipos], iword, alpha[ipos])
                nxt = view(nx, :, ipos, s)
                for ipos2 = 1:npos
                    for itrial2 = 1:ntrial
                        cur = H2V + h2h[ipos2, ipos] + dp[itrial2, ipos2, t + 1]
                        for itrial = 1:ntrial
                            if cur < res[itrial]
                                res[itrial + 1:end] .= res[itrial:end - 1]
                                nxt[itrial + 1:end] .= nxt[itrial:end - 1]
                                res[itrial] = cur
                                nxt[itrial] = (itrial2, ipos2, t)
                                # @show itrial, ipos, s, itrial2, ipos2, t + 1
                                break
                            end
                        end
                    end
                end
            end
            j -= 1
        end
        if i == charindexes[k]
            iword = 0
            s = i
            t = charindexes[k + 1] - 1
            for ipos = 1:npos
                res = view(dp, :, ipos, s)
                H2V = get(h2v[ipos], iword, alpha[ipos])
                nxt = view(nx, :, ipos, s)
                for ipos2 = 1:npos
                    for itrial2 = 1:ntrial
                        cur = H2V + h2h[ipos2, ipos] + dp[itrial2, ipos2, t + 1]
                        for itrial = 1:ntrial
                            if cur < res[itrial]
                                res[itrial + 1:end] .= res[itrial:end - 1]
                                nxt[itrial + 1:end] .= nxt[itrial:end - 1]
                                res[itrial] = cur
                                nxt[itrial] = (itrial2, ipos2, t)
                                break
                            end
                        end
                    end
                end
            end
            k -= 1
        end
    end
    # dp[:, :, 1] .+= hpr
    for i = 1:ntrial dp[i, :, 1] .+= hpr end
    res = Vector()
    dp1 = dp[:, :, 1]
    for i = 1:ntrial
        minind = findmin(dp1)[2]
        dp1[minind] = 1.0 / 0.0
        itrial = minind[1]
        ipos = minind[2]
        pvis = 1
        segs = Vector{Tuple{String, String}}()
        while pvis <= ncode
            # @show nx[ipos, pvis]
            nxt = nx[itrial, ipos, pvis]
            itrial2 = nxt[1]
            ipos2 = nxt[2]
            pvis2 = nxt[3]
            push!(segs, (pos[ipos], String(codes[pvis:pvis2])))
            itrial = itrial2
            ipos = ipos2
            pvis = pvis2 + 1
        end
        push!(res, segs)
    end
    push!(res, dp[:, :, 1])
    push!(res, nx[:, :, 1])
    return res
end
