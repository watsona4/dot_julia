"""

    HASLER_AND_SUSSTRUNK_M3 <: NoReferenceIQI
    M =  hasler_and_susstrunk_m3(img)

Calculates the colorfulness of a natural image using method M3 from
[1]. As a guide to interpretation of results, the authors suggest:

| Attribute           | M3 |
|:--------------------|----|
| Not colorful        |  0 |
| slightly colorful   | 15 |
| moderately colorful | 33 |
| averagely colorful  | 45 |
| quite colorful      | 59 |
| highly colorful     | 82 |
| extremely colorful  |109 |

[1] Hasler, D. and Süsstrunk, S.E., 2003, June. Measuring colorfulness
in natural images. In Human vision and electronic imaging VIII
(Vol. 5007, pp. 87-96). International Society for Optics and
Photonics.

"""
struct HASLER_AND_SUSSTRUNK_M3 <: NoReferenceIQI end

# api
(iqi::HASLER_AND_SUSSTRUNK_M3)(img) = hasler_and_susstrunk_m3(img)

@doc (@doc HASLER_AND_SUSSTRUNK_M3)
function hasler_and_susstrunk_m3(img::AbstractArray{<:AbstractRGB})

    R = 255 .* float(red.(img))
    G = 255 .* float(green.(img))
    B = 255 .* float(blue.(img))

    rg = R .- G 
    μrg, σrg = mean(rg), std(rg)
   
    yb = 0.5 .* (R .+ G) .- B
    μyb,  σyb = mean(yb), std(yb)

    μrgyb = sqrt(μrg^2 + μyb^2)
    σrgyb = sqrt(σrg^2 + σyb^2)

    return σrgyb + 0.3 * μrgyb

end

hasler_and_susstrunk_m3(img::GenericGrayImage) = 0

"""
     M =  colorfulness(img)
     M =  colorfulness(HASLER_AND_SUSSTRUNK_M3(), img)

Measures the colorfulness of a natural image. Uses the
[`HASLER_AND_SUSSTRUNK_M3`](@ref) method by default.

See also: [`HASLER_AND_SUSSTRUNK_M3`](@ref).

"""
colorfulness(m::HASLER_AND_SUSSTRUNK_M3, img) = m(img)

colorfulness(img) = HASLER_AND_SUSSTRUNK_M3()(img)


