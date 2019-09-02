
struct HmmScoreTable
        c_cmat::Matrix{Int}   #char level confusion matrix
        c_f1::Vector{Float64} #char level f1 score
        c_p::Vector{Float64}  #char level precision
        c_r::Vector{Float64}  #char level recall
        
        w_f1::Float64         #word level f1 score
        w_p::Float64          #word level precision
        w_r::Float64          #word level recall

        n::Int                #how many tables combined

end

HmmScoreTable(xs::Vector{Vector{String}}, ys::Vector{Vector{String}}) = mapreduce(p->HmmScoreTable(p...), +, zip(xs, ys))
"""
        x : Standard output
        y : KongYiji output
"""
function HmmScoreTable(x::Vector{String}, y::Vector{String})
        #### char level
        # confusion matrix
        c_cmat, c_f1, c_p, c_r = fill(0, (4, 4)), fill(0., 4), fill(0., 4), fill(0., 4)
        idx = Dict(:B=>1, :M=>2, :E=>3, :S=>4)
        nchr = mapreduce(length, +, x)
        xa = fill(:M, nchr)
        p = 1
        for w in x
                nw = length(w)
                xa[p] = :B
                xa[p + nw - 1] = :E
                if nw == 1 xa[p] = :S end
                p += nw
        end
        ya = fill(:M, nchr)
        p = 1
        for w in y
                nw = length(w)
                ya[p] = :B
                ya[p + nw - 1] = :E
                if nw == 1 ya[p] = :S end
                p += nw
        end
        for i = 1:nchr c_cmat[idx[ya[i]],idx[xa[i]]] += 1 end
        # precision, recall, f1-score
        c_f1, c_p, c_r = fill(0., 4), fill(0., 4), fill(0., 4)
        for i = 1:4
                num, den = c_cmat[i,i], sum(c_cmat[i,:]) 
                c_p[i] = num == den ? 1. : (0. + num) / den
                num, den = c_cmat[i,i], sum(c_cmat[:,i]) 
                c_r[i] = num == den ? 1. : (0. + num) / den
                c_f1[i] = f1(c_p[i], c_r[i])
        end

        ##### word level
        ix, iy, px, py, nx, ny, r = 1, 1, 1, 1, length(x), length(y), 0.
        while ix <= nx && iy <= ny
                if px == py
                        if x[ix] == y[iy] r += 1 end
                        nxi, nyi = length(x[ix]), length(y[iy])
                        if nxi == nyi px += nxi; py += nyi; ix += 1; iy += 1
                        elseif nxi < nyi px += nxi; ix += 1
                        else py += nyi; iy += 1
                        end
                elseif px < py
                        while px < py && ix <= nx px += length(x[ix]); ix += 1 end
                else
                        while py < px && iy <= ny py += length(y[iy]); iy += 1 end
                end
        end
        w_p = r / length(y)
        w_r = r / length(x)
        w_f1 = f1(w_p, w_r)
        return HmmScoreTable(c_cmat, c_f1, c_p, c_r, w_f1, w_p, w_r, 1)
end

+(a::HmmScoreTable, b::HmmScoreTable) = HmmScoreTable(map(x->getfield(a, x) + getfield(b, x), fieldnames(HmmScoreTable))...)

function show(io::IO, tb::HmmScoreTable)
        n = size(tb.c_cmat, 1)
        fm(d) = string(trunc(d * 100, sigdigits=3), "%")
        fm1(d) = trunc(d, sigdigits=5)
        char_f1, char_p, char_r = map(x->x / tb.n, [tb.c_f1, tb.c_p, tb.c_r])
        word_f1, word_p, word_r = map(x->x / tb.n, [tb.w_f1, tb.w_p, tb.w_r])
        mat = Array{Any}(missing, (n + 4, n + 1))
        mat[1:n,1:n] .= tb.c_cmat              
        mat[n + 1,1:n] .= sum(tb.c_cmat, dims=1)[1,:]
        mat[1:n,n + 1] .= sum(tb.c_cmat, dims=2)[:,1]
        mat[n + 1,n + 1] = sum(tb.c_cmat)
        mat[n + 2,1:n] .= fm.(char_p); mat[n + 2,n + 1] = ""
        mat[n + 3,1:n] .= fm.(char_r); mat[n + 3,n + 1] = ""
        mat[n + 4,1:n] .= fm1.(char_f1); mat[n + 4,n + 1] = ""
        char_avg_f1, char_avg_p, char_avg_r = map(x->sum(x)/length(x), [char_f1, char_p, char_r])

        utb = UselessTable(mat; cnames=(:B, :M, :E, :S, ""), 
                                rnames=(:B, :M, :E, :S, "", :Precision, :Recall, :F1), 
                                topleft="O\\S", 
                                foots=["Char level avg.F1: $(fm1(char_avg_f1)), avg.precison: $(fm(char_avg_p)), avg.recall: $(fm(char_avg_r))",
                                      "Word level F1: $(fm1(word_f1)), precison: $(fm(word_p)), recall: $(fm(word_r))",
                                ],
                                heads=["KongYiji(1) HMM Score Table $(tb.n) combined"],
        )
        show(io, utb)
end

f1(x, y) = 2 / (1. / x + 1. / y)

############ Interfaces to ChTreebank 
HmmScoreTable(xs::Vector{CtbDocument}, ys::Vector{Vector{String}}) = HmmScoreTable(map(tokens, xs), ys)
