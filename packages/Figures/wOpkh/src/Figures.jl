module Figures

using Pages, JSON

export figure, Plotly, Style

struct Display <: AbstractDisplay end

include("packages/plotly/plotly.jl"); using .Plotly

import .Plotly: newPlot

const current = Ref{String}("")

const Style = Dict{String,String}

function figure(io::IO,id,style=Style())
    id = string(id)
    if tryparse(Int,id) !== nothing
        id = "figure"*id
    end
    global current[] = id

    style = merge(Dict{String,String}(
        "position"      => "absolute",
        "border"        => "thin solid lightgrey",
        "left"          => "50px",
        "top"           => "50px",
        "width"         => "700px",
        "height"        => "450px",
        "box-shadow"    => "3px 3px 5px lightgrey",
        "background"    => "white"),style)

    print(io,"Figures.Figure('$(id)',$(json(style)));")
    return io
end

function closeall(io::IO)
    print(io,"Figures.closeall();")
    return io
end

function close(io::IO,id)
    id = string(id)
    if tryparse(Int,id) !== nothing
        id = "figure"*id
    end
    if id == current[]
        current[] = ""
    end
    print(io,"Figures.close('$(id)');")
    return io
end

for (m,argsin,kwargsin,argsout,kwargsout) in (
        (:figure, (:id, Expr(:kw,:style,:(Style()))), (), (:id,:style), ()),
        (:close, (:id,), (), (:id,), ()),
        (:closeall, (), (), (), ()),
        (:newPlot, (:id, :traces),(
                Expr(:kw,:layout,:(default["layout"])),
                Expr(:kw,:config,:(default["config"]))),
            (:id,:traces),(Expr(:kw,:layout,:layout),Expr(:kw,:config,:config))
        )
    )
    @eval begin
        function $m($(argsin...);$(kwargsin...))
            script = String(take!($m(IOBuffer(),$(argsout...),$(kwargsout...))))
            Pages.broadcast("script",script)
            return
        end
        function $m(route::String,client_id::String,$(argsin...);$(kwargsin...))
            script = String(take!($m(IOBuffer(),$(argsout...),$(kwargsout...))))
            Pages.message(route,client_id,"script",script)
            return
        end
    end
end

start(port=8000) = @async Pages.start(port)
syncstart(port=8000) = Pages.start(port)

include("../examples/examples.jl")

"Download file to a folder relative to /libs"
function download(url::String,path::String)
    Base.download(url,joinpath(@__DIR__,"..","libs",path))
end

function __init__()
    Endpoint("/") do request::HTTP.Request
        read(joinpath(@__DIR__,"index.html"),String)
    end

    Endpoint("/figures.js") do request::HTTP.Request
        read(joinpath(@__DIR__,"..","libs","figures.js"),String)
    end

    Endpoint("/libs/d3/5.9.2/d3.min.js") do request::HTTP.Request
        read(joinpath(@__DIR__,"..","libs","d3","5.9.2","d3.min.js"),String)
    end

    Endpoint("/libs/plotly/1.45.3/plotly.min.js") do request::HTTP.Request
        read(joinpath(@__DIR__,"..","libs","plotly","1.45.3","plotly.min.js"),String)
    end

    pushdisplay(Display())
end

end
