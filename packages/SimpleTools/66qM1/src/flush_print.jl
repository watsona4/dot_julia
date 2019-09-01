export flush_print


function flush_print_string(s::String, width::Int, right::Bool)::String
    n = length(s)
    @assert n>=0 "Width must be nonnegative, got $n"

    if width<n
        @warn "Trunctated to fit width"
        return s[1:width]
    end

    spacer = " "^(width-n)
    if right
        return spacer * s
    end
    return s * spacer
end

"""
`flush_print(x,width)` returns a `String` version of `x` right justified
in a string of length `width`.

Use `flush_print(x,width,false)` for left-justified.
"""
function flush_print(x, width::Int, right::Bool=true)::String
    return flush_print_string(string(x), width, right)
end
