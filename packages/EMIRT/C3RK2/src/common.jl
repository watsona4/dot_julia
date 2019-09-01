#=doc
Utilities
=#

export crop_array_border

"""
throwaway the border region of an array (ndims > 3), currently only works for 3D cropsize.
"""
function crop_array_border(arr::Array, cropsize::Union{Vector,Tuple})
    @assert ndims(arr) >= 3
    sz = size(arr)
    @assert sz[1]>cropsize[1]*2 &&
            sz[2]>cropsize[2]*2 &&
            sz[3]>cropsize[3]*2
    return arr[ cropsize[1]+1:sz[1]-cropsize[1],
                cropsize[2]+1:sz[2]-cropsize[2],
                cropsize[3]+1:sz[3]-cropsize[3]]
end
