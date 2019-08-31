PRE_CHECKING_ON = true

"Check preconditions"
pre_check_on!() = (global PRE_CHECKING_ON=true)
pre_check_off!() = (global PRE_CHECKING_ON=false)
pre_check()::Bool = (global PRE_CHECKING_ON; PRE_CHECKING_ON::Bool)

"""
Activate precondition checking within scope of expr

```jldoctest
julia> f(x::Real) = (@pre x > 0; sqrt(x) + 5)
f (generic function with 1 method)

julia> f(-3)
ERROR: DomainError:
Stacktrace:
 [1] f(::Int64) at ./REPL[2]:1

julia> @with_pre begin
               f(-3)
             end
ERROR: ArgumentError: x > 0
Stacktrace:
```
"""
macro with_pre(expr)
  quote
    try
      pre_check_on!()
      $(esc(expr))
      pre_check_off!()
    catch e
      pre_check_off!()
      rethrow(e)
    end
  end
end

"""
Macroless version of `@with_pre`

```jldoctest
julia> f(x::Real) = (@pre x > 0; sqrt(x) + 5)
f (generic function with 1 method)

julia> f(-3)
ERROR: DomainError:
Stacktrace:
 [1] f(::Int64) at ./REPL[2]:1

julia> with_pre() do
         f(-3)
       end
ERROR: ArgumentError: x > 0
```
"""
function with_pre(thunk)
  pre_check_on!()
  res = thunk()
  pre_check_off!()
  res
end


"""
Define a precondition on function argument.
Currently `@pre` works similarly to `@assert` except that:
 1) an exception is thrown
 2) pre_check_ons can be disabled

```jldoctest
julia> f(x::Real) = (@pre x > 0; sqrt(x) + 5)
f (generic function with 1 method)

julia> f(-3)
ERROR: ArgumentError: x > 0
```

"""
macro pre(pred)
  quote
    if pre_check()
      if !$(esc(pred))
        errterm = string($(Meta.quot(pred)))
        throw(ArgumentError(errterm))
      end
    end
  end
end

"""
Pre with a comment
# FIXME: redundancy
"""
macro pre(pred, desc)
  quote
    if pre_check()
      if !$(esc(pred))
        desc = $(esc(desc))
        errterm = string($(Meta.quot(pred)), ", ", desc)
        throw(ArgumentError(errterm))
      end
    end
  end
end


"""
Define a postcondition on function argument.

Currently `@post` works similarly to `@assert` except that:
 1) an exception is thrown
 2) post_check_ons can be disabled

```jldoctest
julia> f(x::Real) = (@post x > 0; sqrt(x) + 5)
f (generic function with 1 method)

julia> f(-3)
ERROR: ArgumentError: x > 0
```

"""
macro post(retval, pred...)
  # quote
  #   if pre_check()
  #     if !$(esc(pred))
  #       errterm = string($(Meta.quot(pred)))
  #       throw(ArgumentError(errterm))
  #     end
  #   end
  #   $(esc(retval))
  # end
end

"Define invariant - currently a dummy for documenation"
macro invariant(args...)
end
