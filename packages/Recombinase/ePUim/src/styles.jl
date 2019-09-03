#=
Conservative 7-color palette from Points of view: Color blindness, Bang Wong - Nature Methods
https://www.nature.com/articles/nmeth.1618?WT.ec_id=NMETH-201106
=#

const wong_colors = [
    RGB(230/255, 159/255, 0/255),
    RGB(86/255, 180/255, 233/255),
    RGB(0/255, 158/255, 115/255),
    RGB(240/255, 228/255, 66/255),
    RGB(0/255, 114/255, 178/255),
    RGB(213/255, 94/255, 0/255),
    RGB(204/255, 121/255, 167/255),
]

const default_style_dict = Dict{Symbol, Any}(
    :color => wong_colors,
    :markershape => [:diamond, :circle, :triangle, :star5],
    :linestyle => [:solid, :dash, :dot, :dashdot],
    :linewidth => [1,4,2,3],
    :markersize => [3,9,5,7]
)

const style_dict = copy(default_style_dict)

function set_theme!(; kwargs...)
    empty!(style_dict)
    for (key, val) in default_style_dict
        style_dict[key] = val
    end
    for (key, val) in kwargs
        style_dict[key] = val
    end
end
