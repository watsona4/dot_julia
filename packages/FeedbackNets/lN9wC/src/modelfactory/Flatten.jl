module Flatten

export flatten

"""
    flatten(x)

Turns a high-dimensional array (e.g., a batch of feature maps) into a 2-d array,
linearizing all except the last (batch) dimension.
"""
flatten(x) = reshape(x, :, size(x, ndims(x)))

end # module Flatten
