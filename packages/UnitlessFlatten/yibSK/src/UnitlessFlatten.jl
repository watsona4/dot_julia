module UnitlessFlatten

using Flatten, Unitful

import Flatten: flatten, reconstruct, retype, update!

export @flattenable, @reflattenable, flattenable, flatten, construct, reconstruct, retype, update!, 
       tagflatten, fieldnameflatten, parentflatten, fieldtypeflatten, parenttypeflatten

flatten(x::Unitful.Quantity) = (x.val,) 
reconstruct(::T, data, n) where T <: Unitful.Quantity = (unit(T) * data[n],), n + 1
retype(::T, data, n) where T <: Unitful.Quantity = (unit(T) * data[n],), n + 1
update!(::T, data, n) where T <: Unitful.Quantity = (unit(T) * data[n],), n + 1

end # module
