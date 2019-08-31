"""
    rotAngMom(eph,jd0,time,target,unit)

Compute angular momentum due to rotation and first derivative of target at
epoch jd0+time.
To get the best precision for the interpolation, the time is splitted in two
floating-point numbers. The argument jd0 should be an integer and time should
be a fraction of the day. But you may call this function with time=0 and jd0,
the desired time, if you don't take care about precision.

# Arguments
- `eph`: ephemeris
- `jd0::Float64`: jd0+time must be equal to the Julian Day for the time coordinate corresponding to the ephemeris (usually TDB or TCB)
- `time::Float64`: jd0+time must be equal to the Julian Day for the time coordinate corresponding to the ephemeris (usually TDB or TCB)
- `target::Integer`: The body whose angular momentum is required. The numbering system depends on the parameter unit.
- `unit::Integer` : The units of the result. This integer is a sum of some unit constants (unit*) and/or the constant useNaifId. If the unit contains useNaifId, the NAIF identification numbering system is used for the target and the center. If the unit does not contain useNaifId, the old number system is used for the target and the center (see the list in the documentation of function compute). The angles are expressed in radians if unit contains unitRad.

"""
function rotAngMom(eph::Ephem,jd0::Float64,time::Float64,
   target::Integer,unit::Integer)
    @_checkPointer eph.data "Ephemeris is not properly initialized!"
    result = Array{Float64,1}(undef,6)
    stat = unsafe_rotAngMom!(result,eph,jd0,time,target,unit)
    @_checkStatus stat "Unable to compute ephemeris"
    return result
end

"""
    unsafe_rotAngMom!(result,eph,jd0,time,target,unit)

In place version of the rotAngMom function. Does not perform any checks!
Compute angular momentum due to rotation and first derivative of target at
epoch jd0+time.
To get the best precision for the interpolation, the time is splitted in two
floating-point numbers. The argument jd0 should be an integer and time should
be a fraction of the day. But you may call this function with time=0 and jd0,
the desired time, if you don't take care about precision.

# Arguments
- `result`: container for result. It is not checked if it is sufficiently large enough!
- `eph`: ephemeris
- `jd0::Float64`: jd0+time must be equal to the Julian Day for the time coordinate corresponding to the ephemeris (usually TDB or TCB)
- `time::Float64`: jd0+time must be equal to the Julian Day for the time coordinate corresponding to the ephemeris (usually TDB or TCB)
- `target::Integer`: The body whose angular momentum is required. The numbering system depends on the parameter unit.
- `unit::Integer` : The units of the result. This integer is a sum of some unit constants (unit*) and/or the constant useNaifId. If the unit contains useNaifId, the NAIF identification numbering system is used for the target and the center. If the unit does not contain useNaifId, the old number system is used for the target and the center (see the list in the documentation of function compute). The angles are expressed in radians if unit contains unitRad.

# Return:
- status integer from CALCEPH: 0 if an error occured

"""
function unsafe_rotAngMom!(result,eph::Ephem,jd0::Float64,time::Float64,
   target::Integer,unit::Integer)
    stat = ccall((:calceph_rotangmom_unit, libcalceph), Cint,
    (Ptr{Cvoid},Cdouble,Cdouble,Cint,Cint,Ref{Cdouble}),
    eph.data,jd0,time,target,unit,result)
    return stat
end

"""
    rotAngMom(eph,jd0,time,target,unit,order)

Compute angular momentum due to rotation and derivatives up to order of target
at epoch jd0+time.
To get the best precision for the interpolation, the time is splitted in two
floating-point numbers. The argument jd0 should be an integer and time should
be a fraction of the day. But you may call this function with time=0 and jd0,
the desired time, if you don't take care about precision.

# Arguments
- `eph`: ephemeris
- `jd0::Float64`: jd0+time must be equal to the Julian Day for the time coordinate corresponding to the ephemeris (usually TDB or TCB)
- `time::Float64`: jd0+time must be equal to the Julian Day for the time coordinate corresponding to the ephemeris (usually TDB or TCB)
- `target::Integer`: The body whose angular momentum is required. The numbering system depends on the parameter unit.
- `unit::Integer` : The units of the result. This integer is a sum of some unit constants (unit*) and/or the constant useNaifId. If the unit contains useNaifId, the NAIF identification numbering system is used for the target and the center. If the unit does not contain useNaifId, the old number system is used for the target and the center (see the list in the documentation of function compute).
- `order::Integer` : The order of derivatives
    * 0: only the angles are computed.
    * 1: only the angles and 1st derivatives are computed.
    * 2: only the angles, the 1st derivatives and 2nd derivatives are computed.
    * 3: the angles, the 1st derivatives, 2nd derivatives and 3rd derivatives are computed.

"""
function rotAngMom(eph::Ephem,jd0::Float64,time::Float64,
   target::Integer,unit::Integer,order::Integer)
    @_checkPointer eph.data "Ephemeris is not properly initialized!"
    @_checkOrder order
    result = Array{Float64,1}(undef,3+3order)
    stat = unsafe_rotAngMom!(result,eph,jd0,time,target,unit,order)
    @_checkStatus stat "Unable to compute ephemeris"
    return result
end

"""
    unsafe_rotAngMom!(result,eph,jd0,time,target,unit,order)

In place version of the rotAngMom function. Does not perform any checks!
Compute angular momentum due to rotation and derivatives up to order of target
at epoch jd0+time.
To get the best precision for the interpolation, the time is splitted in two
floating-point numbers. The argument jd0 should be an integer and time should
be a fraction of the day. But you may call this function with time=0 and jd0,
the desired time, if you don't take care about precision.

# Arguments
- `result`: container for result. It is not checked if it is sufficiently large enough!
- `eph`: ephemeris
- `jd0::Float64`: jd0+time must be equal to the Julian Day for the time coordinate corresponding to the ephemeris (usually TDB or TCB)
- `time::Float64`: jd0+time must be equal to the Julian Day for the time coordinate corresponding to the ephemeris (usually TDB or TCB)
- `target::Integer`: The body whose angular momentum is required. The numbering system depends on the parameter unit.
- `unit::Integer` : The units of the result. This integer is a sum of some unit constants (unit*) and/or the constant useNaifId. If the unit contains useNaifId, the NAIF identification numbering system is used for the target and the center. If the unit does not contain useNaifId, the old number system is used for the target and the center (see the list in the documentation of function compute).
- `order::Integer` : The order of derivatives
    * 0: only the angles are computed.
    * 1: only the angles and 1st derivatives are computed.
    * 2: only the angles, the 1st derivatives and 2nd derivatives are computed.
    * 3: the angles, the 1st derivatives, 2nd derivatives and 3rd derivatives are computed.

    # Return:
    - status integer from CALCEPH: 0 if an error occured

"""
function unsafe_rotAngMom!(result,eph::Ephem,jd0::Float64,time::Float64,
   target::Integer,unit::Integer,order::Integer)
    stat = ccall((:calceph_rotangmom_order, libcalceph), Cint,
    (Ptr{Cvoid},Cdouble,Cdouble,Cint,Cint,Cint,Ref{Cdouble}),
    eph.data,jd0,time,target,unit,order,result)
    return stat
end
