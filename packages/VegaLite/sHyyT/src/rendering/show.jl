
function Base.show(io::IO, m::MIME"text/plain", v::AbstractVegaSpec)
    print(io, summary(v))
end

function convert_vl_to_vg(v::VLSpec{:plot})
    vl2vg_script_path = joinpath(@__DIR__, "vl2vg.js")
    data = JSON.json(v.params)
    p = open(`$(nodejs_cmd()) $vl2vg_script_path`, "r+")
    writer = @async begin
        write(p, data)
        close(p.in)
    end
    reader = @async read(p, String)
    wait(p)
    res = fetch(reader)
    if p.exitcode!=0
        throw(ArgumentError("Invalid spec"))
    end
    return res
end

function convert_vl_to_x(v::VLSpec{:plot}, second_script)
    vl2vg_script_path = joinpath(@__DIR__, "vl2vg.js")
    full_second_script_path = joinpath(@__DIR__, "..", "..", "deps", "node_modules", "vega-cli", "bin", second_script)
    data = JSON.json(v.params)
    p = open(pipeline(`$(nodejs_cmd()) $vl2vg_script_path`, `$(nodejs_cmd()) $full_second_script_path`), "r+")
    writer = @async begin
        write(p, data)
        close(p.in)
    end
    reader = @async read(p, String)
    wait(p)
    res = fetch(reader)
    if p.processes[1].exitcode!=0 || p.processes[2].exitcode!=0
        throw(ArgumentError("Invalid spec"))
    end
    return res
end

function convert_vg_to_x(v::VGSpec, script)
    full_script_path = joinpath(@__DIR__, "..", "..", "deps", "node_modules", "vega-cli", "bin", script)
    data = JSON.json(v.params)
    p = open(`$(nodejs_cmd()) $full_script_path`, "r+")
    writer = @async begin
        write(p, data)
        close(p.in)
    end
    reader = @async read(p, String)
    wait(p)
    res = fetch(reader)
    if p.exitcode!=0
        throw(ArgumentError("Invalid spec"))
    end
    return res
end

Base.Multimedia.istextmime(::MIME{Symbol("application/vnd.vegalite.v3+json")}) = true
Base.Multimedia.istextmime(::MIME{Symbol("application/vnd.vega.v5+json")}) = true

function Base.show(io::IO, m::MIME"application/vnd.vegalite.v3+json", v::VLSpec{:plot})
     print(io, JSON.json(v.params))
end

function Base.show(io::IO, m::MIME"application/vnd.vega.v5+json", v::VGSpec)
    print(io, JSON.json(v.params))
end

function Base.show(io::IO, m::MIME"application/vnd.vega.v5+json", v::VLSpec{:plot})

    print(io, convert_vl_to_vg(v))
end

function Base.show(io::IO, m::MIME"image/svg+xml", v::VLSpec{:plot})
    print(io, convert_vl_to_x(v, "vg2svg"))
end

function Base.show(io::IO, m::MIME"image/svg+xml", v::VGSpec)
    print(io, convert_vg_to_x(v, "vg2svg"))
end

function Base.show(io::IO, m::MIME"application/pdf", v::VLSpec{:plot})
    print(io, convert_vl_to_x(v, "vg2pdf"))
end

function Base.show(io::IO, m::MIME"application/pdf", v::VGSpec)
    print(io, convert_vg_to_x(v, "vg2pdf"))
end

# function Base.show(io::IO, m::MIME"application/eps", v::AbstractVegaSpec)
#     svgstring = convert_to_svg(v)

#     r = Rsvg.handle_new_from_data(svgstring)
#     d = Rsvg.handle_get_dimensions(r)

#     cs = Cairo.CairoEPSSurface(io, d.width,d.height)
#     c = Cairo.CairoContext(cs)
#     Rsvg.handle_render_cairo(c,r)
#     Cairo.finish(cs)
# end

function Base.show(io::IO, m::MIME"image/png", v::VLSpec{:plot})
    print(io, convert_vl_to_x(v, "vg2png"))
end

function Base.show(io::IO, m::MIME"image/png", v::VGSpec)
    print(io, convert_vg_to_x(v, "vg2png"))
end
