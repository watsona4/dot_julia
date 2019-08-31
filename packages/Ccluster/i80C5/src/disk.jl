#
#  Copyright (C) 2018 Remi Imbach
#
#  This file is part of Ccluster.
#
#  Ccluster is free software: you can redistribute it and/or modify it under
#  the terms of the GNU Lesser General Public License (LGPL) as published
#  by the Free Software Foundation; either version 2.1 of the License, or
#  (at your option) any later version.  See <http://www.gnu.org/licenses/>.
#

mutable struct disk
    _center_real_den::Int
    _center_real_num::Int
    _center_imag_den::Int
    _center_imag_num::Int
    _radius_den::Int
    _radius_num::Int
    
    function disk()
        z = new()
        ccall( (:compDsk_init, :libccluster), 
             Nothing, (Ref{disk},), 
                    z)
#         finalizer(z, _disk_clear_fn)
        finalizer(_disk_clear_fn, z)
        return z
    end
    
    function disk(re::fmpq, im::fmpq, rad::fmpq)
        z = new()
        
        ccall( (:compDsk_init, :libccluster), 
             Nothing, (Ref{disk},), 
                    z)
        ccall( (:compDsk_set_3realRat, :libccluster), 
             Nothing, (Ref{disk}, Ref{fmpq}, Ref{fmpq}, Ref{fmpq}), 
                    z,        re,       im,       rad)
#         finalizer(z, _disk_clear_fn)
        finalizer(_disk_clear_fn, z)
        return z
    end
end

function _disk_clear_fn(d::disk)
    ccall( (:compDsk_clear, :libccluster), 
         Nothing, (Ref{disk},), 
                d)
end

function getCenterRe(d::disk)
    res = fmpq(0,1)
    ccall( (:compDsk_get_centerRe, :libccluster), 
             Nothing, (Ref{fmpq}, Ref{disk}), 
                    res,      d)
    return res
end

function getCenterIm(d::disk)
    res = fmpq(0,1)
    ccall( (:compDsk_get_centerIm, :libccluster), 
             Nothing, (Ref{fmpq}, Ref{disk}), 
                    res,      d)
    return res
end

function getRadius(d::disk)
    res = fmpq(0,1)
    ccall( (:compDsk_get_radius, :libccluster), 
             Nothing, (Ref{fmpq}, Ref{disk}), 
                    res,      d)
    return res
end

function inflateDisk(d::disk, ratio::fmpq)
    res = disk()
    ccall( (:compDsk_inflate_realRat, :libccluster), 
             Nothing, (Ref{disk}, Ref{disk}, Ref{fmpq}), 
                    res,      d,        ratio)
    return res
end

function isSeparated(d::disk, qMainLoop::listConnComp, qResults::listConnComp, qAllResults::listConnComp, discardedCcs::listConnComp )
    res = ccall( (:ccluster_compDsk_is_separated_DAC, :libccluster), 
                   Cint, (Ref{disk}, Ref{listConnComp}, Ref{listConnComp}, Ref{listConnComp}, Ref{listConnComp}), 
                          d,        qMainLoop,       qResults,           qAllResults,       discardedCcs)
    return Bool(res)
end
    
function toStr(d::disk)
    res = ""
    res = res * "Disk: center: $(getCenterRe(d))" 
    res = res * " + i*$(getCenterIm(d))"
    res = res * ", radius: $(getRadius(d))"
    return res
end

# function isDiskInDisk(d1::disk, d2::disk)
#     RR = RealField(64)
#     #compute the square of the distance between the center of d1 and the center of d2
#     dist::fmpq = (getCenterRe(d1)-getCenterRe(d2))^2 + (getCenterIm(d1)-getCenterIm(d2))^2
#     if dist>= (getRadius(d2))^2
#         return false
#     end
#     sqrtdist::arb = sqrt(RR(dist))+RR(getRadius(d1))
#     if sqrtdist <= RR(getRadius(d2))
#         return true
#     else 
#         return false
#     end
#     
#     
# end
    
