function examples(;port=8000,launch=false)
    Endpoint("/examples") do request::HTTP.Request
        read(joinpath(@__DIR__,"examples.html"),String)
    end

    Endpoint("/examples/plot.ly") do request::HTTP.Request
        read(joinpath(@__DIR__,"plotly","plotly.html"),String)
    end

    Endpoint("/examples/blank") do request::HTTP.Request
        read(joinpath(@__DIR__,"blank","blank.html"),String)
    end

    include(joinpath(@__DIR__,"plotly","plotly.jl"))
    include(joinpath(@__DIR__,"blank","blank.jl"))
    # include("mwe.jl")
    
    Callback("generateplots") do client, route, id, msg
        example_plotly(route,id)
    end

    Callback("broadcastplots") do client, route, id, msg
        example_plotly()
    end

    @async Pages.start()
    launch && Pages.launch("http://localhost:$(port)/examples/plot.ly")
end