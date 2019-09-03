module QNaNs

export qnan


if VERSION < v"0.6.9"
    if !isdefined(:xor)
        xor{T}(a::T, b::T) = (a $ b)
    end
end

#=
  A float64 quiet NaN is represented with these 2^52-2 UInt64 hexadecimal patterns:
    (positive) UnitRange(0x7ff8000000000000,0x7fffffffffffffff) has 2^51-1 realizations
    (negative) UnitRange(0xfff8000000000000,0xffffffffffffffff) has 2^51-1 realizations
  A float32 quiet NaN is represented with these 2^23-2 UInt32 hexadecimal patterns:
    (positive) UnitRange(0x7fc00000,0x7fffffff) has 2^22-1 realizations
    (negative) UnitRange(0xffc00000,0xffffffff) has 2^22-1 realizations
  A float16 quiet NaN is represented with these 2^10-2 UInt16 hexadecimal patterns:
    (positive) UnitRange(0x7e00,0x7fff) has 2^9-1 realizations
    (negative) UnitRange(0xfe00,0xffff) has 2^9-1 realizations
  Julia assigns its NaNs as quiet NaNs with a payload of zero and sign bit 0b0:
     0x7ff8000000000000, 0x7fc00000, 0x7e00.
=#

for (FL, SI, UI, UPos, UNeg) in [(:Float64, :Int64, :UInt64, :0x7ff8000000000000, :0xfff8000000000000),
                                 (:Float32, :Int32, :UInt32, :0x7fc00000, :0xffc00000),
                                 (:Float16, :Int16, :UInt16, :0x7e00, :0xfe00) ]
  @eval begin  
      function qnan(si::$(SI))
          u = reinterpret($(UI), abs(si))
          if (u > ~$(UNeg)) # 2^51-1, 2^22-1, 2^9-1
              throw(ArgumentError("The value $(si) exceeds the payload range."))
          end
          u |= signbit(si) ? $(UNeg) : $(UPos)
          return reinterpret($(FL),u)
      end

      function qnan(ui::$(UI))
          si = ui%($SI)
          u = reinterpret($(UI), abs(si))
          if (u > ~$(UNeg)) # 2^51-1, 2^22-1, 2^9-1
              throw(ArgumentError("The value $(si) exceeds the payload range."))
          end
          u |= signbit(si) ? $(UNeg) : $(UPos)
          return reinterpret($(FL),u)
      end
      
      function qnan(fp::$(FL))
          !isnan(fp) && throw(ArgumentError("The value $(fp) is not a NaN."))
          u = reinterpret($(UI), fp)
          a = u & ~$(UNeg)
          b =  reinterpret($(SI),a)
          return signbit(fp) ? -b : b
      end
   end
end

"""
  **qnan**(`si`::{Int64|32|16}) generates a quiet NaN with a payload of `si`  

  **qnan**(`fp`::{Float64|32|16}) recovers the signed integer payload from `fp`  
""" QNaNs

"""
  **qnan**(`si`::{Int64|32|16}) generates a quiet NaN with a payload of `si`  

  **qnan**(`fp`::{Float64|32|16}) recovers the signed integer payload from `fp`
""" qnan

end # module
