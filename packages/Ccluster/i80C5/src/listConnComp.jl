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

mutable struct listConnComp
    _begin::Ptr{Cvoid}
    _end::Ptr{Cvoid}
    _size::Cint
    _clear::Ptr{Cvoid}
    
    function listConnComp()
        z = new()
        ccall( (:connCmp_list_init, :libccluster), 
             Nothing, (Ref{listConnComp},), 
                    z)
#         finalizer(z, _listConnComp_clear_fn)
        finalizer(_listConnComp_clear_fn, z)
        return z
    end
end

function _listConnComp_clear_fn(lc::listConnComp)
    ccall( (:connCmp_list_clear, :libccluster), 
         Nothing, (Ref{listConnComp},), 
                lc)
end

function isEmpty( lc::listConnComp )
    res = ccall( (:connCmp_list_is_empty, :libccluster), 
                  Cint, (Ref{listConnComp},), 
                        lc )
    return Bool(res)
end

function getSize(lc::listConnComp)
    return Int(lc._size)
end

function pop( lc::listConnComp )
    res = ccall( (:connCmp_list_pop, :libccluster), 
                  Ptr{connComp}, (Ref{listConnComp},), 
                                 lc)
    resobj::connComp = unsafe_load(res)
    return resobj
end

function pop_obj_and_ptr( lc::listConnComp )
    res = ccall( (:connCmp_list_pop, :libccluster), 
                  Ptr{connComp}, (Ref{listConnComp},), 
                                 lc)                        
    resobj::connComp = unsafe_load(res)
    return resobj, res
end


function push( lc::listConnComp, cc::connComp )
    ccall( (:connCmp_list_push, :libccluster), 
             Nothing, (Ref{listConnComp}, Ref{connComp}), 
                    lc,               cc)
end

function push_ptr( lc::listConnComp, cc::Ptr{connComp} )
    ccall( (:connCmp_list_push, :libccluster), 
             Nothing, (Ref{listConnComp}, Ref{connComp}), 
                    lc,               cc)
end


