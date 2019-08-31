using MacroTools

export render, setdisplay, unsetdisplay, getdisplay, current_input, Media, @media, media,
        @render

# Some type system utils

distance(S, T) =
  !(S <: T) ? Inf :
  S == T ? 0. :
  1 + distance(supertype(S), T)

nearest(T, U, V) =
  distance(T, U) < distance(T, V) ? U : V

nearest(T, Ts) =
  reduce((U, V) -> nearest(T, U, V), Ts)

function compare2desc(ex)
  (isexpr(ex, :comparison) && ex.args[2] == :(<:)) || return ex
  return Expr(:(<:), ex.args[1], ex.args[3])
end

"""
Similar to `abstract`:

    @media Foo

defines `Foo`, as well as `FooT`, the type representing `Foo`
and its descendants (which is useful for dispatch).

    @media Bar <: Foo
    Bar::FooT
"""
macro media(def)
  T = namify(def)
  def = compare2desc(def)
  quote
    abstract type $def end
    $(Symbol(string(T, "T"))){T<:$T} = Type{T}
    nothing
  end |> esc
end

# The media heirarchy defines an extensible set of possible
# output types. Displayable types are associated with a media
# type as a trait.

@media Graphical
@media Plot <: Graphical
@media Image <: Graphical

@media Textual
@media Numeric <: Textual
@media RichText <: Textual

@media Tabular
@media Matrix <: Tabular
@media List <: Tabular
@media Dataset <: Tabular

"""
`media(T)` gives the media type of the type `T`.
The default is `Textual`.

    media(Gadfly.Plot) == Media.Plot
"""
media(x) = media(typeof(x))

media(T, M) =
  Core.eval(@__MODULE__, :((Media.media(::Type{T}) where {T<:$T})= $(Any[M])[1]))

media(Any, Media.Textual)

media(AbstractMatrix, Media.Matrix)
media(AbstractVector, Media.List)

# A "pool" simply associates types with output devices. Obviously
# the idea is to use media types for genericity, but object types
# (e.g. `Float64`, `AbstractMatrix`) can also be used (which will
# override the media trait of the relevant objects).

const _pool = Dict()

defaultpool() = _pool

"""
    setdisplay([input], T, output)

Display `T` objects using `output` when produced by `input`.

`T` is an object type or media type, e.g. `Gadfly.Plot` or `Media.Graphical`.

    display(Editor(), Image, Console())
"""
setdisplay(T, output) =
  defaultpool()[T] = output

unsetdisplay(T) =
  haskey(defaultpool(), T) && delete!(defaultpool(), T)

"""
    getdisplay(T)

Find out what output device `T` will display on.
"""
function getdisplay(T, pool; default = nothing)
  K = nearest(T, Any[Any, keys(pool)...])
  K == Any && (K = nearest(media(T), keys(pool)))
  K == Any && default ≠ nothing && return default
  return pool[K]
end

# There should be a pool associated with each input device. Normally,
# it should take into account the global pool. The device should
# also override `setdisplay(input, T, output)`

# This design allows e.g. terminal and IJulia displays to be linked
# to their respective inputs, so that both can be used simultaneously
# with the same kernel. At the same time you can link a global display
# to both (e.g. a popup window for plots).

macro defpool(D)
  :(let pool = Dict()
      Media.pool(::$D) = merge(Media.defaultpool(), pool)
      Media.setdisplay(::$D, T, input) = pool[T] = input
      Media.unsetdisplay(::$D, T) = delete!(pool, T)
    end) |> esc
end

# In order to actually display things, we need to know what the current
# input device is. This is stored as a dynamically-bound global variable,
# with the intention that an input device will rebind the current input
# to itself whenever it evaluates code.

# This will also be useful for device-specific functionality like reading
# input and producing warnings.

@dynamic input::Any = nothing

current_input() = input[]

# e.g.

# @dynamic let Media.input = REPL
#   eval(:(render(x)))
# end

# `render` is a stand-in for `display` here.
# Displays should override `render` to display the given object appropriately.

pool() = pool(current_input())
pool(::Nothing) = defaultpool()

getdisplay(x; default = nothing) =
  getdisplay(x, pool(), default = default)

@eval primarytype(x) = typeof(x).name.wrapper

render(x) =
  render(getdisplay(primarytype(x)), x)

# Most of the time calls to `render` will defer to rendering some lower-level
# type. `@render` reduces the boilerplate here by automatically calling
# `render` again on the return type.

macro render(T, x, f)
  @capture(T, d_::T′_ | T′_)
  d == nothing && (d = gensym())
  @gensym result
  quote
    function Media.render($d::$T′, $x)
      Media.render($d, $f)
    end
  end |> esc
end
