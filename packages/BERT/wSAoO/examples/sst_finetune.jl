using BERT
using Knet
import Base: length, iterate
using Random
using CSV
using PyCall
using Dates

VOCABFILE = "bert-base-uncased-vocab.txt"
NUM_CLASSES = 2
LEARNING_RATE = 2e-5
NUM_OF_EPOCHS = 30
TRAIN = true

token2int = Dict()
f = open(VOCABFILE) do file
    lines = readlines(file)
    for (i,line) in enumerate(lines)
        token2int[line] = i
    end
end
int2token = Dict(value => key for (key, value) in token2int)
VOCABSIZE = length(token2int)

# include("preprocess.jl")
# include("optimizer.jl")

function convert_to_int_array(text, dict; lower_case=true)
    tokens = bert_tokenize(text, dict, lower_case=lower_case)
    out = Int[]
    for token in tokens
        if token in keys(dict)
            push!(out, dict[token])
        else
            push!(out, dict["[UNK]"])
        end
    end
    return out
end

function read_and_process(filename, dict; lower_case=true)
    data = CSV.File(filename, delim="\t")
    x = Array{Int,1}[]
    y = Int8[]
    for i in data
        push!(x, convert_to_int_array(i.sentence, dict, lower_case=lower_case))
        push!(y, Int8(i.label + 1)) # negative 1, positive 2
    end
    
    # Padding to maximum
#     max_seq = findmax(length.(x))[1]
#     for i in 1:length(x)
#         append!(x[i], fill(1, max_seq - length(x[i]))) # 1 is for "[PAD]"
#     end
    
    return (x, y)
end

mutable struct ClassificationData
    input_ids
    input_mask
    segment_ids
    labels
    batchsize
    ninstances
    shuffled
end

function ClassificationData(input_file, token2int; batchsize=8, shuffled=true, seq_len=64)
    input_ids = []
    input_mask = []
    segment_ids = []
    labels = []
    (x, labels) = read_and_process(input_file, token2int)
    for i in 1:length(x)
        if length(x[i]) >= seq_len
            x[i] = x[i][1:seq_len]
            mask = Array{Int64}(ones(seq_len))
        else
            mask = Array{Int64}(ones(length(x[i])))
            append!(x[i], fill(1, seq_len - length(x[i]))) # 1 is for "[PAD]"
            append!(mask, fill(0, seq_len - length(mask))) # 0's vanish with masking operation
        end
        push!(input_ids, x[i])
        push!(input_mask, mask)
        push!(segment_ids, Array{Int64}(ones(seq_len)))
    end
    ninstances = length(input_ids)
    return ClassificationData(input_ids, input_mask, segment_ids, labels, batchsize, ninstances, shuffled)
end


function length(d::ClassificationData)
    d, r = divrem(d.ninstances, d.batchsize)
    return r == 0 ? d : d+1
end

function iterate(d::ClassificationData, state=ifelse(d.shuffled, randperm(d.ninstances), 1:d.ninstances))

    state === nothing && return nothing

    if length(state) > d.batchsize
        new_state = state[d.batchsize+1:end]
        input_ids = hcat(d.input_ids[state[1:d.batchsize]]...)
        input_mask = hcat(d.input_mask[state[1:d.batchsize]]...)
        segment_ids = hcat(d.segment_ids[state[1:d.batchsize]]...)
        labels = hcat(d.labels[state[1:d.batchsize]]...)
    else
        new_state = nothing
        input_ids = hcat(d.input_ids[state]...)
        input_mask = hcat(d.input_mask[state]...)
        segment_ids = hcat(d.segment_ids[state]...)
        labels = hcat(d.labels[state]...)
    end
    
    return ((input_ids, input_mask, segment_ids, labels), new_state)
end

# mutable struct ClassificationData2
#     input_ids
#     input_mask
#     segment_ids
#     labels
#     batchsize
#     ninstances
#     shuffled
# end


# function ClassificationData2(input_file; batchsize=8, shuffled=true, seq_len=64)
#     input_ids = []
#     input_mask = []
#     segment_ids = []
#     labels = []
#     f = open(input_file)
#     tmp = split.(readlines(f), "\t")
#     for i in 1:length(tmp)
#         instance = eval.(Meta.parse.(tmp[i]))
#         push!(input_ids, (instance[1] .+ 1)[1:seq_len])
#         push!(input_mask, instance[2][1:seq_len])
#         push!(segment_ids, (instance[3] .+ 1)[1:seq_len])
#         push!(labels, (instance[4] + 1))
#     end
#     ninstances = length(input_ids)
#     return ClassificationData2(input_ids, input_mask, segment_ids, labels, batchsize, ninstances, shuffled)
# end


# function length(d::ClassificationData2)
#     d, r = divrem(d.ninstances, d.batchsize)
#     return r == 0 ? d : d+1
# end

# function iterate(d::ClassificationData2, state=ifelse(d.shuffled, randperm(d.ninstances), 1:d.ninstances))

#     state === nothing && return nothing

