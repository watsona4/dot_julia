module PrePostCall

import MacroTools: splitdef,combinedef,postwalk

export @pre,@post

function get_qargs_for_call(x::Array{Any,1})
    args = map(x) do a
        isa(a,Expr) && return Expr(:quote,:($(a.args[1])))
        return Expr(:quote,:($a))
    end
end

function get_args_for_call(x::Array{Any,1})
    args = map(x) do a
        isa(a,Expr) && return (a.args[1])
        return a
    end
end

"""
    @pre function name ...
 
Create a macro `@name [[variable] variable ...] function other ...` for inserting a call to `name` before each call to `other`.

`variable` defines the variable names passed to `name`. If `variable` is omitted the names of the attributes of `name` are used.
If multiple variables are given `name` is called on each of them, for example:

- `@name x y z` is just a short notation for `@name x @name y @name z` and calls `name(x)`, `name(y)`, `name(z)`
- `@name x,y,z` calls `name(x,y,z)`

# Examples
```jldoctest
julia> @pre function nonzero(x::Int)
           @assert x!=0
       end
@nonzero (macro with 2 methods)

julia> @nonzero @nonzero y function foo(x::Int,y::Int)
           x+y
       end
foo (generic function with 1 method)
```
The outer `@nonzero` uses `x` as the attribute due to the function definition of `nonzero`.
```jldoctest
julia> foo(1,2)
3

julia> foo(1,0)
ERROR: AssertionError: x != 0

julia> foo(0,1)
ERROR: AssertionError: x != 0
```

"""
macro pre(cfun)
    def = splitdef(cfun)
    mname = QuoteNode(Symbol("@$(def[:name])"))
    return esc(quote
               # Define the actual function
               $cfun
               # Define the macro without explicit variable definition
               macro $(def[:name])(fun)
                   # If the head is a macro call evaluate this macro first.
                   # In order to function properly the pre and post macros
                   # must be evaluated from insided to outside
                   if fun.head == :macrocall
                       fun = macroexpand(@__MODULE__,fun)
                   end
                   _def = PrePostCall.splitdef(fun)
                   # Insert the function call as first element in the body
                   insert!(_def[:body].args,1,Expr(:call,$(def[:name]),$(PrePostCall.get_qargs_for_call(def[:args])...)))
                   esc(PrePostCall.combinedef(_def))
               end
               # Define the macro with explicit variable definition
               macro $(def[:name])(arg,fun)
                   # If multiple explicit variables are defined expand them on the function call
                   arg = isa(arg,Symbol) ? arg : Expr(:...,arg)
                   if fun.head == :macrocall
                       fun = macroexpand(@__MODULE__,fun)
                   end
                   _def = PrePostCall.splitdef(fun)
                   # The only difference to the macro without the explicit definition is,
                   # that the passed variables are used for the function call
                   insert!(_def[:body].args,1,Expr(:call,$(def[:name]),:($arg)))
                   esc(PrePostCall.combinedef(_def))
               end
               macro $(def[:name])(args...)
                   # The second attribute to a macrocall expression is always a
                   # LineNumberNode. Here I replaced it by nothing.
                   clast = Expr(:macrocall,$mname, nothing,args[end-1], args[end])
                   for i in length(args)-2:-1:1
                       clast = Expr(:macrocall,$mname, nothing,args[i], clast)
                   end
                   return esc(clast)
               end
               end)
end

