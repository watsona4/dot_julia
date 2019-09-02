# This file is part of the LittleEndianBase128 package
# (http://github.com/davidssmith/LittleEndianBase128.jl).
#
# The MIT License (MIT)
#
# Copyright (c) 2016 David Smith and Dong Wang
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

module LittleEndianBase128

export encode, decodesigned, decodeunsigned, decode

const version = v"0.0.3"

movesign(x::T) where T = signed(xor(x >>> one(T), -(x & one(T))))

encode(input::Array{Bool,N}) where N = encode(Array(reinterpret(UInt8, input)))

function encode(input::Array{T,N}) where T<:Unsigned where N
  # Encode array of unsigned integers using LEB128
  maxbytes = ceil(Int, 8*sizeof(T)/ 7)
  output = Array{UInt8}(undef, maxbytes*length(input))  # maximum possible length
  k = 1  # position of next write in output array
  for j in 1:length(input)
    if input[j] == 0
      output[k] = zero(T)
      k += 1
    else
      x = input[j]
      while x != 0
        output[k] = x & 0x7F | 0x80  # can simplify?
        k += 1
        x >>= 7
      end
      output[k-1] &= 0x7F
    end
  end
  return output[1:k-1]
end

encode(n::T) where T<:Unsigned = encode([n])

encode(n::Bool) = encode([n])

encode(n::T) where T<:Signed = encode(unsigned(xor(n << 1, n >> (8*sizeof(T)-1))))

encode(input::Array{T,N}) where T<:Signed where N = encode(map(n -> unsigned(xor(n << 1, n >> 63)), input))


function decodeunsigned(input::Array{UInt8,1}, dtype::DataType=UInt64, outsize::Integer=0)
  # Decode unsigned integer using LEB128
  if outsize == 0
    outsize = length(input) # if don't know, just allocate largest possible array
  end
  output = Array{dtype}(undef, outsize)
  j = 1  # position of next read in input array
  k = 1  # position of current write in output array
  while k <= length(output)
    output[k] = 0
    shift = 0
    while true
        byte = input[j]
        j += 1
        output[k] |= (dtype(byte & 0x7F) << shift)
        if (byte & 0x80 == 0) # replace with right shift 7?
          break
        end
        shift += 7
    end
    k += 1
    if j > length(input)
      break
    end
  end
  return output[1:k-1]
end

function decodesigned(input::Array{UInt8,1}, dtype::DataType=Int64, outsize::Integer=0)
  n = decodeunsigned(input, dtype, outsize)
  # undo zigzag encoding to retrieve the sign
  return movesign.(n)
end

function decode(input::Array{UInt8,1}, dtype::DataType=UInt64, outsize::Integer=0)
  udtypes = Dict(1 => UInt8, 2 => UInt16, 4 => UInt32, 8 => UInt64, 16 => UInt128)
  if dtype <: Signed
    udtype = udtypes[sizeof(dtype)]
    n = decodeunsigned(input, udtype, outsize)
    return movesign.(n)
  else
    n = decodeunsigned(input, dtype, outsize)
    return map(dtype, n)
  end
end

decode(input::UInt8, dtype::DataType=UInt64, outsize::Integer=0) = decode([input], dtype, outsize)

end
