# All or most of the code in this file is taken from:
# 1. https://github.com/NHDaly/DeepcopyModules.jl (license: MIT)
# 2. https://github.com/perrutquist/CodeTransformation.jl (license: MIT)

"""
    jl_method_def(argdata, ci, mod) - C function wrapper

This is a wrapper of the C function with the same name, found in the Julia
source tree at julia/src/method.c

Use `addmethod!` or `codetransform!` instead of calling this function directly.
"""
jl_method_def(argdata::Core.SimpleVector, ci::Core.CodeInfo, mod::Module) =
    ccall(:jl_method_def, Cvoid, (Core.SimpleVector, Any, Ptr{Module}), argdata, ci, pointer_from_objref(mod))
# `argdata` is `Core.svec(Core.svec(types...), Core.svec(typevars...))`

"Recursively get the typevars from a `UnionAll` type"
typevars(T::UnionAll) = (T.var, typevars(T.body)...)
typevars(T::DataType) = ()

@nospecialize # the below functions need not specialize on arguments

"Get the module of a function"
getmodule(F::Type{<:Function}) = F.name.mt.module
getmodule(f::Function) = getmodule(typeof(f))

"Create a call singature"
makesig(f::Function, args) = Tuple{typeof(f), args...}

"""
    argdata(sig[, f])

Turn a call signature into the 'argdata' `Core.svec` that `jl_method_def` uses
When a function is given in the second argument, it replaces the one in the
call signature.
"""
argdata(sig) = Core.svec(Base.unwrap_unionall(sig).parameters::Core.SimpleVector, Core.svec(typevars(sig)...))
argdata(sig, f::Function) = Core.svec(Core.svec(typeof(f), Base.unwrap_unionall(sig).parameters[2:end]...), Core.svec(typevars(sig)...))

"""
    addmethod!(f, argtypes, ci)

Add a method to a function.

The types of the arguments is given as a `Tuple`.

Example:
```
g(x) = x + 13
ci = code_lowered(g)[1]
function f end
addmethod!(f, (Any,), ci)
f(1) # returns 14
```
"""
addmethod!(f::Function, argtypes::Tuple, ci::Core.CodeInfo) = addmethod!(makesig(f, argtypes), ci)
"""
    addmethod(sig, ci)

Alternative syntax where the call signature is a `Tuple` type.

Example:
```
addmethod!(Tuple{typeof(f), Any}, ci)
```
"""
function addmethod!(sig::Type{<:Tuple{F, Vararg}}, ci::Core.CodeInfo) where {F<:Function}
    jl_method_def(argdata(sig), ci, getmodule(F))
end

@specialize # restore default

"""
    codetransform!(tr, dst, src)

Apply a code transformation function `tr` on the methods of a function `src`,
adding the transformed methods to another function `dst`.

Example: Search-and-replace a constant in a function.
```
g(x) = x + 13
function e end
codetransform!(g => e) do ci
    for ex in ci.code
        if ex isa Expr
            map!(x -> x === 13 ? 7 : x, ex.args, ex.args)
        end
    end
    ci
end
e(1) # returns 8
```
"""
function codetransform!(tr::Function, @nospecialize(dst::Function), @nospecialize(src::Function))
    mod = getmodule(dst)
    for m in methods(src).ms
        ci = Base.uncompressed_ast(m)
        ci = tr(ci)
        jl_method_def(argdata(m.sig, dst), ci, mod)
    end
end
"Alternative syntax: codetransform!(tr, src => dst)"
codetransform!(tr::Function, @nospecialize(p::Pair{<:Function, <:Function})) =
    codetransform!(tr, p.second, p.first)
