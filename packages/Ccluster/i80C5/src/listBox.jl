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

mutable struct listBox
    _begin::Ptr{Cvoid}
    _end::Ptr{Cvoid}
    _size::Cint
    _clear::Ptr{Cvoid}
    
    function listBox()
        z = new()
        ccall( (:compBox_list_init, :libccluster), 
             Nothing, (Ref{listBox},), 
                    z)
#         finalizer(z, _listBox_clear_fn)
#         finalizer(_listBox_clear_fn, z)
        return z
    end
end

function _listBox_clear_fn(lc::listBox)
    ccall( (:compBox_list_clear, :libccluster), 
         Nothing, (Ref{listBox},), 
                lc)
end

function isEmpty( lc::listBox )
    res = ccall( (:compBox_list_is_empty, :libccluster), 
                  Cint, (Ref{listBox},), 
                        lc )
    return Bool(res)
end

function pop( lc::listBox )
    res = ccall( (:compBox_list_pop, :libccluster), 
                  Ptr{box}, (Ref{listBox},), 
                                 lc)                        
    resobj::box = unsafe_load(res)
    return resobj
end


function push( lc::listBox, cc::box )
    ccall( (:compBox_list_push, :libccluster), 
             Nothing, (Ref{listBox}, Ref{box}), 
                    lc,               cc)
end


