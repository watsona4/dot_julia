"""
    SSIM([kernel], [(α, β, γ)]) <: FullReferenceIQI
    assess(iqi::SSIM, img, ref)
    ssim(img, ref)

Structural similarity (SSIM) index is an image quality assessment method based
on degradation of structural information.

The SSIM index is composed of three components: luminance, contrast, and
structure; `ssim = 𝐿ᵅ * 𝐶ᵝ * 𝑆ᵞ`, where `W := (α, β, γ)` controls relative
importance of each components. By default `W = (1.0, 1.0, 1.0)`.

In practice, a mean version SSIM is used. At each pixel, SSIM is calculated
locally with neighborhoods weighted by `kernel`, returning a ssim map;
`ssim` is actaully `mean(ssim_map)`.
By default `kernel = KernelFactors.gaussian(1.5, 11)`.

!!! info

    SSIM is defined only for gray images. RGB images are treated as 3d Gray
    images. General `Color3` images are converted to RGB images first, in which
    case, you could manually expand them using `channelview` if you don't want
    them converted to RGB first.

# Example

`ssim(img, ref)` should be sufficient to get a benchmark for algorithms. One
could also instantiate a customed SSIM, then pass it to `assess` or use it as a
function. For example:

```julia
iqi = SSIM(KernelFactors.gaussian(2.5, 17), (1.0, 1.0, 2.0))
assess(iqi, img, ref)
iqi(img, ref)
```

# Reference

[1] Wang, Z., Bovik, A. C., Sheikh, H. R., & Simoncelli, E. P. (2004). Image quality assessment: from error visibility to structural similarity. _IEEE transactions on image processing_, 13(4), 600-612.

[2] Wang, Z., Bovik, A. C., Sheikh, H. R., & Simoncelli, E. P. (2003). The SSIM Index for Image Quality Assessment. Retrived May 30, 2019, from http://www.cns.nyu.edu/~lcv/ssim/
"""
struct SSIM <: FullReferenceIQI
    kernel::AbstractArray{<:Real}
    W::NTuple{3}
    function SSIM(kernel, W)
        ndims(kernel) == 1 || throw(ArgumentError("only 1-d kernel is valid"))
        issymetric(kernel) || @warn "SSIM kernel is assumed to be symmetric"
        all(W .>= 0) || throw(ArgumentError("(α, β, γ) should be non-negative, instead it's $(W)"))
        new(kernel, W)
    end
end

# default values from [1]
const SSIM_KERNEL = KernelFactors.gaussian(1.5, 11) # kernel
const SSIM_W = (1.0, 1.0, 1.0) # (α, β, γ)
SSIM(kernel=SSIM_KERNEL) = SSIM(kernel, SSIM_W)

# api
# By default we don't crop the padding boundary to meet the ssim result from
# MATLAB Image Processing Toolbox, which is used more broadly than the original
# implementaion [2] (written in MATLAB as well).
# TODO: add keyword argument "crop=false" for compatibility
# -- Johnny Chen <johnnychen94@hotmail.com>
(iqi::SSIM)(x, ref) = mean(_ssim_map(iqi, x, ref))

@doc (@doc SSIM)
ssim(x, ref) = SSIM()(x, ref)

# Parameters `(K₁, K₂)` are used to avoid instability when denominator is very
# close to zero. Different from origianl implementation [2], we don't make it
# public since the ssim result is insensitive to these parameters according to
# [1].
# -- Johnny Chen <johnnychen94@hotmail.com>
const SSIM_K = (0.01, 0.03)

# SSIM is defined only for gray images,
# RGB images are treated as 3d gray images,
# other Color3 images are converted to RGB first.
function _ssim_map(iqi::SSIM, x::GenericGrayImage, ref::GenericGrayImage, peakval = 1.0, K = SSIM_K)
    if size(x) ≠ size(ref)
        err = ArgumentError("images should be the same size, instead they're $(size(x))-$(size(ref))")
        throw(err)
    end
    α, β, γ = iqi.W
    C₁, C₂ = @. (peakval * K)^2
    C₃ = C₂/2

    T = promote_type(float(eltype(ref)), float(eltype(x)))
    x = of_eltype(T, x)
    ref = of_eltype(T, ref)

    # calculate ssim in the neighborhood of each pixel, weighted by window
    window = kernelfactors(Tuple(repeated(iqi.kernel, ndims(ref))))

    μx = imfilter(x, window)   # equation (14) in [1]
    μy = imfilter(ref, window) # equation (14) in [1]
    μx² = μx .* μx
    μy² = μy .* μy
    μxy = μx .* μy
    σx² = imfilter(x.^2, window) .- μx²     # equation (15) in [1]
    σy² = imfilter(ref.^2, window) .- μy²   # equation (15) in [1]
    σxy = imfilter(x .* ref, window) .- μxy # equation (16) in [1]

    if [α, β, γ] ≈ [1.0, 1.0, 1.0]
        # equation (13) in [1]
        ssim_map = @. ((2μxy + C₁)*(2σxy + C₂))/((μx²+μy²+C₁)*(σx² + σy² + C₂))
    else
        σx_σy = @. sqrt(σx²*σy²)
        l = @. (2μxy + C₁)/(μx² + μy²) # equation (6) in [1]
        c = @. (2σx_σy + C₂)/(σx² + σy² + C₂) # equation (9) in [1]
        s = @. (σxy + C₃)/(σx_σy + C₃) # equation (10) in [1]

        ssim_map = @. l^α * c^β * s^γ # equation (12) in [1]
    end
    return ssim_map
end

_ssim_map(iqi::SSIM,
          x::AbstractArray{<:AbstractRGB},
          ref::AbstractArray{<:AbstractRGB},
          peakval = 1.0, K = SSIM_K) =
    _ssim_map(iqi, channelview(x), channelview(ref), peakval, K)

_ssim_map(iqi::SSIM,
          x::AbstractArray{<:Color3},
          ref::AbstractArray{<:Color3},
          peakval = 1.0, K = SSIM_K) =
    _ssim_map(iqi, of_eltype(RGB, x), of_eltype(RGB, ref), peakval, K)


# helpers
function issymetric(kernel)
    origin = first(axes(kernel, 1))
    center = (length(kernel)-1) ÷ 2 + origin
    kernel[origin:center] ≈ kernel[end:-1:center]
end
