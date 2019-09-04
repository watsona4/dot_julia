@enum MinifyState begin
    MINIFY_INIT
    MINIFY_MAP_KEY
    MINIFY_MAP_KEY_FIRST
    MINIFY_MAP_VAL
    MINIFY_ARRAY
    MINIFY_ARRAY_FIRST
end

const NULL = Vector{UInt8}("null")
const COLON = UInt8(':')
const COMMA = UInt8(',')
const QUOTE = UInt8('"')
const OPEN_BRACE = UInt8('{')
const CLOSE_BRACE = UInt8('}')
const OPEN_BRACKET = UInt8('[')
const CLOSE_BRACKET = UInt8(']')

"""
    Minifier(io::IO=stdout) -> Minifier

Removes all unecessary whitespace from JSON.

## Example
```julia-repl
julia> String(take!(YAJL.run(IOBuffer("{    }"), YAJL.Minifier(IOBuffer()))))
"{}"
```
"""
struct Minifier{T<:IO} <: Context
    io::T
    state::Vector{MinifyState}

    Minifier(io::T=stdout) where T <: IO = new{T}(io, [MINIFY_INIT])
end

collect(ctx::Minifier) = ctx.io

writeval(ctx::Minifier, v::Ptr{UInt8}, len::Int) = unsafe_write(ctx.io, v, len)
writeval(ctx::Minifier, v::Vector{UInt8}, ::Int=-1) = write(ctx.io, v)
writeval(ctx::Minifier, v::UInt8, ::Int=-1) = write(ctx.io, v)

# Yuck.
function addval(ctx::Minifier, v, len::Int=-1; string::Bool=false)
    state = ctx.state[end]
    if state === MINIFY_INIT
        string && writeval(ctx, QUOTE)
        writeval(ctx, v, len)
        string && writeval(ctx, QUOTE)
    elseif state === MINIFY_MAP_KEY
        writeval(ctx, [COMMA, QUOTE])
        writeval(ctx, v, len)
        writeval(ctx, [QUOTE, COLON])
        ctx.state[end] = MINIFY_MAP_VAL
    elseif state === MINIFY_MAP_KEY_FIRST
        writeval(ctx, QUOTE)
        writeval(ctx, v, len)
        writeval(ctx, [QUOTE, COLON])
        ctx.state[end] = MINIFY_MAP_VAL
    elseif state === MINIFY_MAP_VAL
        string && writeval(ctx, QUOTE)
        writeval(ctx, v, len)
        string && writeval(ctx, QUOTE)
        ctx.state[end] = MINIFY_MAP_KEY
    elseif state === MINIFY_ARRAY
        writeval(ctx, COMMA)
        string && writeval(ctx, QUOTE)
        writeval(ctx, v, len)
        string && writeval(ctx, QUOTE)
    elseif state === MINIFY_ARRAY_FIRST
        string && writeval(ctx, QUOTE)
        writeval(ctx, v, len)
        string && writeval(ctx, QUOTE)
        ctx.state[end] = MINIFY_ARRAY
    end
end

@yajl null(ctx::Minifier) = addval(ctx, NULL)
@yajl boolean(ctx::Minifier, v::Bool) = addval(ctx, v)
@yajl number(ctx::Minifier, v::Ptr{UInt8}, len::Int) = addval(ctx, v, len)
@yajl string(ctx::Minifier, v::Ptr{UInt8}, len::Int) = addval(ctx, v, len; string=true)
@yajl function map_start(ctx::Minifier)
    ctx.state[end] in (MINIFY_ARRAY, MINIFY_MAP_KEY) && writeval(ctx, COMMA)
    writeval(ctx, OPEN_BRACE)
    push!(ctx.state, MINIFY_MAP_KEY_FIRST)
end
@yajl map_key(ctx::Minifier, v::Ptr{UInt8}, len::Int) = addval(ctx, v, len)
@yajl function map_end(ctx::Minifier)
    writeval(ctx, CLOSE_BRACE)
    pop!(ctx.state)
    state = ctx.state[end]
    if state === MINIFY_MAP_KEY_FIRST
        ctx.state[end] = MINIFY_MAP_KEY
    elseif state === MINIFY_ARRAY_FIRST
        ctx.state[end] = MINIFY_ARRAY
    end
end
@yajl function array_start(ctx::Minifier)
    ctx.state[end] in (MINIFY_ARRAY, MINIFY_MAP_KEY) && writeval(ctx, COMMA)
    writeval(ctx, OPEN_BRACKET)
    push!(ctx.state, MINIFY_ARRAY_FIRST)
end
@yajl function array_end(ctx::Minifier)
    writeval(ctx, CLOSE_BRACKET)
    pop!(ctx.state)
    state = ctx.state[end]
    if state === MINIFY_MAP_KEY_FIRST
        ctx.state[end] = MINIFY_MAP_KEY
    elseif state === MINIFY_ARRAY_FIRST
        ctx.state[end] = MINIFY_ARRAY
    end
end
