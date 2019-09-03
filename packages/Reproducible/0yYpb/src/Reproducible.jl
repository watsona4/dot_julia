module Reproducible

using Markdown

#-----------------------------------------------------------------------# build
"""
    build(path::String [, builddir::String]; frontmatter::String = "")
    build(path::Vector{String} [, builddir::String]; frontmatter::String = "")

Evaluate the markdown document(s) in `path` and put the output in `builddir`, beginning 
with `frontmatter` (since Julia's markdown parser does not support it).
"""
function build(path::String, builddir = joinpath(dirname(path), "build"); frontmatter::String = "", toc=false)
    mod = Main.eval(:(module __Temp__ end))
    !isdir(builddir) && mkdir(builddir)
    file = touch(joinpath(builddir, basename(path)))
    open(file, "w") do io
        toc && write(io, maketoc(path))
        !isempty(frontmatter) && write(io, "---\n$(strip(frontmatter))\n---\n\n")
        for x in Markdown.parse(read(path, String)).content
            write(io, markdown2string(x, mod, builddir) * "\n")
        end
    end
    return file
end

function build(paths, builddir = joinpath(dirname(paths[1]), "build"))
    files = []
    for path in paths 
        push!(files, build(path, builddir))
    end
    files
end

function markdown2string(x, mod, builddir) 
    if isa(x, Markdown.Code)
        isa(Meta.parse(x.language), Expr) ? code2string(x, mod, builddir) : Markdown.plain(x)
    else
        Markdown.plain(x)
    end
end

function code2string(x::Markdown.Code, mod::Module, builddir::String)
    ex = Meta.parse(x.language)
    lang = ex.args[1]
    if lang == :julia
        v = Val(Meta.parse(x.language).args[2])  # renderer
        render(CodeBlock(x.code, mod), v; builddir=builddir, _kws(ex.args[3:end])...)
    else
        @warn "Reproducible doesn't know how to eval a code block with language $lang...skipping"
        Markdown.plain(x)
    end
end

# create named tuple from array of expressions e.g. :(hide = true)
function _kws(args)
    vals = [eval(a.args[2]) for a in args]
    nt = NamedTuple{tuple([a.args[1] for a in args]...), Tuple{eltype.(vals)...}}(tuple(vals...))
end


#-----------------------------------------------------------------------# CodeRow 
"""
Object that represents a block of code.  Fields are:

- `input (String)`: the input block of code
- `output (Any)`: the result of `eval(parse(input))`
- `repldisplay (String)`: string of what would get sent to REPL
"""
struct CodeRow 
    input::String
    output::Any
    repldisplay::String
end

#-----------------------------------------------------------------------# CodeBlock
"""
    CodeBlock(code::String, mod::Module)

Object to represent code for a **Reproducible** renderer.  The constructor parses/evaluates
the code inside the provided module. 
"""
struct CodeBlock
    rows::Vector{CodeRow}
end
function CodeBlock(code::String, mod::Module, args...; display_size = (10, 80), limit = true)
    n = 1 
    rows = CodeRow[]  
    while n < length(code)
        nold = n
        ex, n = Meta.parse(code, n)
        input = code[nold:n-1]
        output = @eval(mod, $ex)
        io = IOContext(IOBuffer(), :display_size => display_size, :limit => limit, args...)
        show(io, MIME"text/plain"(), output)
        out = (endswith(strip(input), ';') || output == nothing) ? "" : String(take!(io.io))
        push!(rows, CodeRow(input, output, out))
    end
    CodeBlock(rows)
end
Base.getindex(o::CodeBlock, i) = o.rows[i]
codestring(o::CodeBlock) = join([r.input for r in o.rows])

#-----------------------------------------------------------------------# utils
block(s::String, lang="") = "```$lang\n$(strip(s))\n```\n"

#-----------------------------------------------------------------------# includes
include("toc.jl")
include("render.jl")

end # module
