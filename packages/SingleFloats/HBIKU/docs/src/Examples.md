# Examples


```
using SingleFloats

fwdxs(::Type{T}) where T  = T.(collect(1.0:20.0))
fwdys(::Type{T}) where T  = cot.(fwdxs(T))
fwdsum(::Type{T}) where T = sum(fwdys(T))

revxs(::Type{T}) where T  = reverse(fwdxs(T))
revys(::Type{T}) where T  = cot.(revxs(T))
revsum(::Type{T}) where T = sum(revys(T))

function muddybits(::Type{T}) where T
   fwd = fwdsum(T)
   rev = revsum(T)
   epsavg = eps((fwd + rev)/2)
   muddy = round(Int32, abs(fwd - rev) / epsavg)
   lsbits = 31 - leading_zeros(muddy)
   return max(0, lsbits)
end


(Single32 = muddybits(Single32),
 Float32  = muddybits(Float32),
 Float64  = muddybits(Float64))

(Single32 = 0, Float32 = 6, Float64 = 7)
```

```julia
using SingleFloats, LinearAlgebra, Random
Random.seed!(7865);

mat_f32 = rand(Float32, 7, 7);
mat_s32 = Single32.(mat_f32);
mat_big  = BigFloat.(mat_f32);

detinv_big = Float32(det(inv(mat_big)));
detinv_f32 = det(inv(mat_f32));
detinv_s32 = det(inv(mat_s32));

julia> (detinv_big - detinv_f32), (detinv_big - Float32.(detinv_s32))
(1.5258789f-5, 0.0f0)
```
