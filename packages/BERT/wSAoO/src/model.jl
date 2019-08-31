# import Base: *
# import Knet: getindex, setindex!

# Matmuls 2d and 3d arrays
# function *(a::AbstractArray{T,2}, b::AbstractArray{T,3}) where T<:Real
#     b_sizes = size(b)
#     a = a * reshape(b, b_sizes[1], :)
#     return reshape(a, :, b_sizes[2:end]...)
# end

# Matmuls 2d and 3d arrays for KnetArrays
# function *(a::KnetArray{T,2}, b::KnetArray{T,3}) where T<:Real
#     b_sizes = size(b)
#     a = a * reshape(b, b_sizes[1], :)
#     return reshape(a, :, b_sizes[2:end]...)
# end

# TODO :
# Since backprop doesn't work with this new import, we define it as a complex function consisting primitives that Autograd can take derivatives of. A primitive derivative of this function would speed things up.
# function matmul23(a::KnetArray{T,2}, b::KnetArray{T,3}) where T<:Real
#     b_sizes = size(b)
#     a = a * reshape(b, b_sizes[1], :)
#     return reshape(a, :, b_sizes[2:end]...)
# end

gelu(x) = x .* 0.5 .* (1.0 .+ erf.(x ./ sqrt(2.0)))

function matmul23(a, b)
    b_sizes = size(b)
    a = a * reshape(b, b_sizes[1], :)
    return reshape(a, :, b_sizes[2:end]...)
end

# Wrote these first, then realized we don't need them. Might come in handy later.
# function matmul23(a::AbstractArray{T,2}, b::AbstractArray{T,3}) where T<:Real
#     b_sizes = size(b)
#     a = a * reshape(b, b_sizes[1], :)
#     return reshape(a, :, b_sizes[2:end]...)
# end

# function matmul23(a::Param{KnetArray{T,2}}, b::KnetArray{T,3}) where T<:Real
#     matmul23(value(a), b)
# end

# function matmul23(a::Param{AbstractArray{T,2}}, b::AbstractArray{T,3}) where T<:Real
#     matmul23(value(a), b)
# end

# function matmul23(a::Param{KnetArray{T,2}}, b::AutoGrad.Result{KnetArray{T,3}}) where T<:Real
#     matmul23(value(a), value(b))
# end

# function matmul23(a::Param{AbstractArray{T,2}}, b::AutoGrad.Result{AbstractArray{T,3}}) where T<:Real
#     matmul23(value(a), value(b))
# end

# @primitive *(x1::KnetArray{T,2},x2::KnetArray{T,3}),dy    

# Not using this anymore
# function getindex(A::KnetArray{Float32,3}, ::Colon, I::Real, ::Colon)
#     sizes = size(A)
#     A = reshape(A, :, sizes[3])
#     return A[(I-1)*sizes[1]+1:I*sizes[1],:]
# #    reshape(A, :, size(A,3))[(I-1)*size(A,1)+1:I*size(A,1),:]
# end

# Does not work
# function setindex!(A::KnetArray{Float32,3}, v, ::Colon, I::Real, ::Colon)
#     A = reshape(A, :, size(A,3))
# #     setindex!(A, v, (I-1)*size(A,1)+1:I*size(A,1), ::Colon)
#     A[(I-1)*size(A,1)+1:I*size(A,1),:] = v
# end

# std doesn't work!
std2(a, μ, ϵ) = sqrt.(Knet.mean(abs2.(a .- μ), dims=1) .+ ϵ)

# Legend
# V -> Vocab size, E -> Embedding size, S -> Sequence length, B -> Batch size
# H -> head_size, N -> num_heads

abstract type Layer end

# MAYBE TODO : sin-cos positionwise embeddings. This will reduce model size by max_seq_len * E

mutable struct Embedding <: Layer
    w
end

Embedding(vocabsize::Int,embed::Int; atype=Array{Float32}) = Embedding(param(embed,vocabsize, atype=atype))

