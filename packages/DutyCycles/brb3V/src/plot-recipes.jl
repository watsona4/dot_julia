# "Plot Recipes" for the package `Plots`, see [their
# documentation](https://docs.juliaplots.org/latest/recipes/) and the
# [package
# `RecipesBase`](https://github.com/JuliaPlots/RecipesBase.jl)

using RecipesBase

# The following recipes are based on the `waveform` method.
#
# To Do: Instead extract the coordinates to draw and draw the
#        corresponding polygon more efficiently.

@recipe f(::Type{T}, d::T) where {T<:AbstractDutyCycle} = waveform(d)

# To Do: this needs to be tested; instead of developing an axis label
#        transformation anew, check
#        https://github.com/ajkeller34/UnitfulPlots.jl
@recipe f(
    ::Type{<:Unitful.Quantity{<:AbstractDutyCycle,<:Any,<:Any}},
    d::Unitful.Quantity{<:AbstractDutyCycle,<:Any,<:Any}
) = waveform(d)
