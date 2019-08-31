function update!(ctx::T, data::U) where {T <: RIPEMD160_CTX,
                                         U <: Union{DenseArray{UInt8, 1},
                                                    NTuple{N, UInt8} where N}}
    UIntXXX = typeof(ctx.count)

    len = convert(UIntXXX, length(data))
    data_idx = convert(UIntXXX, 0)
    usedspace = ctx.count % bytes_per_block(T)

    while len - data_idx + usedspace >= bytes_per_block(T)
        copyto!(ctx.buffer, usedspace + 1,
                data,       data_idx + 1,
                bytes_per_block(T))

        transform!(ctx)

        ctx.count += bytes_per_block(T) - usedspace
        data_idx += bytes_per_block(T) - usedspace
        usedspace = convert(UIntXXX, 0)
    end

    if len > data_idx
        copyto!(ctx.buffer, usedspace + 1,
                data,       data_idx + 1,
                len - data_idx)
        ctx.count += len - data_idx
    end
    return nothing
end

function pad_remainder!(ctx::T) where {T <: RIPEMD160_CTX}

    @inbounds begin

        usedspace = ctx.count % bytes_per_block(T)

        if usedspace > 0
            usedspace += 1
            ctx.buffer[usedspace] = 0x80

            # do we have space for a UInt64?
            if usedspace <= bytes_per_block(T) - sizeof(ctx.count)
                # space for UInt64 so fill with 0x0 except the last UInt64
                for i = (usedspace + 1):(length(ctx.buffer) - sizeof(ctx.count))
                    ctx.buffer[i] = 0x0
                end
            else
                # no space for UInt64 fill out everything, transform and fill with
                # 0x0
                for i = (usedspace + 1):length(ctx.buffer)
                    ctx.buffer[i] = 0x0
                end
                transform!(ctx)
                for i = 1:bytes_per_block(T)
                    ctx.buffer[i] = 0x0
                end
            end
        else # usedspace == 0
            ctx.buffer[1] = 0x80
            for i = 2:bytes_per_block(T)
                ctx.buffer[i] = 0x0
            end
        end
    end
    return nothing
end

function digest!(ctx::T) where {T <: RIPEMD160_CTX}
    pad_remainder!(ctx)

    # bitcount_idx = div(words_per_block(T), sizeof(ctx.count)) + 1
    pbuf = Ptr{typeof(ctx.count)}(pointer(ctx.buffer))
    unsafe_store!(pbuf, UInt64(ctx.count * 8), 8)

    transform!(ctx)

    # TODO: is this safe for 0.7? the [1:end] should make a copy and get around
    # the lazy reinterpret.
    return reinterpret(UInt8, ctx.state)[1:digest_length(T)]
end
