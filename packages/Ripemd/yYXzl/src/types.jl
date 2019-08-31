
abstract type RIPEMD_CTX end

mutable struct RIPEMD160_CTX <: RIPEMD_CTX
    state  :: Array{UInt32, 1} # length 5
    count  :: UInt64           # how many bytes we already ingested
    buffer :: Array{UInt8, 1}  # message is copied here, read as UInt32 in
                               # transform!
end

# length of the buffer
bytes_per_block(::Type{RIPEMD160_CTX}) = 64
words_per_block(::Type{RIPEMD160_CTX}) = 16

state_type(::Type{RIPEMD160_CTX}) = UInt32
digest_length(::Type{RIPEMD160_CTX}) = 20

function RIPEMD160_CTX()
    RIPEMD160_CTX(copy(INIT_STATE), 0 , zeros(UInt8, bytes_per_block(RIPEMD160_CTX)))
end
