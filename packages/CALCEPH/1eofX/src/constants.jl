
const _maxConstName = 33
const _maxConstValue = 1024

"""
   constants(eph)

   Retrieve the constants stored in the ephemeris associated to handle eph as a dictionary

"""
function constants(eph::Ephem)
    res = Dict{Symbol,Any}()
    @_checkPointer eph.data "Ephemeris is not properly initialized!"
    NC::Int = ccall((:calceph_getconstantcount , libcalceph), Cint,
    (Ptr{Cvoid},),eph.data)
    value = Ref{Cdouble}(0.0)
    name = Vector{UInt8}(undef,_maxConstName)
    for i=1:NC
       numberOfValues = ccall((:calceph_getconstantindex , libcalceph), Cint,
                  (Ptr{Cvoid},Cint,Ptr{UInt8},Ref{Cdouble}),
                  eph.data, i ,name ,value)
       if (numberOfValues==1)
          res[Symbol(strip(unsafe_string(pointer(name))))] = value[]
       elseif (numberOfValues>1)
          values = Array{Float64,1}(undef,numberOfValues)
          stat = ccall((:calceph_getconstantvd , libcalceph), Cint,
                  (Ptr{Cvoid},Ptr{UInt8},Ptr{Cdouble}, Cint),
                  eph.data, name ,values, numberOfValues)
          if (stat>0)
             res[Symbol(strip(unsafe_string(pointer(name))))] = values
          end
       else
          numberOfValues = ccall((:calceph_getconstantvs , libcalceph), Cint,
                  (Ptr{Cvoid},Ptr{UInt8},Ptr{Ptr{Char}}, Cint),
                  eph.data, name ,C_NULL, 0)
          if (numberOfValues>0)
             storage = Array{UInt8}(undef,_maxConstValue,numberOfValues)
             stat = ccall((:calceph_getconstantvs , libcalceph), Cint,
             (Ptr{Cvoid},Ptr{UInt8},Ptr{UInt8}, Cint),
             eph.data, name ,storage, numberOfValues)
             if (stat>0)
                 values = [ strip(unsafe_string(pointer(storage,i))) for i in 1:_maxConstValue:length(storage) ]
                 if (numberOfValues==1)
                    res[Symbol(strip(unsafe_string(pointer(name))))] = values[1]
                 else
                    res[Symbol(strip(unsafe_string(pointer(name))))] = values
                 end
             end
          end
       end
    end

    return res
end
