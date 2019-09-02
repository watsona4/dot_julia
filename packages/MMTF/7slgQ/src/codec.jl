include("converters.jl")

"""
A function to run length decode an int array.
in_array: the input array of integers
"""
function runlengthdecode(in_array::Array{T,1}) where {T<:Integer}
    switch=false
    out_array=Int32[]
    this_item = 0
    for item in in_array
        if switch==false
            this_item = item
            switch=true
        else
            switch=false
            for i=1:item
                push!(out_array,Int32(this_item))
            end
        end
    end
    return out_array
end

"""
A function to run length decode an int array.
in_array: the inptut array of integers
"""
function runlengthencode(in_array::Array{T,1}) where {T<:Integer}
    if length(in_array)==0
        return Int32[]
    end
    curr_ans = in_array[1]
    out_array = Int32[curr_ans]
    counter = 1
    for in_int in in_array[2:end]
        if in_int == curr_ans
            counter+=1
        else
            push!(out_array, Int32(counter))
            push!(out_array, Int32(in_int))
            curr_ans = in_int
            counter = 1
        end
    end
    # Add the final counter
    push!(out_array, Int32(counter))
    return out_array
end

"""
A function to delta decode an int array.
in_array: the input array of integers
"""
function deltadecode(in_array::Array{T,1}) where {T<:Integer}
    if length(in_array) == 0
        return Int32[]
    end
    this_ans = in_array[1]
    out_array = Int32[this_ans]
    for i = 2:length(in_array)
        this_ans += in_array[i]
        push!(out_array,Int32(this_ans))
    end
    return out_array
end

"""
A function to delta decode an int array.
in_array: the input array to be delta encoded
"""
function deltaencode(in_array::Array{T,1}) where {T<:Integer}
    if length(in_array)==0
        return Int32[]
    end
    curr_ans = in_array[1]
    out_array = Int32[curr_ans]
    for in_int in in_array[2:end]
        push!(out_array, Int32(in_int-curr_ans))
        curr_ans = in_int
    end
    return out_array
end

function deltarecursivefloatdecode(in_array::Array{UInt8,1}, param)
    return floats(deltadecode(recursiveindexdecode(ints(in_array,2))),param)
end

function deltarecursivefloatencode(in_array::Array{Float32,1}, param)
    return bytes(recursiveindexencode(deltaencode(ints(in_array,param)))) 
end

function runlengthfloatdecode(in_array::Array{UInt8,1}, param)
    return floats(runlengthdecode(ints(in_array,4)),param)
end

function runlengthfloatencode(in_array::Array{Float32,1}, param)
    return bytes(runlengthencode(ints(in_array,param)))
end

function runlengthdeltaintdecode(in_array::Array{UInt8,1})
    return deltadecode(runlengthdecode(ints(in_array, 4)))
end

function runlengthdeltaintencode(in_array::Array{T,1}) where {T<:Integer}
    return bytes(runlengthencode(deltaencode(in_array)))
end

function runlengthchardecode(in_array::Array{UInt8,1})
    return chars(runlengthdecode(ints(in_array, 4)))
end

function runlengthcharencode(in_array::Array{Char,1})
    return bytes(runlengthencode(ints(in_array)))
end

function stringdecode(in_array::Array{UInt8,1})
    return decodechainlist(in_array)
end

function stringencode(in_array::Array{String,1})
    return encodechainlist(in_array)
end

#1-byte Int decode
function intdecode(in_array::Array{UInt8,1})
    return ints(in_array, 1)
end

#1-byte Int encode
function intencode(in_array::Array{Int8,1})
    return bytes(in_array)
end

#4-byte Int decode
function fourbyteintdecode(in_array::Array{UInt8,1})
    return ints(in_array, 4)
end

#4-byte Int encode
function fourbyteintencode(in_array::Array{Int32,1})
    return bytes(in_array)
end

"""
Parse the header of an input byte array and then decode using the input array,
the codec and the appropirate parameter.
input_array: the array to be decoded
"""
function decodearray(input_array::Array{UInt8,1})
    codec, length, param, input_array = parseheader(input_array)
    if codec == 10
        return deltarecursivefloatdecode(input_array, param)
    elseif codec == 9
        return runlengthfloatdecode(input_array, param)
    elseif codec == 8
        return runlengthdeltaintdecode(input_array)
    elseif codec == 6
        return runlengthchardecode(input_array)
    elseif codec == 5
        return stringdecode(input_array)
    elseif codec == 2
        return intdecode(input_array)
    elseif codec == 4
        return fourbyteintdecode(input_array)
    else
        throw(ArgumentError("Invalid codec while parsing MMTF data!"))
    end
end

"""
Encode the array using the method and then add the header to this array.
input_array: the array to be encoded
codec: the integer index of the codec to use
param: the integer parameter to use in the function
"""
function encodearray(input_array::Array{T,1}, codec, param) where {T<:Union{Real,Char,String}}
    if codec == 10
        return addheader(deltarecursivefloatencode(input_array, param), codec, length(input_array), param)
    elseif codec == 9
        return addheader(runlengthfloatencode(input_array, param), codec, length(input_array), param)
    elseif codec == 8
        return addheader(runlengthdeltaintencode(input_array), codec, length(input_array), param)
    elseif codec == 6
        return addheader(runlengthcharencode(input_array), codec, length(input_array), param)
    elseif codec == 5
        return addheader(stringencode(input_array), codec, length(input_array), param)
    elseif codec == 2
        return addheader(intencode(input_array), codec, length(input_array), param)
    elseif codec == 4
        return addheader(fourbyteintencode(input_array), codec, length(input_array), param)
    else
        throw(ArgumentError("Invalid codec while encoding to MMTF data!"))
    end
end