function (e::Embedding)(x)
    e.w[:,x]
end

# If we need 0's as pads
#=
struct SegmentEmbedding <: Layer
    w
    atype
end

SegmentEmbedding(vocabsize::Int,embed::Int; atype=Array{Float32}) = SegmentEmbedding(param(embed,vocabsize, atype=atype), atype)

function (e::SegmentEmbedding)(x)
    x != 0 ? e.w[:,x] : e.atype(zeros(size(e.w,1)))
end
=#

mutable struct Linear <: Layer
    w
    b
end

Linear(input_size::Int, output_size::Int; atype=Array{Float32}) = Linear(param(output_size, input_size, atype=atype), param0(output_size, atype=atype))

function (l::Linear)(x)
    return l.w * x .+ l.b
end

mutable struct Linear3D <: Layer
    w
    b
end

Linear3D(input_size::Int, output_size::Int; atype=Array{Float32}) = Linear3D(param(output_size, input_size, atype=atype), param0(output_size, atype=atype))

function (l::Linear3D)(x)
    return matmul23(l.w, x) .+ l.b
end

# Absolutely no difference between Dense and Linear! Except one has dropout and activation function.
mutable struct Dense <: Layer
    linear
    pdrop
    func
end

function Dense(input_size::Int, output_size::Int; pdrop=0.0, func=identity, atype=Array{Float32}, threeD=false)
    if threeD
        return Dense(Linear3D(input_size, output_size, atype=atype), pdrop, func)
    else
        return Dense(Linear(input_size, output_size, atype=atype), pdrop, func)
    end
end

function (a::Dense)(x)
    return a.func.(dropout(a.linear(x), a.pdrop))
end

mutable struct LayerNormalization <: Layer
    γ
    β
    ϵ
end

LayerNormalization(hidden_size::Int; epsilon=1e-12, atype=Array{Float32}) = LayerNormalization(Param(atype(ones(hidden_size))), param0(hidden_size, atype=atype), epsilon)

function (n::LayerNormalization)(x)
    μ = Knet.mean(x, dims=1)
    x = (x .- μ) ./ std2(x, μ, n.ϵ) # corrected=false for n
    return n.γ .* x .+ n.β
end

mutable struct EmbedLayer <: Layer
    wordpiece::Embedding
    positional::Embedding
#    segment::SegmentEmbedding
    segment::Embedding
    layer_norm::LayerNormalization
    seq_len::Int
    pdrop
end

function EmbedLayer(config)
    wordpiece = Embedding(config.vocab_size, config.embed_size, atype=config.atype)
    positional = Embedding(config.max_seq_len, config.embed_size, atype=config.atype)
    #segment = SegmentEmbedding(config.num_segment, config.embed_size, atype=config.atype)
    segment = Embedding(config.num_segment, config.embed_size, atype=config.atype)
    layer_norm = LayerNormalization(config.embed_size, atype=config.atype)
    return EmbedLayer(wordpiece, positional, segment, layer_norm, config.seq_len, config.pdrop)
end

function (e::EmbedLayer)(x, segment_ids) # segment_ids are SxB, containing 1 or 2, or 0 in case of pads.
    x = e.wordpiece(x)
    positions = zeros(Int64, e.seq_len, size(x,3)) .+ collect(1:e.seq_len) # size(x,3) is batchsize. Resulting matrix is SxB
    x = x .+ e.positional(positions)
    #x .+= reshape(hcat(e.segment.(segment_ids)...), (:, size(segment_ids,1),size(segment_ids,2)))
    x = x .+ e.segment(segment_ids)
    x = e.layer_norm(x)
    return dropout(x, e.pdrop)
end

function divide_to_heads(x, num_heads, head_size, seq_len)
    x = reshape(x, (head_size, num_heads, seq_len, :))
    x = permutedims(x, (1,3,2,4))
    return reshape(x, (head_size, seq_len, :)) # Reshape to 3D so bmm can handle it.
end