#     if length(state) > d.batchsize
#         new_state = state[d.batchsize+1:end]
#         input_ids = hcat(d.input_ids[state[1:d.batchsize]]...)
#         input_mask = hcat(d.input_mask[state[1:d.batchsize]]...)
#         segment_ids = hcat(d.segment_ids[state[1:d.batchsize]]...)
#         labels = hcat(d.labels[state[1:d.batchsize]]...)
#     else
#         new_state = nothing
#         input_ids = hcat(d.input_ids[state]...)
#         input_mask = hcat(d.input_mask[state]...)
#         segment_ids = hcat(d.segment_ids[state]...)
#         labels = hcat(d.labels[state]...)
#     end
    
#     return ((input_ids, input_mask, segment_ids, labels), new_state)
# end

# include("model.jl")

# Embedding Size, Vocab Size, Intermediate Hidden Size, Max Sequence Length, Sequence Length, Num of Segments, Num of Heads in Attention, Num of Encoders in Stack, Batch Size, Matrix Type, General Dropout Rate, Attention Dropout Rate, Activation Function 
config = BertConfig(768, 30522, 3072, 512, 64, 2, 12, 12, 8, KnetArray{Float32}, 0.1, 0.1, "gelu")

if TRAIN
    dtrn = ClassificationData("../project/mytrain.tsv", token2int, batchsize=config.batchsize, seq_len=config.seq_len)
    ddev = ClassificationData("../project/dev.tsv", token2int, batchsize=config.batchsize, seq_len=config.seq_len)
else
    dtst = ClassificationData("../project/mytest.tsv", token2int, batchsize=config.batchsize, seq_len=config.seq_len)
end

if TRAIN
    model = BertClassification(config, NUM_CLASSES)

    @pyimport torch
    torch_model = torch.load("../project/pytorch_model.bin")

    model = load_from_torch_base(model, config.num_encoder, config.atype, torch_model)
end

function accuracy2(model, dtst)
    true_count = 0
    all_count = 0
    for (x, attention_mask, segment_ids, y) in dtst
        probs = model(x, segment_ids, attention_mask=attention_mask)
        preds = map(x -> x[1], argmax(Array{Float32}(probs),dims=1))
        true_count += sum(y .== preds)
        all_count += length(y)
    end
    return true_count/all_count
end

function initopt!(model, t_total; lr=0.001, warmup=0.1)
    for par in params(model)
        if length(size(value(par))) === 1
            par.opt = BertAdam(lr=lr, warmup=warmup, t_total=t_total, w_decay_rate=0.01)
        else
            par.opt = BertAdam(lr=lr, warmup=warmup, t_total=t_total)
        end
    end
end

function mytrain!(model, dtrn, ddev, best_acc)
    losses = []
    accs = []
    for (k, (x, attention_mask, segment_ids, labels)) in enumerate(dtrn)
        J = @diff model(x, segment_ids, labels, attention_mask=attention_mask)
        for par in params(model)
            g = grad(J, par)
            update!(value(par), g, par.opt)
        end
        push!(losses, value(J))
        if k % 500 == 0
            print(Dates.format(now(), "HH:MM:SS"), "  ->  ")
            println("Training loss up to $k iteration is : ", Knet.mean(losses))
            flush(stdout)
            acc = accuracy2(model, ddev)
            push!(accs, acc)
            print(Dates.format(now(), "HH:MM:SS"), "  ->  ")
            println("Accuracy at $k iteration : ", acc)
            flush(stdout)
            if acc > best_acc
                best_acc = acc
                print(Dates.format(now(), "HH:MM:SS"), "  ->  ")
                println("Saving...")
                Knet.save("model_bert.jld2", "model", model)
                flush(stdout)
            end
        end
    end
    return (best_acc, Knet.mean(losses), accs)
end

if TRAIN
    t_total = length(dtrn) * NUM_OF_EPOCHS
    initopt!(model, t_total, lr=LEARNING_RATE)

    dev_accs = [0.0]
    best_acc = 0.0
    for epoch in 1:NUM_OF_EPOCHS
        global best_acc
        print(Dates.format(now(), "HH:MM:SS"), "  ->  ")
        println("Epoch : ", epoch)
        flush(stdout)
        (best_acc, lss, acc) = mytrain!(model, dtrn, ddev, best_acc)
        append!(dev_accs, acc)
        print(Dates.format(now(), "HH:MM:SS"), "  ->  ")
        println("Training loss for $epoch epoch is : $lss")
        println(dev_accs)
        flush(stdout)
        #=
        acc = accuracy2(model, ddev)
        println("Accuracy : ", acc)
        if acc > best_acc
            best_acc = acc
            println("Saving...")
            Knet.save("model_bert.jld2", "model", model)
        end
        =#
    end

    Knet.save("accuracies.jld2", "dev_accs", dev_accs)
else
    model = Knet.load("model_bert.jld2", "model")
    result = accuracy2(model, dtst)
    print(Dates.format(now(), "HH:MM:SS"), "  ->  ")
    println("Test accuracy is : $result")
end
