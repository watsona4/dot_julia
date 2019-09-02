
struct CtbSentence
        tree::Vector{Char}
        postags::Vector{Pair{String, String}}
end

struct CtbDocument
        type::String
        sents::Vector{CtbSentence}
end

struct CtbTag
        name::String
        description::String
        example::Vector{String}
end

"Chinese Treebank 8.0 of 3,007 docs, 71,369 sentences, 1,620,561 words and 2,589,848 characters (hanzi or foreign)"
struct ChTreebank
        docs::Vector{CtbDocument}
end

function ChTreebank(home::String; nf=0)
        home_data = joinpath(home, "data", "bracketed")
        if (nf <= 0) nf = length(readdir(home_data)) end
        docs = Vector{CtbDocument}(undef, nf)
        @showprogress 1 "Parsing ChTreebank..." for (i, file_name) in enumerate(readdir(home_data))
                if i > nf break end
                type = ""
                id = parse(Int, file_name[6:9])
                if 0001<=id<=0325 || 0400<=id<=0454 || 0500<=id<=0540 || 0600<=id<=0885 || 0900<=id<=0931 || 4000<=id<=4050 type = "Newwire"
                elseif 0590<=id<=0596 || 1001<=id<=1151 type = "Magazine articles"
                elseif 2000<=id<=3145 || 4051<=id<=4111 type = "Broadcast news"
                elseif 4112<=id<=4197 type = "Broadcast conversations"
                elseif 4198<=id<=4411 type = "Weblogs"
                elseif 5000<=id<=5558 type = "Discussion forums"
                else type = "N/A"
                end
                trees = parsectbfile(joinpath(home_data, file_name))
                sents = [CtbSentence(tree, postags(CtbTree(tree))) for tree in trees]
                docs[i] = CtbDocument(type, sents)
        end
        return ChTreebank(docs)
end

Base.length(sent::CtbSentence) = length(sent.postags)
Base.length(doc::CtbDocument) = length(doc.sents)
Base.length(ctb::ChTreebank) = length(ctb.docs)
Base.getindex(sent::CtbSentence, inds...) = getindex(sent.postags, inds...)
Base.getindex(doc::CtbDocument, inds...) = getindex(doc.sents, inds...)
Base.getindex(ctb::ChTreebank, inds...) = getindex(ctb.docs, inds...)
Base.iterate(sent::CtbSentence, state=1) = state > length(sent) ? nothing : (sent.postags[state], state + 1)
Base.iterate(doc::CtbDocument, state=1) = state > length(doc) ? nothing : (doc.sents[state], state + 1)
Base.iterate(ctb::ChTreebank, state=1) = state > length(ctb) ? nothing : (ctb.docs[state], state + 1)

function Base.summary(ctb::ChTreebank)
        ndoc = length(ctb.docs)
        nsent = sum(map(doc -> length(doc.trees), ctb.docs))
        nword = sum(map(doc -> sum(map(length, doc.postags)), ctb.docs))
        return "CTB($(ndoc) D. $(nsent) S. $(nword) W.)"
end

mutable struct Block
    chrs::Vector{Char}
    nlb::Int
end

function Block()
        chrs = Char[]
        sizehint!(chrs, 100)
        #resize!(chrs, 100)
        return Block(chrs, 0)
end

function push!(b::Block, chrs::Vector{Char})
    for c in chrs
        if c == '('
            b.nlb += 1
        elseif c == ')'
            b.nlb -= 1
        end
        push!(b.chrs, c)
    end
end

function text(b::Block)
        resize!(b.chrs, length(b.chrs));
        return b.chrs
end

function ok(block::Block)
    return block.nlb == 0
end

function parsectbfile(file_path)
        ret = Vector{Char}[]
        b = Block()
        open(file_path, "r") do io
            for line in eachline(io)
                if startswith(line, "(")
                    push!(b, collect(line))
                    if !ok(b)
                        for line in eachline(io)
                            push!(b, collect(line))
                            if ok(b) break end
                        end
                    end
                    push!(ret, text(b))
                    b = Block()
                end
            end
        end
        return ret
end

text(tree::CtbTree) = tree.label
ispostag(tree::CtbTree) = length(tree.adj) == 1 && isleaf(tree.adj[1])

function postags(sent::CtbTree)
        ret = Pair{String, String}[]
        visitor(tree::CtbTree) = if ispostag(tree) && text(tree) != "-NONE-" push!(ret, text(tree)=>text(tree.adj[1])) end
        dfstraverse(sent, visitor)
        return ret
end

postags(doc::CtbDocument) = Iterators.flatten(doc)

function tokens(sent::CtbTree)
        ret = String[]
        visitor(tree::CtbTree) = if ispostag(tree) && text(tree) != "-NONE-" push!(ret, text(tree.adj[1])) end
        dfstraverse(sent, visitor)
        return ret
end

tokens(sent::CtbSentence) = map(last, sent)
tokens(doc::CtbDocument) = mapreduce(tokens, append!, doc)

raw(sent::CtbSentence) = mapreduce(last, *, sent) #todo speed up
raw(doc::CtbDocument) = mapreduce(raw, *, doc)


function ==(a::ChTreebank, b::ChTreebank)
        return all(fname -> getfield(a, fname) == getfield(b, fname), fieldnames(ChTreebank))
end

function ==(a::CtbDocument, b::CtbDocument)
        return all(fname -> getfield(a, fname) == getfield(b, fname), fieldnames(CtbDocument))
end

function ==(a::CtbSentence, b::CtbSentence)
        return all(fname -> getfield(a, fname) == getfield(b, fname), fieldnames(CtbSentence))
end

function split(ctb::ChTreebank; percents::Vector{Float64}=[0.7, 0.2, 0.1])
        percents ./= sum(percents)
        n = length(ctb)
        caps = map(p -> floor(p * n), percents)
        caps[3] += n - sum(caps)
        idx = randperm(n)
        train = ChTreebank(ctb.tags, ctb.docs[1:caps[1]])
        dev = ChTreebank(ctb.tags, ctb.docs[caps[1]+1:caps[1]+caps[2]])
        test = ChTreebank(ctb.tags, ctb.docs[end-caps[3]+1:end])
        return (train, dev, test)
end

import Base.+
function kfolds(docs; k::Int=10)
        groups = DefaultDict{String, Vector{CtbDocument}}(()->CtbDocument[])
        for doc in docs push!(groups[doc.type], doc) end
        k = min(k, mapreduce(length, max, values(groups)))
        @assert 2 <= k
        r = [CtbDocument[] for _ in 1:k]
        for (ig, group) in enumerate(values(groups))
                ng = length(group)
                kg = min(ng, k)
                idx = randperm(ng)
                from = 1
                for i in 1:k
                        sz = div(ng, kg) + (i <= ng % kg ? 1 : 0)
                        to = from + sz - 1
                        append!(r[i], group[idx[from:to]])
                        from = to + 1
                end
                @assert from == ng + 1
        end
        return r
end



function postable()
        tsv = readdlm(joinpath(pathof(KongYiji), "..", "..", "data", "postable.tsv"), '\t', String)
        return UselessTable(tsv[2:end,:]; cnames=tsv[1,:], heads=["CTB postable"])
end