"""
    @post function name ...
 
Create a macro `@name [[variable] variable ...] function other ...` for inserting a call to `name` after each call to `other`.

`variable` defines the variable names passed to `name`. If `variable` is omitted, `name` is called on the return argument of `other`.
If `variable` is used, the call to `other` is inserted before each `return`, or if non present, as last expression in `other`.
If multiple variables are given `name` is called on each of them, for example:

- `@name x y z` is just a short notation for `@name x @name y @name z` and calls `name(x)`, `name(y)`, `name(z)`
- `@name x,y,z` calls `name(x,y,z)`

# Examples
```jldoctest
julia> @post function nonzero(x::Int)
           @assert x!=0
       end
@nonzero (macro with 2 methods)

julia> @nonzero function foo(x::Int,y::Int)
           x*y
       end
foo (generic function with 1 method)

julia> foo(1,2)
2

julia> foo(1,0)
ERROR: AssertionError: x != 0

julia> @nonzero @nonzero a function foo(x::Int,y::Int)
           a = x-1
           return a*y
       end
foo (generic function with 1 method)

julia> foo(1,2)
ERROR: AssertionError: x != 0
```
Failes because `a` must be nonzero
```jldoctest
julia> foo(2,2)
2

julia> foo(2,0)
ERROR: AssertionError: x != 0
```
Failes because the return value must be nonzero

"""
macro post(cfun)
    def = splitdef(cfun)
    # In case the check function has multiple arguments the return value
    # must be expanded
    # This is only used for the macro without explicit variable definition.
    retExpr = length(def[:args])==1 ? :(Expr(:call,$(def[:name]),:($ret))) : :(Expr(:call,$(def[:name]),Expr(:...,:($ret))))
    mname = QuoteNode(Symbol("@$(def[:name])"))
    return esc(quote
               $cfun
               # Define the macro without explicit variable definition
               # This macro nests the function call insided a new equally named funciton.
               macro $(def[:name])(fun)
                   # If the head is a macro call evaluate this macro first.
                   # In order to function properly the pre and post macros
                   # must be evaluated from insided to outside
                   if fun.head == :macrocall
                       fun = macroexpand(@__MODULE__,fun)
                   end
                   # Dict for the new function
                   _def = PrePostCall.splitdef(fun)
                   # Dict for the original function
                   _fun = copy(_def)
                   # Get a unique name for the return value variable
                   ret = gensym("ret")    
                   # Get a unique name for the now nested original function
                   name = gensym(_def[:name])
                   _fun[:name] = name
                   # Define the function body of the new function
                   _def[:body] = Expr(:block,
                                      # Insert original function now as local and renamed
                                      PrePostCall.combinedef(_fun),
                                      # Store the return value in ret
                                      Expr(Symbol("="),:($ret),Expr(:call,:($name),:($(PrePostCall.get_args_for_call(_def[:args])...)))),
                                      # Evaluate the ckeck function
                                      $retExpr,
                                      # Return the return value
                                      Expr(:return,:($ret))                    
                                      )
                   esc(PrePostCall.combinedef(_def))
               end
               # Define the macro with explicit variable definition
               # This macro add the check function call before each return statement,
               # or if none where found as the last expression of the original function
               macro $(def[:name])(arg,fun)
                   # If multiple explicit variables are defined expand them on the function call
                   arg = isa(arg,Symbol) ? arg : Expr(:...,arg)
                   if fun.head == :macrocall
                       fun = macroexpand(@__MODULE__,fun)
                   end
                   _def = PrePostCall.splitdef(fun)
                   # Counter to check if the function has return statements
                   found = 0
                   # Walk through the expression an search for return statements
                   _def[:body] = PrePostCall.postwalk(_def[:body]) do l
                       # Add the check function call before the return statement
                       if isa(l,Expr) && l.head == :return
                           found += 1
                           return Expr(:block,Expr(:call,$(def[:name]),:($arg)),l)
                       end
                       return l
                   end
                   # No return statement was found add the call after the last expression
                   if found == 0
                       push!(_def[:body].args,Expr(:block,Expr(:call,$(def[:name]),:($arg)),:nothing))
                   end
                   esc(PrePostCall.combinedef(_def))
               end
               macro $(def[:name])(args...)
                   # The second attribute to a macrocall expression is always a
                   # LineNumberNode. Here I replaced it by nothing.
                   clast = Expr(:macrocall,$mname, nothing,args[end-1], args[end])
                   for i in length(args)-2:-1:1
                       clast = Expr(:macrocall,$mname, nothing,args[i], clast)
                   end
                   return esc(clast)
               end
               end)
end

end # module
