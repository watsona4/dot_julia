"""
Wrapper type for indentation management for plain text printing.

The single exported function is [`indent`](@ref), see its docstring for usage.
"""
module IndentWrappers

export indent

struct IndentWrapper{T <: IO} <: Base.AbstractPipe
    parent::T
    spaces::Int
    function IndentWrapper(io::T, spaces::Integer) where {T <: IO}
        spaces ≥ 0 || throw(ArgumentError("negative indent not allowed"))
        new{T}(io, Int(spaces))
    end
end

"""
    indent(io, spaces)

Return a wrapper around `io` that prepends each `\n` written to the stream with the given
number of spaces.

It is recommended that indent is chained together in a functional manner. Blocks should
always begin with a newline and end *without one*.

# Example

```julia
julia> let io = stdout
           print(io, "toplevel")
           let io = indent(io, 4)
               print(io, '\n', "- level1")
               let io = indent(io, 4)
                   print(io, '\n', "- level 2")
               end
           end
       end
toplevel
    - level1
        - level 2
```
"""
indent(io::IO, spaces::Integer) = IndentWrapper(io, spaces)

indent(iw::IndentWrapper, spaces::Integer) = IndentWrapper(iw.parent, iw.spaces + spaces)

function Base.show(io::IO, iw::IndentWrapper)
    print(io, iw.parent, " indented by $(iw.spaces) spaces")
end

####
#### forwarded methods
####

Base.in(key_value::Pair, iw::IndentWrapper) = in(key_value, iw.parent)
Base.haskey(iw::IndentWrapper, key) = haskey(iw.parent, key)
Base.getindex(iw::IndentWrapper, key) = getindex(iw.parent, key)
Base.get(iw::IndentWrapper, key, default) = get(iw.parent, key, default)
Base.pipe_reader(iw::IndentWrapper) = iw.parent
Base.pipe_writer(iw::IndentWrapper) = iw.parent
Base.lock(iw::IndentWrapper) = lock(iw.parent)
Base.unlock(iw::IndentWrapper) = unlock(iw.parent)
Base.displaysize(iw::IndentWrapper) = displaysize(iw.parent)

####
#### capture '\n' and indent
####

_write_spaces(iw::IndentWrapper) = write(iw.parent, ' '^(iw.spaces))

function Base.write(iw::IndentWrapper, chr::Char)
    write(iw.parent, chr) + (chr == '\n' ? _write_spaces(iw) : 0)
end

function Base.write(iw::IndentWrapper, str::Union{SubString{String}, String})
    write_count = 0
    for (i, line) in enumerate(split(str, '\n'; keepempty = true))
        i == 1 || (write_count += _write_spaces(iw))
        write_count += write(iw.parent, line)
    end
    write_count
end

end # module
