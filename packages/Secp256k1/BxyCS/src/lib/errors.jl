struct NotInField <: Exception end
Base.showerror(io::IO, e::NotInField) = print(io, "𝑛 is not within secp256k1 field")

struct NotOnCurve <: Exception end
Base.showerror(io::IO, e::NotOnCurve) = print(io, "Point is not on curve")

abstract type SignatureException <: Exception end

struct PrefixError <: SignatureException end
Base.showerror(io::IO, e::PrefixError) = print(io, "Incorrect signature prefix")

struct LengthError <: SignatureException end
Base.showerror(io::IO, e::LengthError) = print(io, "Encoded length does not match available data")
