module Kwonly
export @add_kwonly

try
    using Core: UndefKeywordError
catch
    # UndefKeywordError added in: RFC: required keyword arguments
    # https://github.com/JuliaLang/julia/pull/25830/files
    struct UndefKeywordError <: Exception
        var::Symbol
    end
    Base.showerror(io::IO, ex::UndefKeywordError) =
        print(io, "UndefKeywordError: keyword argument $(ex.var) not assigned")
end

"""
    @add_kwonly function_definition

Define keyword-only version of the `function_definition`.

    @add_kwonly function f(a, b; c=1, d=2)
        ...
    end

expands to:

    function f(x; y=1)
        ...
    end
    function f(; x = throw(UndefKeywordError(:x)), y=1)
        ...
    end
"""
macro add_kwonly(ex)
    esc(add_kwonly(ex))
end

add_kwonly(ex::Expr) = add_kwonly(Val{ex.head}, ex)

function add_kwonly(::Type{<: Val}, ex)
    error("add_kwonly does not work with expression $(ex.head)")
end

function add_kwonly(::Union{Type{Val{:function}},
                            Type{Val{:(=)}}}, ex::Expr)
    body = ex.args[2:end]  # function body
    default_call = ex.args[1]  # e.g., :(f(a, b=2; c=3))
    kwonly_call = add_kwonly(default_call)
    if kwonly_call === nothing
        return ex
    end

    return quote
        begin
            $ex
            $(Expr(ex.head, kwonly_call, body...))
        end
    end
end

function add_kwonly(::Type{Val{:where}}, ex::Expr)
    default_call = ex.args[1]
    rest = ex.args[2:end]
    kwonly_call = add_kwonly(default_call)
    if kwonly_call === nothing
        return nothing
    end
    return Expr(:where, kwonly_call, rest...)
end

function add_kwonly(::Type{Val{:call}}, default_call::Expr)
    # default_call is, e.g., :(f(a, b=2; c=3))
    funcname = default_call.args[1]  # e.g., :f
    required = []  # required positional arguments; e.g., [:a]
    optional = []  # optional positional arguments; e.g., [:(b=2)]
    default_kwargs = []
    for arg in default_call.args[2:end]
        if isa(arg, Symbol)
            push!(required, arg)
        elseif arg.head == :(::)
            push!(required, arg)
        elseif arg.head == :kw
            push!(optional, arg)
        elseif arg.head == :parameters
            @assert default_kwargs == []  # can I have :parameters twice?
            default_kwargs = arg.args
        else
            error("Not expecting to see: $arg")
        end
    end
    if isempty(required) && isempty(optional)
        # If the function is already keyword-only, do nothing:
        return nothing
    end
    if isempty(required)
        # It's not clear what should be done.  Let's not support it at
        # the moment:
        error("At least one positional mandatory argument is required.")
    end

    kwonly_kwargs = Expr(:parameters, [
        Expr(:kw, pa, :(throw($UndefKeywordError($(QuoteNode(pa))))))
        for pa in required
    ]..., optional..., default_kwargs...)
    kwonly_call = Expr(:call, funcname, kwonly_kwargs)
    # e.g., :(f(; a=error(...), b=error(...), c=1, d=2))

    return kwonly_call
end

end  # module
