"""
    orient(eph,jd0,time,target,unit)

Compute Euler angles and first derivative for the orientation of target at
epoch jd0+time.
To get the best precision for the interpolation, the time is split in two
floating-point numbers. The argument jd0 should be an integer and time should
be a fraction of the day. But you may call this function with time=0 and jd0,
the desired time, if you don't take care about precision.

# Arguments
- `eph`: ephemeris
- `jd0::Float64`: jd0+time must be equal to the Julian Day for the time coordinate corresponding to the ephemeris (usually TDB or TCB)
- `time::Float64`: jd0+time must be equal to the Julian Day for the time coordinate corresponding to the ephemeris (usually TDB or TCB)
- `target::Integer`: The body whose orientation is required. The numbering system depends on the parameter unit.
- `unit::Integer` : The units of the result. This integer is a sum of some unit constants (unit*) and/or the constant useNaifId. If the unit contains useNaifId, the NAIF identification numbering system is used for the target and the center. If the unit does not contain useNaifId, the old number system is used for the target and the center (see the list in the documentation of function compute). The angles are expressed in radians if unit contains unitRad. If the unit contains outputNutationAngles, the nutation angles are computed rather than the Euler angles.

"""
function orient(eph::Ephem,jd0::Float64,time::Float64,
   target::Integer,unit::Integer)
    @_checkPointer eph.data "Ephemeris is not properly initialized!"
    result = Array{Float64,1}(undef,6)
    stat = unsafe_orient!(result,eph,jd0,time,target,unit)
    @_checkStatus stat "Unable to compute ephemeris"
    return result
end

"""
    unsafe_orient!(result,eph,jd0,time,target,unit)

In place version of the orient function. Does not perform any checks!
Compute Euler angles and first derivative for the orientation of target
at epoch jd0+time.
To get the best precision for the interpolation, the time is split in two
floating-point numbers. The argument jd0 should be an integer and time should
be a fraction of the day. But you may call this function with time=0 and jd0,
the desired time, if you don't take care about precision.

# Arguments
- `result`: container for result. It is not checked if it is sufficiently large enough!
- `eph`: ephemeris
- `jd0::Float64`: jd0+time must be equal to the Julian Day for the time coordinate corresponding to the ephemeris (usually TDB or TCB)
- `time::Float64`: jd0+time must be equal to the Julian Day for the time coordinate corresponding to the ephemeris (usually TDB or TCB)
- `target::Integer`: The body whose orientation is required. The numbering system depends on the parameter unit.
- `unit::Integer` : The units of the result. This integer is a sum of some unit constants (unit*) and/or the constant useNaifId. If the unit contains useNaifId, the NAIF identification numbering system is used for the target and the center. If the unit does not contain useNaifId, the old number system is used for the target and the center (see the list in the documentation of function compute). If the unit contains outputNutationAngles, the nutation angles are computed rather than the Euler angles.

# Return:
- status integer from CALCEPH: 0 if an error occured

"""
function unsafe_orient!(result,eph::Ephem,jd0::Float64,time::Float64,
   target::Integer,unit::Integer)
    stat = ccall((:calceph_orient_unit, libcalceph), Cint,
    (Ptr{Cvoid},Cdouble,Cdouble,Cint,Cint,Ref{Cdouble}),
    eph.data,jd0,time,target,unit,result)
    return stat
end

"""
    orient(eph,jd0,time,target,unit,order)

Compute Euler angles and derivatives up to order for the orientation of target
at epoch jd0+time.
To get the best precision for the interpolation, the time is split in two
floating-point numbers. The argument jd0 should be an integer and time should
be a fraction of the day. But you may call this function with time=0 and jd0,
the desired time, if you don't take care about precision.

# Arguments
- `eph`: ephemeris
- `jd0::Float64`: jd0+time must be equal to the Julian Day for the time coordinate corresponding to the ephemeris (usually TDB or TCB)
- `time::Float64`: jd0+time must be equal to the Julian Day for the time coordinate corresponding to the ephemeris (usually TDB or TCB)
- `target::Integer`: The body whose orientation is required. The numbering system depends on the parameter unit.
- `unit::Integer` : The units of the result. This integer is a sum of some unit constants (unit*) and/or the constant useNaifId. If the unit contains useNaifId, the NAIF identification numbering system is used for the target and the center. If the unit does not contain useNaifId, the old number system is used for the target and the center (see the list in the documentation of function compute). If the unit contains outputNutationAngles, the nutation angles are computed rather than the Euler angles.
- `order::Integer` : The order of derivatives
    * 0: only the angles are computed.
    * 1: only the angles and 1st derivatives are computed.
    * 2: only the angles, the 1st derivatives and 2nd derivatives are computed.
    * 3: the angles, the 1st derivatives, 2nd derivatives and 3rd derivatives are computed.

"""
function orient(eph::Ephem,jd0::Float64,time::Float64,
   target::Integer,unit::Integer,order::Integer)
    @_checkPointer eph.data "Ephemeris is not properly initialized!"
    @_checkOrder order
    result = Array{Float64,1}(undef,3+3order)
    stat = unsafe_orient!(result,eph,jd0,time,target,unit,order)
    @_checkStatus stat "Unable to compute ephemeris"
    return result
end

"""
    unsafe_orient!(result,eph,jd0,time,target,unit,order)

In place version of the orient function. Does not perform any checks!
Compute Euler angles and derivatives up to order for the orientation of target
at epoch jd0+time.
To get the best precision for the interpolation, the time is split in two
floating-point numbers. The argument jd0 should be an integer and time should
be a fraction of the day. But you may call this function with time=0 and jd0,
the desired time, if you don't take care about precision.

# Arguments
- `result`: container for result. It is not checked if it is sufficiently large enough!
- `eph`: ephemeris
- `jd0::Float64`: jd0+time must be equal to the Julian Day for the time coordinate corresponding to the ephemeris (usually TDB or TCB)
- `time::Float64`: jd0+time must be equal to the Julian Day for the time coordinate corresponding to the ephemeris (usually TDB or TCB)
- `target::Integer`: The body whose orientation is required. The numbering system depends on the parameter unit.
- `unit::Integer` : The units of the result. This integer is a sum of some unit constants (unit*) and/or the constant useNaifId. If the unit contains useNaifId, the NAIF identification numbering system is used for the target and the center. If the unit does not contain useNaifId, the old number system is used for the target and the center (see the list in the documentation of function compute). If the unit contains outputNutationAngles, the nutation angles are computed rather than the Euler angles.
- `order::Integer` : The order of derivatives
    * 0: only the angles are computed.
    * 1: only the angles and 1st derivatives are computed.
    * 2: only the angles, the 1st derivatives and 2nd derivatives are computed.
    * 3: the angles, the 1st derivatives, 2nd derivatives and 3rd derivatives are computed.

    # Return:
    - status integer from CALCEPH: 0 if an error occured

"""
function unsafe_orient!(result,eph::Ephem,jd0::Float64,time::Float64,
   target::Integer,unit::Integer,order::Integer)
    stat = ccall((:calceph_orient_order, libcalceph), Cint,
    (Ptr{Cvoid},Cdouble,Cdouble,Cint,Cint,Cint,Ref{Cdouble}),
    eph.data,jd0,time,target,unit,order,result)
    return stat
end
