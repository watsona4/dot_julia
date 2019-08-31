# Error
# =====

"""
Decoding exception.
"""
struct DecodeError <: Exception
    msg::String
end

function Base.showerror(io::IO, error::DecodeError)
    print(io, "DecodeError: $(error.msg)")
end
