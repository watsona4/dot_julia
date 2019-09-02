function htonofarray(array::AbstractArray{T,1}) where {T<:Union{Real,Char}}
    return [hton(x) for x in array]
end

function ntohofarray(array::AbstractArray{T,1}) where {T<:Union{Real,Char}}
    return [ntoh(x) for x in array]
end

"""
Parse the header and return it along with the input array minus the header. 
Returns the codec, the length of the decoded array, the parameter and the remainder
of the array
"""
function parseheader(input_array::Array{UInt8,1})
    codec, length, param = htonofarray(reinterpret(Int32,input_array[1:12]))
    return codec,length,param,input_array[13:end]
end

""" 
Add the header to the appropriate array
"""
function addheader(input_array::Array{UInt8,1}, codec::Integer, length::Integer, param::Integer)
    out_array=UInt8[]
    append!(out_array, reinterpret(UInt8,[ntoh(Int32(codec))])) 
    append!(out_array, reinterpret(UInt8,[ntoh(Int32(length))])) 
    append!(out_array, reinterpret(UInt8,[ntoh(Int32(param))]))
    append!(out_array, input_array)
end