mutable struct SelfAttention <: Layer
    query::Linear3D # N*H x E
    key::Linear3D
    value::Linear3D
    linear::Linear3D
    num_heads::Int
    seq_len::Int
    embed_size::Int
    head_size::Int
    head_size_sqrt::Int
    attention_pdrop
    pdrop
end

function SelfAttention(config)
    config.embed_size % config.num_heads != 0 && throw("Embed size should be divisible by number of heads!")
    head_size = Int(config.embed_size / config.num_heads)
    head_size_sqrt = Int(sqrt(head_size))
    head_size_sqrt * head_size_sqrt != head_size && throw("Square root of head size should be an integer!")
    query = Linear3D(config.embed_size, head_size*config.num_heads, atype=config.atype) # H*N is always equal to E
    key = Linear3D(config.embed_size, head_size*config.num_heads, atype=config.atype)
    value = Linear3D(config.embed_size, head_size*config.num_heads, atype=config.atype)
    linear = Linear3D(config.embed_size, config.embed_size, atype=config.atype)
    return SelfAttention(query, key, value, linear, config.num_heads, config.seq_len, config.embed_size, head_size, head_size_sqrt, config.attention_pdrop, config.pdrop)
end

function (s::SelfAttention)(x, attention_mask)
    # We make all the batchsize ones colon, in case of batches smaller than batchsize.
    # x is ExSxB
    query = divide_to_heads(s.query(x), s.num_heads, s.head_size, s.seq_len) # H x S x N*B
    key = divide_to_heads(s.key(x), s.num_heads, s.head_size, s.seq_len)
    value = divide_to_heads(s.value(x), s.num_heads, s.head_size, s.seq_len)
    
    # Scaled Dot Product Attention
    query = bmm(permutedims(key, (2,1,3)), query)
    query = query ./ s.head_size_sqrt # Scale down. I init this value to avoid taking sqrt every forward operation.
    # Masking. First reshape to 4d, then add mask, then reshape back to 3d.
    query = reshape(reshape(query, (s.seq_len, s.seq_len, s.num_heads, :)) .+ attention_mask, (s.seq_len, s.seq_len, :))

    query = Knet.softmax(query, dims=1)
    query = dropout(query, s.attention_pdrop)
    query = bmm(value, query)
    query = permutedims(reshape(query, (s.head_size, s.seq_len, s.num_heads, :)), (1,3,2,4))
    
    query = reshape(query, (s.embed_size, s.seq_len, :)) # Concat
    return dropout(s.linear(query), s.pdrop) # Linear transformation at the end
    # In pytorch version dropout is after layer_norm!
end

mutable struct FeedForward <: Layer
    dense::Dense
    linear::Linear3D
    pdrop
end

function FeedForward(config)
    dense = Dense(config.embed_size, config.ff_hidden_size, func=eval(Meta.parse(config.func)), atype=config.atype, threeD=true)
    linear = Linear3D(config.ff_hidden_size, config.embed_size, atype=config.atype)
    return FeedForward(dense, linear, config.pdrop)
end

function (f::FeedForward)(x)
    x = f.dense(x)
    return dropout(f.linear(x), f.pdrop)
end

mutable struct Encoder <: Layer
    self_attention::SelfAttention
    layer_norm1::LayerNormalization
    feed_forward::FeedForward
    layer_norm2::LayerNormalization
end

function Encoder(config)
    return Encoder(SelfAttention(config), LayerNormalization(config.embed_size, atype=config.atype), FeedForward(config), LayerNormalization(config.embed_size, atype=config.atype))
end

function (e::Encoder)(x, attention_mask)
    x = e.layer_norm1(x .+ e.self_attention(x, attention_mask))
    return e.layer_norm2(x .+ e.feed_forward(x))
end

mutable struct Bert <: Layer
    embed_layer::EmbedLayer
    encoder_stack
    atype
end

