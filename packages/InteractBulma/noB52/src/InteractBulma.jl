module InteractBulma

import InteractBase, Sass

struct BulmaTheme<:InteractBase.WidgetTheme
    path::String
end

const examplefolder = joinpath(@__DIR__, "..", "examples")
const main_css = joinpath(@__DIR__, "..", "assets", "main.min.css")
const main_confined_css = joinpath(@__DIR__, "..", "assets", "main_confined.min.css")
const font_awesome = InteractBase.font_awesome

function InteractBase.libraries(b::BulmaTheme)
    bulmalib = joinpath(b.path, InteractBase.isijulia() ? "main_confined.min.css" : "main.min.css")
    vcat(font_awesome, InteractBase.style_css, bulmalib)
end

const main_scss = joinpath(@__DIR__, "..", "assets", "main.scss")
const main_confined_scss = joinpath(@__DIR__, "..", "assets", "main_confined.scss")
const _overrides = joinpath(@__DIR__, "..", "assets", "_overrides")
const _variables = joinpath(@__DIR__, "..", "assets", "_variables")

function copy_or_empty(::Nothing, dest)
    dest = dest*".scss"
    open(io -> nothing, dest, "w")
    return dest
end
function copy_or_empty(src::AbstractString, dest)
    extension = split(src, '.')[end]
    dest = "$dest.$extension"
    cp(realpath(abspath(src)), dest, force = true)
    return dest
end

function compile_theme(output = mktempdir(); overrides = nothing, variables = nothing)
    asset_dir = joinpath(@__DIR__, "..", "assets")
    for file in readdir(asset_dir)
        startswith(file, "_") && rm(joinpath(asset_dir, file))
    end
    copy_or_empty(overrides, _overrides)
    copy_or_empty(variables, _variables)
    Sass.compile_file(main_scss, joinpath(output, "main.min.css"), output_style = Sass.compressed)
    Sass.compile_file(main_confined_scss, joinpath(output, "main_confined.min.css"), output_style = Sass.compressed)
    return BulmaTheme(output)
end

end # module
