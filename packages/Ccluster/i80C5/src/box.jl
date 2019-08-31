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

mutable struct box
    _center_real_den::Int
    _center_real_num::Int
    _center_imag_den::Int
    _center_imag_num::Int
    _radius_den::Int
    _radius_num::Int
    _maxNbSols::Cint
    
    function box()
        z = new()
        ccall( (:compBox_init, :libccluster), 
             Nothing, (Ref{box},), 
                    z)
        finalizer(_box_clear_fn, z)
        return z
    end
    
    function box(re::fmpq, im::fmpq, width::fmpq)
        z = new()
        
        ccall( (:compBox_init, :libccluster), 
             Nothing, (Ref{box},), 
                    z)
        ccall( (:compBox_set_3realRat, :libccluster), 
             Nothing, (Ref{box}, Ref{fmpq}, Ref{fmpq}, Ref{fmpq}), 
                    z,        re,      im,       width)
        finalizer(_box_clear_fn, z)
        return z
    end
    
    function box(b::box)
        z = new()
        
        ccall( (:compBox_init, :libccluster), 
             Nothing, (Ref{box},), 
                    z)
        ccall( (:compBox_set, :libccluster), 
             Nothing, (Ref{box}, Ref{box}), 
                       z,        b)
        finalizer(_box_clear_fn, z)
        return z
    end
    
#     function box(re::fmpq, im::fmpq, width::fmpq, nbSols::Int)
#         z = new()
#         
#         ccall( (:compBox_init, :libccluster), 
#              Nothing, (Ref{box},), 
#                     &z)
#         ccall( (:compBox_set_3realRat_int, :libccluster), 
#              Nothing, (Ref{box}, Ref{fmpq}, Ref{fmpq}, Ref{fmpq}, Int), 
#                     &z,        &re,       &im,       &width,   nbSols)
#         finalizer(z, _box_clear_fn)
#         return z
#     end
end

function _box_clear_fn(d::box)
    ccall( (:compBox_clear, :libccluster), 
         Nothing, (Ref{box},), 
                d)
end

function getCenterRe(d::box)
    res = fmpq(0,1)
    ccall( (:compBox_get_centerRe, :libccluster), 
             Nothing, (Ref{fmpq}, Ref{box}), 
                    res,      d)
    return res
end

function getCenterIm(d::box)
    res = fmpq(0,1)
    ccall( (:compBox_get_centerIm, :libccluster), 
             Nothing, (Ref{fmpq}, Ref{box}), 
                    res,      d)
    return res
end

function getWidth(d::box)
    res = fmpq(0,1)
    ccall( (:compBox_get_bwidth, :libccluster), 
             Nothing, (Ref{fmpq}, Ref{box}), 
                    res,      d)
    return res
end

function getMaxNbSols(d::box)
    return Int(d._maxNbSols)
end

function toStr(d::box)
    res = ""
    res = res * "Box: center: $(getCenterRe(d))" 
    res = res * " + i*$(getCenterIm(d))"
    res = res * ", width: $(getWidth(d))"
    res = res * ", max nb of sols: $(d._maxNbSols)"
    return res
end
