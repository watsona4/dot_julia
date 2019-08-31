# Standard Callbacks

runall(f) = f
runall(fs::AbstractVector) = (data) -> foreach(f -> handlesignal(f(data)), fs)

@inline idcb(x) = x

"Higher order function that makes a callback run just once every n"
function everyn(callback, n::Integer)
  function everyncb(data)
    if data.i % n == 0
      return callback(data)
    else
      nothing
    end
  end
  return everyncb
end

"""Returns its inpu every after being called `n` times

```julia
everyn(10) → println
```
"""
function everyn(n::Integer)
  i = 0
  function everyncb(data)
    if i % n == 0
      i = i + 1
      return data
    else
      i = i + 1
      nothing
    end
  end
end

# Callback Augmenters

# From Flux
"""
Returns a function that when invoked, will only be triggered at most once
during `timeout` seconds. Normally, the throttled function will run
as much as it can, without ever going more than once per `wait` duration;
but if you'd like to disable the execution on the leading edge, pass
`leading=false`. To enable execution on the trailing edge, ditto.
"""
function throttle(f, timeout; leading = true, trailing = false) # From Flux (thanks!)
  cooldown = true
  later = nothing
  result = nothing

  function throttled(args...; kwargs...)
    yield()

    if cooldown
      if leading
        result = f(args...; kwargs...)
      else
        later = () -> f(args...; kwargs...)
      end

      cooldown = false
      @async try
        while (sleep(timeout); later != nothing)
          later()
          later = nothing
        end
      catch e
        rethrow(e)
      finally
        cooldown = true
      end
    elseif trailing
      later = () -> (result = f(args...; kwargs...))
    end

    return result
  end
end

"As the name suggests"
donothing(data) = nothing

"Show progress meter"
function showprogress(n)
  p = ProgressMeter.Progress(n, 1)
  function updateprogress(data)
    ProgressMeter.next!(p)
  end
end

"Stop if nans or Inf are present (-Inf) still permissible"
function stopnanorinf(data)
  if isnan(data.p)
    println("p is $(data.p)")
    throw(NaNError())
    return Stop
  elseif data.p == Inf
    println("p is $(data.p)")
    throw(InfError())
    return Stop
  end
end

"Capture a vector of value of type `T`

```julia
function f(x; cb)
  for i = 1:10
    x += 0.0
    cb(x)
  end
end

cb, xs = capturevals(:x)
f(0.5; cb = cb)
```
"
function capturevals(key::Symbol, ::Type{T} = Any) where T
  xs = T[]
  function innercap(data)
    x_ = getfield(data, key)
    push!(xs, x_)
    (vals = xs,)
  end
  (cb = innercap, capture = xs)
end