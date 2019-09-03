"""
Implements the `@required_keywords` macro which allows function definitions to have keyword
arguments without a default value. These keywords must always be specified. If they are not,
a `UnassignedKeyword` exception is thrown.
"""
module RequiredKeywords
    import Base: showerror
    export UnassignedKeyword, @required_keywords, @showexp

    """
    Indicated that a funtion has been called without specifying a keyword which has no default.
    """
    struct UnassignedKeyword <:Exception
        msg::String
    end

    Base.showerror(io::IO, e::UnassignedKeyword) = print(io, "Unassigned Keyword:  ", e.msg)

    """
        @required_keywords f(...; x::Int=0, y::Int) = ...

    Allows function definitions to have keyword arguments without a default value. These
    keywords must always be specified. If they are not, a `UnassignedKeyword` exception is thrown.
    """
    macro required_keywords(exp)
    end

    macro showexp(exp)
        show(exp)
    end

end # module
