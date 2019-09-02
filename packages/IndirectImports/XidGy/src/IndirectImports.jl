@doc read(joinpath(dirname(@__DIR__), "README.md"), String) ->
module IndirectImports

export @indirect

using MacroTools
using Pkg: TOML
using UUIDs

"""
    IndirectFunction(pkgish::Union{Module,PkgId,IndirectPackage}, name::Symbol)

# Examples
```jldoctest
julia> using IndirectImports: IndirectFunction, IndirectPackage

julia> using UUIDs

julia> Dummy = IndirectPackage(
           UUID("f315346e-6bf8-11e9-0cba-43b0a27f0f55"),
           :Dummy);

julia> Dummy.fun
Dummy.fun

julia> Dummy.fun isa IndirectFunction
true

julia> Dummy.fun ===
           IndirectFunction(Dummy, :fun) ===
           IndirectFunction(
               Base.PkgId(
                   UUID("f315346e-6bf8-11e9-0cba-43b0a27f0f55"),
                   "Dummy"),
               :fun)
true

julia> IndirectPackage(Dummy.fun) === Dummy
true
```
"""
struct IndirectFunction{pkg, name}
end

"""
    IndirectPackage(pkgish::Union{Module,PkgId,IndirectPackage})
    IndirectPackage(uuid::UUID, pkgname::Symbol)

# Examples
```jldoctest
julia> using IndirectImports: IndirectPackage

julia> using Test

julia> IndirectPackage(Test) ===
           IndirectPackage(IndirectPackage(Base.PkgId(Test))) ===
           IndirectPackage(Base.PkgId(Test)) ===
           IndirectPackage(
               Base.UUID("8dfed614-e22c-5e08-85e1-65c5234f0b40"),
               :Test)
true
```
"""
struct IndirectPackage{uuid, pkgname}
end

Base.getproperty(pkg::IndirectPackage, name::Symbol) =
    IndirectFunction(pkg, name)

IndirectFunction(pkgish, name::Symbol) =
    IndirectFunction{IndirectPackage(pkgish), name}()

IndirectPackage(pkg::IndirectPackage) = pkg
IndirectPackage(uuid::UUID, pkgname::Symbol) = IndirectPackage{uuid, pkgname}()
IndirectPackage(pkg::Base.PkgId) = IndirectPackage(pkg.uuid, Symbol(pkg.name))


@nospecialize

function IndirectPackage(mod::Module)
    if parentmodule(mod) !== mod
        error("Only the top-level module can be indirectly imported.")
    end
    return IndirectPackage(Base.PkgId(mod))
end


IndirectPackage(::IndirectFunction{pkg}) where pkg = pkg
Base.nameof(::IndirectFunction{_pkg, name}) where {_pkg, name} = name
Base.nameof(::IndirectPackage{_uuid, pkgname}) where {_uuid, pkgname} = pkgname
pkguuid(::IndirectPackage{uuid}) where uuid = uuid
Base.PkgId(pkg::IndirectPackage) = Base.PkgId(pkguuid(pkg), String(nameof(pkg)))

# Base.parentmodule(f::IndirectFunction) =
#     Base.loaded_modules[Base.PkgId(IndirectPackage(f))]

isloaded(pkg::IndirectPackage) = haskey(Base.loaded_modules, Base.PkgId(pkg))

function Base.show(io::IO, f::IndirectFunction)
    # NOTE: BE VERY CAREFUL inside this function.  Throwing an
    # exception inside `show` for `Type` can kill Julia.  Since
    # `IndirectFunction` can be put inside a `Val`, we need to be
    # extra careful.
    # https://github.com/JuliaLang/julia/issues/29428
    try
        show(io, MIME("text/plain"), f)
    catch
        invoke(show, Tuple{IO, Any}, io, f)
    end
    return
end

function Base.show(io::IO, ::MIME"text/plain", f::IndirectFunction)
    pkg = IndirectPackage(f)
    printstyled(io, nameof(pkg);
                color = isloaded(pkg) ? :green : :red)
    print(io, ".")
    print(io, nameof(f))
    return
