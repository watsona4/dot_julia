# This script is a minimal example of how to use a `FeedbackChain` to build a
# convolutional network with feedback operations and to apply it to data.
using Pkg
Pkg.activate("..")
using FeedbackNets
using Flux

# some parameters
batchsize = 10
usegpu = false

if usegpu
    using CuArrays
end

# We generate the FeedbackChain much like a normal Flux.Chain. The difference is
# that we set Splitters where feedback branches off and Mergers where the feedback
# is folded back in.
# The basis for this architecture is LeNet5, but with ReLUs instead of sigmoids.
chain = FeedbackChain(
    Conv((5,5), 1=>6, relu),
    Merger("conv2", ConvTranspose((10,10), 16=>6, relu, stride=2), +),
    MaxPool((2,2), stride=(2,2)),
    Conv((5,5), 6=>16, relu),
    Splitter("conv2"),
    Merger("fc1", ConvTranspose((10,10), 120=>16, relu), +),
    MaxPool((2,2), stride=(2,2)),
    Conv((5,5), 16=>120, relu),
    Splitter("fc1"),
    x -> reshape(x, 120, size(x, 4)),
    Dense(120, 84, relu),
    Dense(84, 10)
)

# In order to apply this chain, we need to pass it a dictionary with the initial
# states of all Splitters. Here, we simply set all initial states to zero.
h = Dict(
    "conv2" => zeros(10, 10, 16, batchsize),
    "fc1" => zeros(1, 1, 120, batchsize)
)

# If we want to calculate the model on a GPU, we also need to shift the initial
# states.
if usegpu
    chain = chain |> gpu
    h = Dict(key => gpu(val) for (key, val) in pairs(h))
end

# Now we can turn out model into a Flux.Recur, which handles its state
# internally.
model = Flux.Recur(chain, h)

# At this point, we can treat out model like any other recurrent network in Flux.
# We can apply it to a single input batch ...
batch = randn(32, 32, 1, batchsize)
if usegpu
    batch = gpu(batch)
end
out1 = model(batch)
# ... or broadcast it over a (time)sequence of batches.
seq = [batch, batch, batch]
out2 = model.(seq)
