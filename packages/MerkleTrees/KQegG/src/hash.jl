using SHA: sha256

"""
Double sha256 function
"""
function hash256(x::Vector{UInt8})
    return sha256(sha256(x))
end