function Bert(config)
    embed_layer = EmbedLayer(config)
    encoder_stack = Encoder[]
    for _ in 1:config.num_encoder
        push!(encoder_stack, Encoder(config))
    end
    return Bert(embed_layer, encoder_stack, config.atype)
end

# x and segment_ids are SxB integers
function (b::Bert)(x, segment_ids; attention_mask=nothing)
    # Init attention_mask if it's not given
    attention_mask = attention_mask == nothing ? ones(size(x)) : attention_mask
    attention_mask = reshape(attention_mask, (size(attention_mask,1), 1, 1, size(attention_mask,2))) # Make it 4d
    attention_mask = (1 .- attention_mask) .* -10000.0 # If integer was 0, now it is masking. ones(size(attention_mask))
    attention_mask = b.atype(attention_mask)

    x = b.embed_layer(x, segment_ids)
    for encoder in b.encoder_stack
        x = encoder(x, attention_mask)
    end
    return x
end

mutable struct Pooler <: Layer
    linear::Linear
end

Pooler(embed_size::Int; atype=Array{Float32}) = Pooler(Linear(embed_size, embed_size, atype=atype))

function (p::Pooler)(x)
    # TODO :
    # Gave up on getindex function for 3D matrices because I could not figure out how to write setindex! for backprop
#     x = reshape(x, :, size(x,3))
#    return tanh.(p.linear(x[:,1,:])) # Use only CLS token. Returns ExB
    return tanh.(p.linear(reshape(x, :, size(x,3))[1:size(x,1),:]))
end

mutable struct NSPHead <: Layer
    linear::Linear
end

NSPHead(embed_size::Int; atype=Array{Float32}) = NSPHead(Linear(embed_size, 2, atype=atype))

(n::NSPHead)(x) = n.linear(x)

mutable struct MLMHead <: Layer
    dense::Dense
    layer_norm::LayerNormalization
    linear::Linear3D
end

function MLMHead(config, embedding_matrix)
    dense = Dense(config.embed_size, config.embed_size, func=eval(Meta.parse(config.func)), pdrop=0.0, atype=config.atype, threeD=true)
    layer_norm = LayerNormalization(config.embed_size, atype=config.atype)
    linear = Linear3D(config.embed_size, config.vocab_size, atype=config.atype)
    # TODO : Do this a shared weight
    #linear.w = permutedims(embedding_matrix, (2,1))
    return MLMHead(dense, layer_norm, linear)
end

function (m::MLMHead)(x)
    x = m.dense(x)
    x = m.layer_norm(x)
    return m.linear(x)
end

mutable struct BertPreTraining <: Layer
    bert::Bert
    pooler::Pooler
    nsp::NSPHead
    mlm::MLMHead
end

function BertPreTraining(config)
    bert = Bert(config)
    pooler = Pooler(config.embed_size, atype=config.atype)
    nsp = NSPHead(config.embed_size, atype=config.atype)
    mlm = MLMHead(config, bert.embed_layer.wordpiece.w) # TODO : Dont forget about embedding matrix
    return BertPreTraining(bert, pooler, nsp, mlm)
end

# We do not need a predictor, since this is only for pretraining
function (b::BertPreTraining)(x, segment_ids, mlm_labels, nsp_labels; attention_mask=nothing) # mlm_labels are SxB, so we just flatten them.
    x = b.bert(x, segment_ids, attention_mask=attention_mask)
    nsp_preds = b.nsp(b.pooler(x)) # 2xB
    mlm_preds = b.mlm(x) # VxSxB
    mlm_preds = reshape(mlm_preds, size(mlm_preds, 1), :) # VxS*B
    nsp_loss = nll(nsp_preds, nsp_labels)
    mlm_labels = reshape(mlm_labels, :) # S*B
    mlm_loss = nll(mlm_preds[:,mlm_labels.!=-1], mlm_labels[mlm_labels.!=-1])
    return mlm_loss + nsp_loss
end

