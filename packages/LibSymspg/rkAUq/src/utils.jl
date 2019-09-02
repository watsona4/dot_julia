function char2Str(charTuple::Tuple{Vararg{UInt8}})
    cs = collect(charTuple)
    idx = 1
    for i in eachindex(cs)
        if cs[i] == 0
            break
        end
        idx = i
    end
    cs = Char.(cs[1:idx])

    return String(cs)
end

function rotsFromTuple(rotsTuple::Array{NTuple{9,Int32},1}, nop::Integer)
    r = Array{Int64,3}(undef, 3, 3, nop)
    for i in 1:nop
        r[:,:,i] = reshape([Base.convert(Int64, e) for e in rotsTuple[i]], 3, 3)
    end
    return r
end

function transFromTuple(transTuple::Array{NTuple{3,Float64}}, nop::Integer)
    t = Array{Float64,2}(undef, 3, nop)
    for i in 1:nop
        t[:,i] = [e for e in transTuple[i]]
    end
    return t
end
