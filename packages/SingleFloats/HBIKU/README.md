# SingleFloats.jl
Float32 results are computed using Float64s

#### Copyright © 2015-2019 by Jeffrey Sarnoff.
####  This work is released under The MIT License.

----
[![Travis Build Status](https://travis-ci.org/JeffreySarnoff/SingleFloats.jl.svg?branch=master)](https://travis-ci.org/JeffreySarnoff/SingleFloats.jl) [![codecov](https://codecov.io/gh/JeffreySarnoff/SingleFloats.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JeffreySarnoff/SingleFloats.jl)
----

There is one export, the type `Single32`.  Use it in place of `Float32` for results that are more reliable,
reporting numerical results with greater accuracy through the low-order bits of significands' precision.

`Single32` values look like `Float32` values and act like `Float32` values.  Their computational results
are exceed the expectations for accuracy with `Float32s`.  With relatively stable algorithms, `Single32s`
are much better at preserving information present in significands' low-order bits.

Mathematical operations with `Single32s` are computed using `Float64` internally.  To get the benefit
that they afford, it is __necessary__ that you do not reach inside these values to see or to use any
part that is not shown in regular use.  This works only if the values you provide are Float32s and
the values you obtain are Float32s.

The translation from an array of `Float32` to an array of `Single32` is done with broadcasting.
After completing the computational work, the translation back to `Float32` is just as easy:
```
using SingleFloats

               # original_data must be Float32

data_at_work   = Single32.(original_data)
value_obtains  = process(data_at_work)
result_of_work = Float32.(value_obtains)

               # result_of_work must be Float32
```

The intent is to provide robust coverage of `Float32` ops.  Let me know of requests. PRs welcome.

----

### Additional reliability comes with using `Single32s`.

```
using SingleFloats

xs_fwd(::Type{T}) where T = T.(collect(1.0:20.0))
ys_fwd(::Type{T}) where T = cot.(xs_fwd(T))
sumfwd(::Type{T}) where T = sum(ys_fwd(T))

xs_rev(::Type{T}) where T = reverse(xs_fwd(T))
ys_rev(::Type{T}) where T = cot.(xs_rev(T))
sumrev(::Type{T}) where T = sum(ys_rev(T))

epsmax(a, b) = eps(max(a, b))

function muddybits(::Type{T}) where T
   fwd = sumfwd(T)
   rev = sumrev(T)
   muddy = round(Int32, abs(fwd - rev) / epsmax(fwd, rev))

   lsbits = 31 - leading_zeros(muddy)
   return max(0, lsbits)
end


#  How many low-order bits of these type's significands have become
#  opaque, replacing confirmatory valuation with inessential noise?

(Single32 = muddybits(Single32),
 Float32  = muddybits(Float32),
 Float64  = muddybits(Float64))

(Single32 = 0, Float32 = 6, Float64 = 7)


```