function (b::BertPreTraining)(dtrn)
    lvals = []
    for (x, attention_mask, segment_ids, mlm_labels, nsp_labels) in dtrn
        push!(lvals, b(x, segment_ids, mlm_labels, nsp_labels, attention_mask=attention_mask))
    end
    return Knet.mean(lvals)
end

mutable struct BertClassification <: Layer
    bert::Bert
    pooler::Pooler
    linear::Linear
    pdrop
end

function BertClassification(config, num_of_classes)
    bert = Bert(config)
    pooler = Pooler(config.embed_size, atype=config.atype)
    linear = Linear(config.embed_size, num_of_classes, atype=config.atype)
    return BertClassification(bert, pooler, linear, config.pdrop)
end

function (b::BertClassification)(x, segment_ids; attention_mask=nothing)
    x = b.bert(x, segment_ids, attention_mask=attention_mask)
    x = dropout(b.pooler(x), b.pdrop) # 2xB
    return b.linear(x)
end

function (b::BertClassification)(x, segment_ids, y; attention_mask=nothing)
    return nll(b(x, segment_ids, attention_mask=attention_mask), y)
end

function (b::BertClassification)(dtrn)
    lvals = []
    for (x, attention_mask, segment_ids, y) in dtrn
        push!(lvals, b(x, segment_ids, y, attention_mask=attention_mask))
    end
    return Knet.mean(lvals)
end

mutable struct BertConfig
    embed_size::Int
    vocab_size::Int
    ff_hidden_size::Int
    max_seq_len::Int
    seq_len::Int
    num_segment::Int
    num_heads::Int
    num_encoder::Int
    batchsize::Int
    atype
    pdrop
    attention_pdrop
    func
end

function load_from_torch_base(model, num_encoder, atype, torch_model)
    # Embed Layer
    model.bert.embed_layer.wordpiece.w = Param(atype(permutedims(torch_model["bert.embeddings.word_embeddings.weight"][:cpu]()[:numpy](), (2,1))))
    model.bert.embed_layer.positional.w = Param(atype(permutedims(torch_model["bert.embeddings.position_embeddings.weight"][:cpu]()[:numpy](), (2,1))))
    model.bert.embed_layer.segment.w = Param(atype(permutedims(torch_model["bert.embeddings.token_type_embeddings.weight"][:cpu]()[:numpy](), (2,1))))
    model.bert.embed_layer.layer_norm.γ = Param(atype(torch_model["bert.embeddings.LayerNorm.gamma"][:cpu]()[:numpy]()))
    model.bert.embed_layer.layer_norm.β = Param(atype(torch_model["bert.embeddings.LayerNorm.beta"][:cpu]()[:numpy]()))
    
    # Encoder Stack
    for i in 1:num_encoder
        model.bert.encoder_stack[i].self_attention.query.w = Param(atype(torch_model["bert.encoder.layer.$(i-1).attention.self.query.weight"][:cpu]()[:numpy]()))
        model.bert.encoder_stack[i].self_attention.query.b = Param(atype(torch_model["bert.encoder.layer.$(i-1).attention.self.query.bias"][:cpu]()[:numpy]()))
        model.bert.encoder_stack[i].self_attention.key.w = Param(atype(torch_model["bert.encoder.layer.$(i-1).attention.self.key.weight"][:cpu]()[:numpy]()))
        model.bert.encoder_stack[i].self_attention.key.b = Param(atype(torch_model["bert.encoder.layer.$(i-1).attention.self.key.bias"][:cpu]()[:numpy]()))
        model.bert.encoder_stack[i].self_attention.value.w = Param(atype(torch_model["bert.encoder.layer.$(i-1).attention.self.value.weight"][:cpu]()[:numpy]()))
        model.bert.encoder_stack[i].self_attention.value.b = Param(atype(torch_model["bert.encoder.layer.$(i-1).attention.self.value.bias"][:cpu]()[:numpy]()))
        model.bert.encoder_stack[i].self_attention.linear.w = Param(atype(torch_model["bert.encoder.layer.$(i-1).attention.output.dense.weight"][:cpu]()[:numpy]()))
        model.bert.encoder_stack[i].self_attention.linear.b = Param(atype(torch_model["bert.encoder.layer.$(i-1).attention.output.dense.bias"][:cpu]()[:numpy]()))
        
        model.bert.encoder_stack[i].layer_norm1.γ = Param(atype(torch_model["bert.encoder.layer.$(i-1).attention.output.LayerNorm.gamma"][:cpu]()[:numpy]()))
        model.bert.encoder_stack[i].layer_norm1.β = Param(atype(torch_model["bert.encoder.layer.$(i-1).attention.output.LayerNorm.beta"][:cpu]()[:numpy]()))
        model.bert.encoder_stack[i].feed_forward.dense.linear.w = Param(atype(torch_model["bert.encoder.layer.$(i-1).intermediate.dense.weight"][:cpu]()[:numpy]()))
        model.bert.encoder_stack[i].feed_forward.dense.linear.b = Param(atype(torch_model["bert.encoder.layer.$(i-1).intermediate.dense.bias"][:cpu]()[:numpy]()))
        model.bert.encoder_stack[i].feed_forward.linear.w = Param(atype(torch_model["bert.encoder.layer.$(i-1).output.dense.weight"][:cpu]()[:numpy]()))
        model.bert.encoder_stack[i].feed_forward.linear.b = Param(atype(torch_model["bert.encoder.layer.$(i-1).output.dense.bias"][:cpu]()[:numpy]()))
        model.bert.encoder_stack[i].layer_norm2.γ = Param(atype(torch_model["bert.encoder.layer.$(i-1).output.LayerNorm.gamma"][:cpu]()[:numpy]()))
        model.bert.encoder_stack[i].layer_norm2.β = Param(atype(torch_model["bert.encoder.layer.$(i-1).output.LayerNorm.beta"][:cpu]()[:numpy]()))
    end
    
    # Pooler
    model.pooler.linear.w = Param(atype(torch_model["bert.pooler.dense.weight"][:cpu]()[:numpy]()))
    model.pooler.linear.b = Param(atype(torch_model["bert.pooler.dense.bias"][:cpu]()[:numpy]()))
    
    return model
