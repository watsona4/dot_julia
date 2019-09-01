# A collection of functions to load and preprocess data for training.
module DataHelpers
using MLDatasets
using Base.Iterators: partition
using Statistics
using Random

################################################################################
# Dataset partitioning
################################################################################
function makebatches(data, labels; batchsize=128)
    batchinds = collect(partition(1:length(labels), batchsize))
    n = ndims(data)
    databatches = map(batch -> data[repeat([Colon()], n-1)..., batch], batchinds)
    labelbatches = map(batch -> labels[batch], batchinds)
    return databatches, labelbatches
end # function makebatches


################################################################################
# Preprocessing
################################################################################
"""
    standardize(imgs)

Normalize each image in `imgs` to have mean 0 and variance 1. Assumes that the
first two dimensions are the image dimensions.

!!! warning
    This should only be used on grayscale images. Color channels would be treated
    like independent images.
"""
function standardize(imgs)
    std_img = std(imgs, dims=(1,2))
    std_img[std_img .== 0] .= 1
    imgs = imgs .- mean(imgs, dims=(1,2))
    imgs = imgs ./ std_img
    return imgs
end # function normalize_images

"""
    whitenoise(imgs, σ)

Add white noise with variance `σ` to `imgs`.
"""
whitenoise(imgs, σ) = return imgs + randn(eltype(imgs), size(imgs)...) .* σ

"""
    saltpepper(imgs, p)

Add salt-and-pepper noise to 'imgs' by randomly swithing off pixels with probability
`p` (half will be set to 0, half to 1).
"""
function saltpepper(imgs, p)
    imgs = copy(imgs)
    inds = shuffle(randsubseq(1:length(imgs), 0.1))
    imgs[inds[1:2:end]] .= 0.0
    imgs[inds[2:2:end]] .= 1.0
    return imgs
end


################################################################################
# Dataset generators
################################################################################
function makemultiMNIST(; set=:training, digits=2, offset=4)
    if set == :training
        imgs, lbls = MNIST.traindata()
    elseif set == :test
        imgs, lbls = MNIST.testdata()
    end
    imgs = Float64.(imgs)
    x = size(imgs, 1)
    y = size(imgs, 2)
    n = size(imgs, 3)
    newimgs = zeros(x+2offset, y+2offset, n)
    inds = [randperm(n) for i in 1:digits]
    for i in 1:n
        for j in 1:digits
            Δx, Δy = rand(-offset:offset, 2)
            newimgs[1+offset-Δx:x+offset-Δx, 1+offset-Δy:y+offset-Δy, i] = max.(
                imgs[:, :, inds[j][i]],
                newimgs[1+offset-Δx:x+offset-Δx, 1+offset-Δy:y+offset-Δy, i]
            )
        end
    end
    newlbls = [lbls[inds[i]] for i in 1:digits]
    newlbls = collect(zip(newlbls...))
    return newimgs, newlbls
end # function makemultiMNIST
end # module DataHelpers
