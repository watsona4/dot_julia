module DumbCompleter

using JSON
using Pkg
using Serialization

export ioserver

# A completion.
struct Leaf
    name::Symbol
    type::Type
    mod::Module
    Leaf(n::Symbol, ::T, m::Module) where T = new(n, T, m)
end

# A completion tree.
struct Tree
    lf::Union{Leaf, Nothing}
    tr::Dict{Char, Tree}
    Tree(lf::Union{Leaf, Nothing}=nothing) = new(lf, Dict{Char, Tree}())
end

Base.show(io::IO, tr::Tree) =
    print(io, "Completion tree with ", length(leaves(tr)), " entries")

# Stored completions.
struct Deps
    exports::Tree
    modules::Dict{Symbol, Tree}
end

const EXPORTS = Ref(Tree())
const MODULES = Ref(Dict{Symbol, Tree}())
const DEPS = joinpath(dirname(@__DIR__), "deps", "completions-$VERSION")
const Command = Dict{Symbol, Union{String, Nothing}}

__init__() = try loaddeps!() catch; loadstoredeps!() end

# Load the completions file.
function loaddeps!()
    deps = open(deserialize, DEPS)
    EXPORTS[] = deps.exports
    MODULES[] = deps.modules
end

# Load default completions and store the completions file.
function loadstoredeps!()
    @info "Loading + storing default completions"
    foreach(loadmodule!, (Core, Base))
    mkpath(dirname(DEPS))
    deps = Deps(EXPORTS[], MODULES[])
    open(io -> serialize(io, deps), DEPS, "w")
end

# Store a single completion.
function putleaf!(tr::Tree, lf::Leaf)
    name = string(lf.name)
    ind = 1
    while ind <= length(name)
        tr = get!(tr.tr, name[ind], Tree(ind == length(name) ? lf : nothing))
        ind = nextind(name, ind)
    end
end

# Compute the normalized module name.
modkey(m::Module) = Symbol(replace(string(m), "Main." => ""))

# Determines whether a symbol is worth using as a completion.
cancomplete(m::Module) = s -> cancomplete(s, m)
cancomplete(s::Symbol, m::Module) = isdefined(m, s) && !startswith(string(s), "#")

# Load a module's names and store them as completions.
function loadmodule!(m::Module; exports::Bool=true)
    m === Main && return
    k = modkey(m)
    haskey(MODULES[], k) && return

    # Populate a tree for this module.
    MODULES[][k] = tr = Tree()
    ns = filter(cancomplete(m), names(m; all=true, imported=true))
    foreach(ns) do n
        lf = Leaf(n, getfield(m, n), m)
        putleaf!(tr, lf)
        exports && Base.isexported(m, n) && putleaf!(EXPORTS[], lf)
    end

    # Do the same for submodules, but don't fill in exports.
    children = map(n -> getfield(m, n), filter(n -> getfield(m, n) isa Module, ns))
    foreach(m -> loadmodule!(m; exports=false), children)
end

function loadmodule!(m::Symbol)
    @eval import $m
    return loadmodule!(eval(m))
end

loadmodule!(m::AbstractString) = loadmodule!(Symbol(m))

# Get all of a tree's completions.
function leaves(tr::Tree)
    lvs = map(tr -> tr.lf, Iterators.filter(tr -> tr.lf !== nothing, values(tr.tr)))
    return vcat(lvs, mapreduce(leaves, vcat, values(tr.tr); init=Leaf[])...)
end

"""
    completions(::Tree, s::AbstractString) -> Vector{Leaf}
    completions(s::AbstractString)
    completions(s::AbstractString, m::Union{Module, Symbol, AbstractString})

Get completions that begin with `s`.
"""
function completions(tr::Tree, s::AbstractString)::Vector{Leaf}
    for c in s
        haskey(tr.tr, c) || return Leaf[]
        tr = tr.tr[c]
    end
    lvs = sort!(leaves(tr); by=lf -> lf.name)
    return tr.lf === nothing ? lvs : [tr.lf; lvs]
end

completions(s::AbstractString, ::Nothing=nothing) = completions(EXPORTS[], s)
completions(s::AbstractString, m::AbstractString) = completions(s, Symbol(m))
completions(s::AbstractString, m::Symbol) =
    completions(s, try eval(m) catch; return Leaf[] end)
completions(s::AbstractString, m::Module) =
    completions(get(MODULES[], modkey(m), Tree()), s)

"""
    activate!(path::AbstractString)

Activate a project and load all of its modules' completions.
"""
function activate!(path::AbstractString)
    toml = joinpath(path, "Project.toml")
    project = Pkg.Types.read_project(toml)
    current = Base.current_project()
    Pkg.activate(path)
    foreach(loadmodule!, keys(projectdeps(project)))
    loadmodule!(projectname(project))
    current === nothing ? Pkg.activate() : Pkg.activate(current)
end

# Pkg's APIs differ between versions.
if VERSION >= v"1.1"
    projectdeps(project::Pkg.Types.Project) = project.deps
    projectname(project::Pkg.Types.Project) = project.name
else
    projectdeps(project::Dict) = project["deps"]
    projectname(project::Dict) = project["name"]
end

JSON.lower(lf::Leaf) = Dict(
    :name => string(lf.name),
    :type => lf.type <: Function ? "Function" : string(lf.type),
    :module => string(modkey(lf.mod)),
)

# Print out some JSON with a newline.
jsonprintln(io::IO, x) = println(io, sprint(JSON.print, x))

"""
    ioserver(input::IO=stdin, output::IO=stdout)

Run a server that listens to some input and prints to some output.
This function does not return.
"""
function ioserver(input::IO=stdin, output::IO=stdout)
    while isopen(input)
        try
            c = JSON.parse(readline(input); dicttype=Command)
            jsonprintln(output, docmd(Val(Symbol(c[:type])), c))
        catch e
            isopen(input) &&
                jsonprintln(output, (; error=sprint(showerror, e), completions=[]))
        end
    end
end

# Do a client command.
docmd(::Val{T}, ::Command) where T = (; error="unknown command type $T", completions=[])
docmd(::Val{nothing}, ::Command) = (; error="type cannot be null", completions=[])
docmd(::Val{:activate}, c::Command) = (@async activate!(c[:path]); (; error=nothing))
docmd(::Val{:completions}, c::Command) = (;
    error=nothing,
    completions=completions(c[:text], c[:module]),
    exports=c[:module] === nothing,
)

end