end

function load_from_torch_pretraining(model, num_encoder, atype, torch_model)
    model = load_from_torch_base(model, num_encoder, atype, torch_model)
    
    # NSP Head
    model.nsp.linear.w = Param(atype(torch_model["cls.seq_relationship.weight"][:cpu]()[:numpy]()))
    model.nsp.linear.b = Param(atype(torch_model["cls.seq_relationship.bias"][:cpu]()[:numpy]()))
    
    # MLM Head.
    model.mlm.dense.linear.w = Param(atype(torch_model["cls.predictions.transform.dense.weight"][:cpu]()[:numpy]()))
    model.mlm.dense.linear.b = Param(atype(torch_model["cls.predictions.transform.dense.bias"][:cpu]()[:numpy]()))
    model.mlm.layer_norm.γ = Param(atype(torch_model["cls.predictions.transform.LayerNorm.gamma"][:cpu]()[:numpy]()))
    model.mlm.layer_norm.β = Param(atype(torch_model["cls.predictions.transform.LayerNorm.beta"][:cpu]()[:numpy]()))
    model.mlm.linear.w = Param(atype(torch_model["cls.predictions.decoder.weight"][:cpu]()[:numpy]()))
    model.mlm.linear.b = Param(atype(torch_model["cls.predictions.bias"][:cpu]()[:numpy]()))
    
    return model
end

function load_from_torch_classification(model, num_encoder, atype, torch_model)
    model = load_from_torch_base(model, num_encoder, atype, torch_model)
    
    model.linear.w = Param(atype(torch_model["classifier.weight"][:cpu]()[:numpy]()))
    model.linear.b = Param(atype(torch_model["classifier.bias"][:cpu]()[:numpy]()))
    
    return model
end
