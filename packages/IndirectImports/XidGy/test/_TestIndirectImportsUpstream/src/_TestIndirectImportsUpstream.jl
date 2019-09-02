module _TestIndirectImportsUpstream

using IndirectImports

"""
    fun

Documentation at the indirect function declaration.
"""
@indirect function fun end

# This does not work:
#
# """
#     fun(x::Complex)
#
# Documentation at the indirect function definition.
# """
@indirect function fun(x::Complex)
    return x + 1 + 1im
end

@indirect function op end

"""
    op

"Off-site" documentation for an indirect function.
"""
op

function reduceop(config, acc, xs)
    for x in xs
        acc = op(config, acc, x)
    end
    return acc
end

end # module
