"""
`categoricalselector(v::AbstractArray, f=filter)`

Create as many checkboxes as the unique elements of `v` and use them to select `v`. By default it returns
a filtered version of `v`: use `categoricalselector(v, map)` to get the boolean vector of whether each element is
selected.
"""
function categoricalselector(v::AbstractArray, f=filter; values=unique(v), value=values, label=nothing, kwargs...)
    cb = checkboxes(values; value=value, kwargs...)
    func = t -> ismissing(t) ? any(ismissing, cb[]) : t in cb[]
    data = [:checkboxes => cb, :function => func]
    wdg = Widget{:categoricalselector}(data, output = map(x -> f(func, v), cb))
    @layout! wdg :checkboxes
    label!(wdg, label)
end

"""
`rangeselector(v::AbstractArray, f=filter)`

Create a `rangepicker` as wide as the extrema of `v` and uses to select `v`. By default it returns
a filtered version of `v`: use `rangeselector(v, map)` to get the boolean vector of whether each element is
selected. Missing data is excluded from the range automatically.
"""
function rangeselector(v::AbstractArray{<:Union{Real, Missing}}, f=filter;
    digits=6, vskip=1em, min=minimum(skipmissing(v)), max=maximum(skipmissing(v)), n=50, label=nothing, kwargs...)

    min = floor(min, digits=digits)
    max = ceil(max, digits=digits)
    step = round((max-min)/n, sigdigits=digits)
    range = min:step:(max+step)
    extrema = InteractBase.rangepicker(range; kwargs...)
    changes = extrema[:changes]
    func = t -> !ismissing(t) && ((min, max) = extrema[]; min <= t <= max)
    data = [:extrema => extrema, :changes => changes, :function => func]
    output = map(t -> f(func, v), changes)
    wdg = Widget{:rangeselector}(data, output=output)
    @layout! wdg :extrema
    label!(wdg, label)
end

"""
`selector(v::AbstractArray, f=filter)`

Create a `textbox` where the user can type in an anonymous function that is used to select `v`. `_` can be used
to denote the funcion argument, e.g. `_ > 0`. By default it returns
a filtered version of `v`: use `selector(v, map)` to get the boolean vector of whether each element is
selected
"""
function selector(v::AbstractArray, f=filter; label=nothing, kwargs...)
    tb = textbox("insert condition")
    changes = tb[:changes]
    func = Observable{Function}(x -> true)
    on(x -> update_function!(func, x, parse=parsepredicate), tb)
    data = [:textbox => tb, :changes => changes, :function => func]
    wdg = Widget{:selector}(data; output=map(t->f(func[], v), changes))
    @layout! wdg :textbox
    label!(wdg, label)
end

label!(v, ::Nothing) = v
function label!(v::Widget, l::AbstractString)
    v[:label] = l
    g = Widgets.layout(v)
    Widget(v, layout = x -> Widgets.div(x[:label], g(x)))
end

for s in [:categoricalselector, :rangeselector, :selector]
    @eval $s(t, c::Symbol, args...; kwargs...) = $s(getproperty(t, c), args...; label = string(c), kwargs...)
end

function parsepredicate(s)
    occursin(r"^(\s)*$", s) && return :(t -> true)
    expr = Meta.parse("_ -> " * s)
    sym = gensym()
    flag = Ref(false)
    expr = MacroTools.postwalk(x -> x == :(_) ? (flag[] = true; sym) : x, Meta.parse(s))
    flag[] ? Expr(:->, sym, expr) : expr
end