end

topmodule(m::Module) = parentmodule(m) == m ? m : topmodule(parentmodule(m))

function _uuidfor(downstream::Module, upstream::Symbol)
    root = topmodule(downstream)
    srcjl = pathof(root)
    if srcjl == nothing
        error("""
        Module $downstream does not have associated source code file.
        `@indirect import` can only be used inside a Julia package.
        """)
    end
    projectpath = dirname(dirname(srcjl))
    tomlpath_candidates = [
        joinpath(projectpath, "Project.toml")
        joinpath(projectpath, "JuliaProject.toml")
    ]
    idx = findfirst(isfile, tomlpath_candidates)
    if idx === nothing
        error("""
        `IndirectImports` needs package `$(nameof(root))` to use `Project.toml`
        file.  Project file is not found at:
            $(tomlpath_candidates[1])
            $(tomlpath_candidates[2])
        """)
    end
    tomlpath = tomlpath_candidates[idx]
    found = find_uuid_or(TOML.parsefile(tomlpath), String(upstream)) do
        error("""
Package `$upstream` is not listed in `[deps]` or `[extras]` of `Project.toml`
file for `$(nameof(root))` found at:
    $tomlpath
If you are developing `$(nameof(root))`, add `$upstream` to the dependency.
Otherwise, please report this to `$(nameof(root))`'s issue tracker.
""")
    end

    # Just to be extremely careful, editing Project.toml should
    # invalidate the compilation cache since the UUID may be changed
    # or removed:
    include_dependency(tomlpath)

    return UUID(found)
end

find_uuid_or(f, project::Dict, name::String) =
    get(get(project, "deps", Dict()), name) do
        get(get(project, "extras", Dict()), name) do
            f()
        end
    end

_indirectpackagefor(downstream::Module, upstream::Symbol) =
    IndirectPackage(_uuidfor(downstream, upstream), upstream)

function _typeof(f, name)
    if !(f isa IndirectFunction)
        msg = """
        Function name `$name` does not refer to an indirect function.
        See `?@indirect`.
        """
        return error(msg)
    end
    return typeof(f)
end

