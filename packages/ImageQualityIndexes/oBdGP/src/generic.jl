"""
    abstract type ImageQualityIndex <: Any

Root of `ImageQualityIndexes` type hierarchy.

Classified by whether a reference image is needed, there are three more abstract types defined: [`FullReferenceIQI`](@ref), [`ReducedReferenceIQI`](@ref) and [`NoReferenceIQI`](@ref)

!!! info

    Image quality index is also known as image quality assessment, image quality metrics and image quality methods.

# References

[1] Wang, Z., & Bovik, A. C. (2006). _Modern Image Quality Assessment_. Morgan & Claypool Publishers.
"""
abstract type ImageQualityIndex end

"""
    abstract type FullReferenceIQI <: ImageQualityIndex
    assess(::FullReferenceIQI, img, ref_img, args...)

Image quality index that requires its reference to be complete/full image or image series.

See also: [`ImageQualityIndex`](@ref), [`ReducedReferenceIQI`](@ref), [`NoReferenceIQI`](@ref)
"""
abstract type FullReferenceIQI <: ImageQualityIndex end

"""
    abstract type ReducedReferenceIQI <: ImageQualityIndex
    assess(::ReducedReferenceIQI, img, ref_info, args...)

Image quality index that requires some information from reference image.

Different from [`FullReferenceIQI`](@ref), `ReducedReferenceIQI` doesn't need the complete reference image.

See also: [`ImageQualityIndex`](@ref), [`FullReferenceIQI`](@ref), [`NoReferenceIQI`](@ref)
"""
abstract type ReducedReferenceIQI <: ImageQualityIndex end

"""
    abstract type NoReferenceIQI <: ImageQualityIndex
    assess(::NoReferenceIQI, img, args...)

Image quality index that doesn't require any information.

See also: [`ImageQualityIndex`](@ref), [`FullReferenceIQI`](@ref), [`ReducedReferenceIQI`](@ref)
"""
abstract type NoReferenceIQI <: ImageQualityIndex end

@doc (@doc FullReferenceIQI)
assess(iqi::FullReferenceIQI, x, ref, args...) = iqi(x, ref, args...)

@doc (@doc ReducedReferenceIQI)
assess(iqi::ReducedReferenceIQI, x, ref, args...) = iqi(x, ref, args...)

@doc (@doc NoReferenceIQI)
assess(iqi::NoReferenceIQI, x, args...) = iqi(x, args...)
