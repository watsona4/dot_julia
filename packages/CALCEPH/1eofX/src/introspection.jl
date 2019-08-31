"""
    timeScale(eph)

   Retrieve the timescale associated with ephemeris handler eph
   Returns 1 for TDB and 2 for TCB.

"""
function timeScale(eph::Ephem)
    @_checkPointer eph.data "Ephemeris is not properly initialized!"
    return ccall((:calceph_gettimescale , libcalceph), Cint,
                  (Ptr{Cvoid},),eph.data)
end

"""
    PositionRecord

    stores position record metadata.
"""
struct PositionRecord
   " Naif Id of target "
   target::Int
   " Naif Id of center "
   center::Int
   " start of epoch span "
   startEpoch::Float64
   "end of epoch span"
   stopEpoch::Float64
   "frame : 1 for ICRF"
   frame::Int
end

"""
    positionRecords(eph)

   Retrieve position records metadata in ephemeris associated to
   handler eph .

"""
function positionRecords(eph::Ephem)
    res = Array{PositionRecord,1}()
    @_checkPointer eph.data "Ephemeris is not properly initialized!"
    NR::Int = ccall((:calceph_getpositionrecordcount , libcalceph), Cint,
    (Ptr{Cvoid},),eph.data)
    (NR == 0) && throw(CALCEPHException("Could not find any position records!"))
    target = Ref{Cint}(0)
    center = Ref{Cint}(0)
    startEpoch = Ref{Cdouble}(0.0)
    stopEpoch = Ref{Cdouble}(0.0)
    frame = Ref{Cint}(0)
    for i=1:NR
       stat = ccall((:calceph_getpositionrecordindex , libcalceph), Cint,
                  (Ptr{Cvoid},Cint,Ref{Cint},Ref{Cint},Ref{Cdouble},Ref{Cdouble},Ref{Cint}),
                  eph.data, i ,target,center,startEpoch,stopEpoch,frame)
       if (stat!=0)
          push!(res,PositionRecord(target[],center[],startEpoch[],stopEpoch[],frame[]))
       end
    end

    return res
end

"""
    OrientationRecord

    stores orientation record metadata.
"""
struct OrientationRecord
   " Naif Id of target "
   target::Int
   " start of epoch span "
   startEpoch::Float64
   "end of epoch span"
   stopEpoch::Float64
   "frame : 1 for ICRF"
   frame::Int
end

"""
    orientationRecords(eph)

   Retrieve orientation records metadata in ephemeris associated to
   handler eph .

"""
function orientationRecords(eph::Ephem)
    res = Array{OrientationRecord,1}()
    @_checkPointer eph.data "Ephemeris is not properly initialized!"
    NR::Int = ccall((:calceph_getorientrecordcount , libcalceph), Cint,
    (Ptr{Cvoid},),eph.data)
    (NR == 0) && throw(CALCEPHException("Could not find any orientation records!"))
    target = Ref{Cint}(0)
    startEpoch = Ref{Cdouble}(0.0)
    stopEpoch = Ref{Cdouble}(0.0)
    frame = Ref{Cint}(0)
    for i=1:NR
       stat = ccall((:calceph_getorientrecordindex , libcalceph), Cint,
                  (Ptr{Cvoid},Cint,Ref{Cint},Ref{Cdouble},Ref{Cdouble},Ref{Cint}),
                  eph.data, i ,target,startEpoch,stopEpoch,frame)
       if (stat!=0)
          push!(res,OrientationRecord(target[],startEpoch[],stopEpoch[],frame[]))
       end
    end

    return res
end
