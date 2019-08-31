

macro _checkStatus(stat,msg)
   return quote
      if ($(esc(stat)) == 0)
         throw(CALCEPHException($(esc(msg))))
      end
   end
end

macro _checkPointer(ptr,msg)
   return quote
      if ($(esc(ptr)) == C_NULL)
         throw(CALCEPHException($(esc(msg))))
      end
   end
end

macro _checkOrder(order)
   return quote
      local or = $(esc(order))
      if (or<0) || (or>3)
         throw(CALCEPHException("Order must be between 0 and 3."))
      end
   end
end

"""
    Ephem

  Ephemeris descriptor. Create with:

    eph = Ephem(filename)
    eph = Ephem([filename1,filename2...])

  The ephemeris descriptor will be used to access the ephemeris and related
  data stored in the specified files.

  Because, Julia GC is lazy, you may want to free the memory managed by eph
  before you get rid of the reference to eph with:

    finalize(eph)

  or after by forcing the GC to run:

    gc()

"""
mutable struct Ephem
   data :: Ptr{Cvoid}
   function Ephem(files::Vector{<:AbstractString})
      ptr = ccall((:calceph_open_array, libcalceph), Ptr{Cvoid},
                  (Int, Ptr{Ptr{UInt8}}), length(files), files)
      @_checkPointer ptr "Unable to open ephemeris file(s)!"
      obj = new(ptr)
      finalizer(_ephemDestructor,obj) # register object destructor
      return obj
   end
end

# to be called by gc when cleaning up
# not in the exposed interface but can be called with finalize(e)
function _ephemDestructor(eph::Ephem)
   if (eph.data == C_NULL)
      return
   end
   ccall((:calceph_close, libcalceph), Cvoid, (Ptr{Cvoid},), eph.data)
   eph.data = C_NULL
   return
end

Ephem(file::AbstractString) = Ephem([file])

"""
    prefetch(eph)

  This function prefetches to the main memory all files associated to the ephemeris descriptor eph.

"""
function prefetch(eph::Ephem)
    @_checkPointer eph.data "Ephemeris is not properly initialized!"
    stat = ccall((:calceph_prefetch, libcalceph), Int, (Ptr{Cvoid},), eph.data)
    @_checkStatus stat "Unable to prefetch  ephemeris!"
    return
end
