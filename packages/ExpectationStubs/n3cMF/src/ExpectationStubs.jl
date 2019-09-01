module ExpectationStubs
using MacroTools
export @stub, @expect, Stub, all_expectations_used, @used, @usecount

include("donotcare.jl")
include("vectordict.jl")

struct SyntaxError <: Exception
end

"""
   ExpectationValueMismatchError

Similar to a julia MethodError
This is thrown if a call was made on a stub,
but the values/types did not match those that were expected.
"""
struct ExpectationValueMismatchError <: Exception
    name
    argvals
end



#########################################################


struct Stub{name} <: Function
    expectations::VectorDict{Any, Any}
    calls::Vector{Any}
end
Stub(name)=Stub{name}(VectorDict{Any, Any}(), Vector{Any}())


function(stub::Stub{name})(args...) where {name}
    if !haskey(stub.expectations, args)
        throw(ExpectationValueMismatchError(name, args))
    end
    push!(stub.calls, args)

    stub.expectations[args]
end

"""
    usecount(stub:Stub, arg)

Returns how many times the `stub` has been called with a matching argument
"""
function usecount(stub::Stub, arg)
    net = 0
    for call_record in stub.calls
        if call_record == arg
            net+=1
        end
    end
    net
end

"""
    @stub(name)

Declares that you will be making a stub function called `name`.
The key difference between a stub and a julia function,
is that stubs can have values for arguements declared,
which must match, as well as having types which must match.
Also they are simpler, in that they can not varying their return result based on argument.

Once you have declared a stub,
you should use `@expect` to declare what it should respond to.

Calling methods that do not exist (with values provided), will result in Errors.
This is intentional, as the stub exists to check that your function is only called with the arguements that you say are valid.
"""
macro stub(name)
    quote
        $(esc(name))=Stub($(QuoteNode(name)))
    end
end

"""
    onlyesc(v)

Like `esc`, except it ignores things that can not be escaped.
Eg literals.

Internal use
"""
onlyesc(v::Any)=v
onlyesc(v::Union{Symbol,Expr})=esc(v)

"""
    split_vals_and_sig(argsexpr)

Takes an expression from a function definition's args
eg `:([a::Int, ::Integer])`
and breaks it down into the values, and the types.
When value is not given it subsitutes `DoNotCare()`,
when type is not given it subsitutes `typeof(val)`
Returns a tuple of each, with all things in expression/symbol form.

Internal use
"""
function split_vals_and_sig(argsexpr)
    vals=Expr(:tuple)
    sig=Expr(:tuple)
    for term in argsexpr
        if @capture(term, v_::s_)
            push!(vals.args, onlyesc(v))
            push!(sig.args, s)
        elseif @capture(term, ::s_)
            push!(vals.args, :(DoNotCare{$(esc(s))}()))
            push!(sig.args, s)
        elseif @capture(term, v_)
            push!(vals.args, onlyesc(v))
            push!(sig.args, :(typeof($(onlyesc(v)))))
        else
            throw(SyntaxError())
        end
    end
    vals, sig
end



"""
    @expect(defn)

Prepares a stub, lets it know to expect a function call matching the `defn`,
and to return the result.

Has several forms, which align to julia function declations.
Examples:

- `@expect(foo(1, 1.5)=10)` this prepares the stub `foo`, to return 10, if it gets given the input `(1, 1.5)`
- `@expect(foo(3, ::Int)=20)` this prepares the stub `foo`, to return 20, if it gets given the input with first arguement 3, and second argument any `Int`
- `@expect(foo(5, ::Any)=30)` this prepares the stub `foo`, to return 30, if it gets given the input with first arguement 5, and second argument any type
- `@expect(foo(Any, ::Any)=40)` this prepares the stub `foo`, to return 40, if it is given 2 arguements

Notes that you can not for the same stub both the declare that it is bound by type (i.e. that it can take anything of a given type),
and declare that it is bound by value, for the same parameter.

Note that the result can not depend on the arguments of the function.
This is intentional, as it is there to keep your Stubs simple and to the point.
So you don't end up needing to test your tests.

Currently does not support KWArgs.
"""
macro expect(defn)
    @capture(defn, name_(args__)=ret_) || throw(SyntaxError())
    argvals, sig = split_vals_and_sig(args)
    quote
        ###########################################################
        # Check not already regeistered
        if haskey($(esc(name)).expectations, $(argvals))
            @warn "Expectation already set" name=$(Meta.quot(name)) argvals=$(argvals) sig=$(sig)
        end


        # actually register the value
        $(esc(name)).expectations[$(argvals)] = $(esc(ret))
    end |> unblock |>  MacroTools.striplines
end

"""
    all_expectations_used(stub::Stub)

Checks that every expectation setup for the stub was actually used.
It is good to have this as a sanity check at the end of your test script using the stub.
"""
function all_expectations_used(stub::Stub)
    all(usecount.(Ref(stub), keys(stub.expectations)) .> 0)
end


"""
    @used(defn)

Returns true if a particular expectionation was used.
Syntax is similar to `@expect`


Like `@expect` the key can be a value or a type.
It does not have to match to the one that was used in `@expect`

Normally one would used this inside a test:

- `@test @used(foo(1, 1.5))` test that `foo` was called with `(1, 1.5)`
- `@test @used(foo(3, ::Int))` test the `foo` was called with 3 and some Int
- `@test !@used(foo(5, ::Any))` test that `foo` was never called with the first arg 5 (and exactly 2 args)
- `@test !@used(foo(Any, ::Any))` test tjat `foo` was never alled with 2 args
"""
macro used(defn)
    name, argvals, sig = name_argvals_and_sig(defn)
    :(usecount($(esc(name)), $(argvals)) > 0)
end

"""
    @usecount(defn)

Like `@used` but returns the count of how many times the particular expectation 
was called.

Syntax is the same.
"""
macro usecount(defn)
    name, argvals, sig = name_argvals_and_sig(defn)
   :(usecount($(esc(name)), $(argvals)))
end


"""
    name_argvals_and_sig(defn)
Does the extraction of these as is needed for `@used` and `@usedcounts`
"""
function name_argvals_and_sig(defn)
    @capture(defn, name_(args__)) || throw(SyntaxError())
    argvals, sig = split_vals_and_sig(args)
    name, argvals, sig
end


end #Module
