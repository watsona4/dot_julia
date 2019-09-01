"""
This module reimplements models from the paper:

    Spoerer, C.J., McClure, P. and Kriegeskorte, N. (2017).
    Recurrent convolutional neural networks: a better model of biological object recognition.
    Frontiers in Psychology 8, 1551.
"""
module Spoerer2017
using Flux
using ...Splitters
using ...Mergers
using ...FeedbackChains
using ..LRNs
using ..Flatten

export spoerer_model_b, spoerer_model_bf, spoerer_model_bk,
       spoerer_model_bl, spoerer_model_bt, spoerer_model_blt

"""
    spoerer_model_fw(T; channels=1, inputsize=(28, 28), kernel=(3,3), features=32, classes=10)

Generate one of the forward models (B, B-K, B-F) from the paper:

    Spoerer, C.J., McClure, P. & Kriegeskorte, N. (2017).
    Recurrent convolutional neural networks: a better model of biological object recognition.
    Frontiers in Psychology 8, 1551.
"""
function spoerer_model_fw(T; channels=1, inputsize=(28, 28), kernel=(3,3), features=32, classes=10)
    return Chain(
        Conv(kernel, channels=>features, relu, pad=map(x -> x ÷ 2, kernel)),
        LRN(T(1.0), T(0.0001), T(0.5), 5),
        MaxPool((2,2), stride=(2,2)),
        Conv(kernel, features=>features, relu, pad=map(x -> x ÷ 2, kernel)),
        LRN(T(1.0), T(0.0001), T(0.5), 5),
        MaxPool(map(x -> x ÷ 2, inputsize)),
        flatten,
        Dense(features, classes, σ)
    )
end # function spoerer_model_fw

"""
    spoerer_model_b(T; channels=1, inputsize=(28, 28), classes=10)

Generate the bottom-up (B) convolutional neural network from:

    Spoerer, C.J., McClure, P. & Kriegeskorte, N. (2017).
    Recurrent convolutional neural networks: a better model of biological object recognition.
    Frontiers in Psychology 8, 1551.
"""
spoerer_model_b(T; channels=1, inputsize=(28,28), classes=10) =
    spoerer_model_fw(T, channels=channels, inputsize=inputsize, classes=classes)

"""
    spoerer_model_bk(T; channels=1, inputsize=(28, 28), classes=10)

Generate the convolutional neural network with increased kernel size (BK) from:

    Spoerer, C.J., McClure, P. & Kriegeskorte, N. (2017).
    Recurrent convolutional neural networks: a better model of biological object recognition.
    Frontiers in Psychology 8, 1551.
"""
spoerer_model_bk(T; channels=1, inputsize=(28,28), classes=10) =
    spoerer_model_fw(T, channels=channels, inputsize=inputsize, classes=classes, kernel=(5,5))

"""
    spoerer_model_bf(T; channels=1, inputsize=(28, 28), classes=10)

Generate the convolutional neural network with additional feature maps (BF) from:

    Spoerer, C.J., McClure, P. & Kriegeskorte, N. (2017).
    Recurrent convolutional neural networks: a better model of biological object recognition.
    Frontiers in Psychology 8, 1551.
"""
spoerer_model_bf(T; channels=1, inputsize=(28,28), classes=10) =
    spoerer_model_fw(T, channels=channels, inputsize=inputsize, classes=classes, features=64)

