"""
    PSNR <: FullReferenceIQI
    psnr(x, ref [, peakval])
    assess(PSNR(), x, ref, [, peakval])

Peak signal-to-noise ratio (PSNR) is used to measure the quality of image in
present of noise and corruption.

For gray image `x`, PSNR (in dB) is calculated by
`10log10(peakval^2/mse(x, ref))`, where `peakval` is the maximum possible pixel
value of image `ref`. `x` will be converted to type of `ref` when necessary.

Generally, for non-gray image `x`, PSNR is reported against each channel of
`ref` and outputs a `Vector`, `peakval` needs to be a vector as well.

!!! info

    Conventionally, `m×n` rgb image is treated as `m×n×3` gray image. To
    calculated channelwise PSNR of rgb image, one could pass `peakval` as
    vector, e.g., `psnr(x, ref, [1.0, 1.0, 1.0])`
"""
struct PSNR <: FullReferenceIQI end

# api
(iqi::PSNR)(x, ref, peakval) = _psnr(x, ref, peakval)
(iqi::PSNR)(x, ref) = iqi(x, ref, peak_value(eltype(ref)))

@doc (@doc PSNR)
psnr(x, ref, peakval) = _psnr(x, ref, peakval)
psnr(x, ref) = psnr(x, ref, peak_value(eltype(ref)))


# implementation
""" Define the default peakval for colors, specialize gray and rgb to get scalar output"""
peak_value(::Type{T}) where T <: Colorant = gamutmax(T)
peak_value(::Type{T}) where T <: NumberLike = one(eltype(T))
peak_value(::Type{T}) where T <: AbstractRGB = one(eltype(T))

_psnr(x::GenericGrayImage, ref::GenericGrayImage, peakval::Real)::Real =
    20log10(peakval) - 10log10(mse(x, ref))

# convention & backward compatibility for RGB images
# m*n RGB images are treated as m*n*3 gray images
function _psnr(x::GenericImage{<:Color3}, ref::GenericImage{<:AbstractRGB},
               peakval::Real)::Real
    _psnr(channelview(of_eltype(eltype(ref), x)), channelview(ref), peakval)
end

# general channelwise definition: each channel is calculated independently
function _psnr(x::GenericImage{<:Color3}, ref::GenericImage{CT},
              peakvals)::Vector where {CT<:Color3}
    check_peakvals(CT, peakvals)

    newx = of_eltype(CT, x)
    cx, ax = channelview(newx), axes(newx)
    cref, aref = channelview(ref), axes(ref)
    [_psnr(view(cx, i, ax...),
           view(cref, i, aref...),
           peakvals[i]) for i in 1:length(CT)]
end
function _psnr(x::GenericGrayImage, ref::GenericGrayImage,
      peakval)::Vector
    check_peakvals(eltype(ref), peakval)

    [_psnr(x, ref, peakval[1]), ]
end

_length(x) = length(x)
_length(x::Type{T}) where T<:Number = 1
function check_peakvals(CT, peakvals)
    if _length(peakvals) ≠ _length(CT)
        err_msg = "peakvals for PSNR should be length-$(length(CT)) vector for $(base_colorant_type(CT)) images"
        throw(ArgumentError(err_msg))
    end
end
