
struct UselessTable
        mat::Matrix{Any}
        heads::Vector{Any}
        foots::Vector{Any}
        useful::Any
end

import Base.show
function show(io::IO, tb::UselessTable)
        compact = get(io, :compact, false)
        dsize = get(io, :displaysize, displaysize())
        limit = get(io, :limit, true)

        offset = "  "
        nrow, ncol = size(tb.mat, 1), size(tb.mat, 2)
        mat = fill("", (nrow, ncol))
        for i in 1:nrow, j in 1:ncol
                if ismissing(tb.mat[i,j]) mat[i,j] = "N/A"
                elseif isnothing(tb.mat[i,j]) mat[i,j] = ""
                else mat[i,j] = string(tb.mat[i,j])
                end
                #todo compact
        end
        colwidth = [maximum(map(textwidth, mat[:,i])) for i in 1:ncol] .+ 1
        for i in 1:nrow, j in 1:ncol
                pad = ifelse(j == 1, rpad, lpad)
                val = mat[i,j]
                val = pad(val, colwidth[j] - textwidth(val) + length(val))
                if j == 1 val = offset * val end
                mat[i,j] = val
        end
        
        function middle(s::String, width::Int)
                r = offset * s
                n = textwidth(r)
                if n < width r = " " ^ div((width - n), 2) * r end
                return r
        end
        function right(s::String, width::Int)
                r = offset * s
                n = textwidth(r)
                if n < width r = " " ^ (width - n) * r end
                return r
        end
 
        totw = sum(colwidth)
        for i in 1:nrow
                #print headers
                if i == 1 && length(tb.heads) > 0
                        for head in tb.heads
                                println(io, middle(string(head), totw))
                        end
                        println(io, middle("-" ^ totw, totw))
                end
                for j in 1:ncol
                        print(io, mat[i,j])
                end
                println(io)
                #print foots
                if i == nrow && length(tb.foots) > 0
                        println(io, middle("=" ^ totw, totw))
                        for foot in tb.foots
                                println(io, right(string(foot), totw))
                        end
                end
        end
end

function UselessTable(mat::Matrix{Tv}; rnames=nothing, cnames=nothing, topleft=nothing, heads=[], foots=[], useful=nothing) where {Tv}
        ncol = size(mat, 2); nrow = size(mat, 1)
        if isnothing(cnames) cnames = 1:ncol end
        if isnothing(rnames) rnames = 1:nrow end
        ncol += 1; nrow += 1
        mat2 = Matrix{Any}(missing, (nrow, ncol))
        mat2[1,1] = topleft
        mat2[1,2:end] .= cnames
        mat2[2:end,1] .= rnames
        for i in 2:nrow, j in 2:ncol
                mat2[i,j] = mat[i-1,j-1]
        end
        return UselessTable(mat2, heads, foots, useful)
end

==(a::UselessTable, b::UselessTable) = a.mat == b.mat

#=
function UselessTable(dict::Dict{Tcname,Dict{Trname, Tv}}; topleft="") where {Tcname, Trname, Tv}
        cnames = Dict{Tcname, Int}(map(reverse, enumerate(keys(dict))))
        rnames = Dict{Trname, Int}()
        for col in values(dict), (rname, cell) in col
                if !haskey(rnames, rname) rnames[rname] = length(rnames) + 1 end
        end
        rnames2 = sort(collect(keys(rnames)), by=x->rnames[x])
        cnames2 = sort(collect(keys(cnames)), by=x->cnames[x])
        ncol = length(cnames) + 1
        nrow = length(rnames) + 1
        mat = Matrix{Any}(missing, (nrow, ncol))
        mat[1,1] = topleft
        mat[1,2:end] .= cnames2
        mat[2:end,1] .= rnames2
        for (cname, col) in dict, (rname, cell) in col
                mat[rnames[rname]+1,cnames[cname]+1] = cell
        end
        return UselessTable(mat, dict)
end
=#