# TODO: currently, the forward, lateral and backward convolutions all have their
#       own biases. This should not make the model more powerful, as they are
#       combined additively before the non-linearity, but it wastes some resources.
"""
    spoerer_model_bl(T; channels=1, inputsize=(28, 28), kernel=(3,3), features=32, classes=10)

Generate the convolutional neural network with lateral recurrence (BL) from:

    Spoerer, C.J., McClure, P. & Kriegeskorte, N. (2017).
    Recurrent convolutional neural networks: a better model of biological object recognition.
    Frontiers in Psychology 8, 1551.
"""
function spoerer_model_bl(T; channels=1, inputsize=(28, 28), kernel=(3,3), features=32, classes=10)
    return FeedbackChain(
        Conv(kernel, channels=>features, pad=map(x -> x ÷ 2, kernel)),
        Merger("l1", ConvTranspose(kernel, features=>features, pad=map(x -> x ÷ 2, kernel)), +),
        x -> relu.(x),
        Splitter("l1"),
        LRN(T(1.0), T(0.0001), T(0.5), 5),
        MaxPool((2,2), stride=(2,2)),
        Conv(kernel, features=>features, pad=map(x -> x ÷ 2, kernel)),
        Merger("l2", ConvTranspose(kernel, features=>features, pad=map(x -> x ÷ 2, kernel)), +),
        x -> relu.(x),
        Splitter("l2"),
        LRN(T(1.0), T(0.0001), T(0.5), 5),
        MaxPool(map(x -> x ÷ 2, inputsize)),
        flatten,
        Dense(features, classes, σ)
    )
end # function spoerer_model_bl

"""
    spoerer_model_bt(T; channels=1, inputsize=(28, 28), kernel=(3,3), features=32, classes=10)

Generate the convolutional neural network with top-down recurrence (BT) from:

    Spoerer, C.J., McClure, P. & Kriegeskorte, N. (2017).
    Recurrent convolutional neural networks: a better model of biological object recognition.
    Frontiers in Psychology 8, 1551.
"""
function spoerer_model_bt(T; channels=1, inputsize=(28, 28), kernel=(3,3), features=32, classes=10)
    return FeedbackChain(
        Conv(kernel, channels=>features, pad=map(x -> x ÷ 2, kernel)),
        Merger("l2",  ConvTranspose((2,2), features=>features, stride=2), +),
        x -> relu.(x),
        LRN(T(1.0), T(0.0001), T(0.5), 5),
        MaxPool((2,2), stride=(2,2)),
        Conv(kernel, features=>features, relu, pad=map(x -> x ÷ 2, kernel)),
        Splitter("l2"),
        LRN(T(1.0), T(0.0001), T(0.5), 5),
        MaxPool(map(x -> x ÷ 2, inputsize)),
        flatten,
        Dense(features, classes, σ)
    )
end # function spoerer_model_bt

"""
    spoerer_model_blt(T; channels=1, inputsize=(28, 28), kernel=(3,3), features=32, classes=10)

Generate the convolutional neural network with lateral and top-down recurrence (BLT) from:

    Spoerer, C.J., McClure, P. & Kriegeskorte, N. (2017).
    Recurrent convolutional neural networks: a better model of biological object recognition.
    Frontiers in Psychology 8, 1551.
"""
function spoerer_model_blt(T; channels=1, inputsize=(28, 28), kernel=(3,3), features=32, classes=10)
    return FeedbackChain(
        Conv(kernel, channels=>features, pad=map(x -> x ÷ 2, kernel)),
        Merger("l1", ConvTranspose(kernel, features=>features, pad=map(x -> x ÷ 2, kernel)), +),
        Merger("l2", ConvTranspose((2,2), features=>features, stride=2), +),
        x -> relu.(x),
        Splitter("l1"),
        LRN(T(1.0), T(0.0001), T(0.5), 5),
        MaxPool((2,2), stride=(2,2)),
        Conv(kernel, features=>features, pad=map(x -> x ÷ 2, kernel)),
        Merger("l2", ConvTranspose(kernel, features=>features, pad=map(x -> x ÷ 2, kernel)), +),
        x -> relu.(x),
        Splitter("l2"),
        LRN(T(1.0), T(0.0001), T(0.5), 5),
        MaxPool(map(x -> x ÷ 2, inputsize)),
        flatten,
        Dense(features, classes, σ)
    )
end # function spoerer_model_blt

end # module Spoerer2017
