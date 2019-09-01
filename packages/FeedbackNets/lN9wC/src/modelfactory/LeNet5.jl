"""
Reimplementation of the LeNet5 architecture from

LeCun, Bottou, Bengio & Haffner (1998),
Gradient-based learning applied to document recognition.
Procedings of the IEEE 86(11), 2278-2324.

and a version of LeNet5 with feedback connections.
"""
module LeNet5
using Flux
using ...Splitters
using ...Mergers
using ...FeedbackChains

export lenet5, lenet5_fb, wrapfb_lenet5

"""
    lenet5(; σ=tanh, pad=2)

Generate the LeNet5 architecture from LeCun et al. (1998) with small modifications.

## Details

The implementation differs from the original LeNet5, as the output layer does not
compute radial basis functions, but is a normal `Dense` layer with a softmax.
The input image is padded. The network assumes a 32x32 input, so for MNIST digits
a `pad` of 2 is appropriate.
The non-linearity can be customized via the `σ` argument. The standard is `tanh`,
whereas the original LeNet5 used `x -> 1.7159 .* tanh(x)`.
"""
function lenet5(; σ=tanh, pad=2)
    return Chain(
        Conv((5,5), 1=>6, σ, pad=pad),
        MaxPool((2,2), stride=(2,2)),
        Conv((5,5), 6=>16, σ),
        MaxPool((2,2), stride=(2,2)),
        Conv((5,5), 16=>120, σ),
        x -> reshape(x, 120, size(x, 4)),
        Dense(120, 84, σ),
        Dense(84, 10),
        softmax
    )
end # function lenet5

"""
    lenet5_fb(; σ=tanh, pad=2)

Generate the LeNet5 architecture from LeCun et al. (1998) with feedback connections
and small modifications.
"""
function lenet5_fb(; σ=tanh, pad=2, op=+)
    return FeedbackChain(
        Conv((5,5), 1=>6, relu, pad=2),
        Merger("conv2", ConvTranspose((10,10), 16=>6, relu, stride=2), op),
        MaxPool((2,2), stride=(2,2)),
        Conv((5,5), 6=>16, relu),
        Splitter("conv2"),
        Merger("fc1", ConvTranspose((10,10), 120=>16, relu), op),
        MaxPool((2,2), stride=(2,2)),
        Conv((5,5), 16=>120, relu),
        Splitter("fc1"),
        x -> reshape(x, 120, size(x, 4)),
        Dense(120, 84, relu),
        Dense(84, 10),
        softmax
    )
end # function lenet5_fb

"""
    wrapfb_lenet5(net, batchsize; generator=zeros)

Wrap a `letnet5_fb` network in a `Flux.Recur`, assuming that batches are of size
`batchsize` and using the given `generator` to initialize the state.
"""
function wrapfb_lenet5(net, batchsize; generator=zeros)
    h = Dict(
        "conv2" => generator(10, 10, 16, batchsize),
        "fc1" => generator(1, 1, 120, batchsize)
    )
    return Flux.Recur(net, h)
end # function wrapfb_lenet5

end # module LeNet5
