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

# saveBoxForDebug = []

mutable struct connComp
#   list of boxes 
    _boxes_begin::Ptr{Cvoid}
    _boxes_end::Ptr{Cvoid}
    _boxes_size::Cint
    _boxes_clear::Ptr{Cvoid}
#     _list_of_boxes::listBox
#   width: fmpq 
    _width_den::Int
    _width_num::Int
#   infRe: fmpq
    _infRe_den::Int
    _infRe_num::Int
#   supRe: fmpq
    _supRe_den::Int
    _supRe_num::Int
#   infIm: fmpq
    _infIm_den::Int
    _infIm_num::Int
#   supIm: fmpq
    _supIm_den::Int
    _supIm_num::Int
#   nSols: int
    _nSols::Cint
#   nwSpd: fmpz
    _nwSpd::Int
#   appPr: int
    _appPr::Int
#   newSu: int
    _newSu::Cint
#   isSep: int
    _isSep::Cint
    
    function connComp()
        z = new()
        ccall( (:connCmp_init, :libccluster), 
             Nothing, (Ref{connComp},), 
                    z)
#         finalizer(z, _connComp_clear_fn)
        finalizer(_connComp_clear_fn, z)
        return z
    end
    
#     function connComp(b::box)
#         push!(saveBoxForDebug, b)
#         z = new()
#         ccall( (:connCmp_init_compBox, :libccluster), 
#              Nothing, (Ref{connComp}, Ref{box}), 
#                     &z,            &b)
#         finalizer(z, _connComp_clear_fn)
#         return z
#     end
    
end

function _connComp_clear_fn(cc::connComp)
    ccall( (:connCmp_clear, :libccluster), 
         Nothing, (Ref{connComp},), 
                cc)
end

function copy_Ptr( cc::Ref{connComp} )
    res = ccall( (:connCmp_copy, :libccluster), 
                  Ptr{connComp}, (Ref{connComp},), 
                        cc )
    return res
end

function getNbSols(cc::connComp)
    return Int(cc._nSols)
end

function getNbBoxes(cc::connComp)
    return Int(cc._boxes_size)
end

function getComponentBox(cc::connComp, initialBox::box)
    
    res = box()
    ccall( (:connCmp_componentBox, :libccluster), 
             Nothing, (Ref{box}, Ref{connComp}, Ref{box}), 
                    res,      cc,           initialBox);
    return res
    
end

function pop( cc::connComp )
    res = ccall( (:connCmp_pop, :libccluster), 
                  Ref{box}, (Ref{connComp},), 
                                 cc)                        
    resobj::box = unsafe_load(res)
    return resobj
end

function isEmpty(cc::connComp)
    res = ccall( (:connCmp_is_empty, :libccluster), 
                  Cint, (Ref{connComp},), 
                        cc )
    return Bool(res)
end