"""
```julia
@indirect function interface_function end
```

Declare an `interface_function` in the upstream module (i.e., the
module "owning" the function `interface_function`).  This function can
be used and/or extended in downstream packages (via `@indirect import
Module`) without loading the package defining `interface_function`.
This from of `@indirect` works only at the top-level module.

```julia
@indirect function interface_function(...) ... end
```

Define a method of `interface_function` in the upstream module.  The
function `interface_function` must be declared first by the above
syntax.

This can also be used in downstream modules provided that
`interface_function` is imported by `@indirect import Module:
interface_function` (see below).

```julia
@indirect import Module
```

Import an upstream module `Module` indirectly.  This defines a
constant named `Module` which acts like the module in a limited way.
Namely, `Module.f` can be used to extend or call function `f`,
provided that `f` in the actual module `Module` is declared to be an
"indirect function" (see above).

```julia
@indirect import Module: f1, f2, ..., fn
```

Import "indirect functions" `f1`, `f2`, ..., `fn`.  This defines
constants `f1`, `f2`, ..., and `fn` that are extendable (see above)
and callable.

```julia
@indirect function Module.interface_function(...) ... end
```

Define a method of an indirectly imported function.  This form can be
usable only in downstream modules where `Module` is imported via
`@indirect import Module`.

# Examples

Suppose you want extend functions in `Upstream` package in
`Downstream` package without importing it.

## Step 1: Declare indirect functions in the Upstream package

There must be a package that "declares" the ownership of an indirect function.
Typically, such function is an interface extended by downstream packages.

To declare a function `fun` in a package `Upstream` wrap an empty
definition of a function `function fun end` with `@indirect`:

```julia
module Upstream
    using IndirectImports
    @indirect function fun end
end
```

To define a method of an indirect function inside `Upstream`, wrap it
in `@indirect`:

```julia
module Upstream
    using IndirectImports
    @indirect function fun end

    @indirect fun() = 0  # defining a method
end
```

## Step 2: Add the upstream package in the Downstream package

Use Pkg.jl interface as usual to add `Upstream` package as a
dependency of the `Downstream` package; i.e., type `]add Upstream⏎`:

```julia-repl
(Downstream) pkg> add Upstream
```

This puts the entry `Upstream` in `[deps]` of `Project.toml`:

```toml
[deps]
...
Upstream = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
...
```

If it is not ideal to install `Upstream` by default, move it to
`[extras]` section (you may need to create it manually):

```toml
[extras]
Upstream = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

## Step 3: Add method definitions in the Downstream package

Once `Upstream` is registered in `Project.toml`, you can import
`Upstream` and define its functions, provided that they are prefixed
with `@indirect` macro:

```julia
module Downstream
    using IndirectImports
    @indirect import Upstream
    @indirect Upstream.fun(x) = x + 1
    @indirect function Upstream.fun(x, y)
        return x + y
    end
end
```

**Note**: It looks like defining a method works without `@indirect` possibly
due to a "bug" in Julia [^1].  While it is handy to define methods without
`@indirect` for debugging, prototyping, etc., it is a good idea to wrap the
method definition in `@indirect` to be forward compatible with future Julia
versions.

[^1]: Extending a constructor is possible with only using `using`
      <https://github.com/JuliaLang/julia/issues/25744>

# Limitation

Function declarations can be documented as usual

```julia
\"\"\"
Docstring for `fun`.
\"\"\"
@indirect function fun end
```

but it does not work with the method definitions:

```julia
# Commenting out the following errors:

# \"\"\"
# Docstring for `fun`.
# \"\"\"
@indirect function fun()
end
```

To add a docstring to indirect functions in downstream packages, one
workaround is to use "off-site" docstring:

```julia
@indirect function fun() ... end

\"\"\"
Docstring for `fun`.
\"\"\"
fun
```

# How it works

See <https://discourse.julialang.org/t/23526/38> for a simple
self-contained code to understanding the idea.  Note that the actual
implementation is slightly different.
"""
macro indirect(expr)
    expr = longdef(unblock(expr))
    if @capture(expr, import name_)
        pkgexpr = :($_indirectpackagefor($__module__, $(QuoteNode(name))))
        return esc(:(const $name = $pkgexpr))
    elseif isexpr(expr, :import) &&
            isexpr(expr.args[1], :(:)) &&
            all(x -> isexpr(x, :.) && length(x.args) == 1, expr.args[1].args)
        # Handling cases like
        #     expr = :(import M: a, b, c)
        # or equivalently
        #     expr = Expr(
        #         :import,
        #         Expr(
        #             :(:),
        #             Expr(:., :M),
        #             Expr(:., :a),
        #             Expr(:., :b),
        #             Expr(:., :c)))
        @assert length(expr.args) == 1
        @assert length(expr.args[1].args) > 1
        name = expr.args[1].args[1].args[1] :: Symbol
        pkgexpr = :($_indirectpackagefor($__module__, $(QuoteNode(name))))
        @gensym pkg
        # Let's not use `pkgexpr` at the right hand side of `const $f = pkg.$f`
        # since it does I/O.
        assignments = :(let $pkg = $pkgexpr; end)
        @assert isexpr(assignments.args[2], :block)
        push!(assignments.args[2].args, __source__)
        for x in expr.args[1].args[2:end]
            f = x.args[1] :: Symbol
            push!(assignments.args[2].args, :(global const $f = $pkg.$f))
        end
        return esc(assignments)
    elseif @capture(expr, function name_ end)
        return esc(:(const $name = $(IndirectFunction(__module__, name))))
    elseif isexpr(expr, :function)
        dict = splitdef(expr)
        dict[:name] = :(::($_typeof($(dict[:name]), $(QuoteNode(dict[:name])))))
        return esc(MacroTools.combinedef(dict))
    else
        msg = """
        Cannot handle:
        $expr
        """
        return :(error($msg))
    end
end

end # module
