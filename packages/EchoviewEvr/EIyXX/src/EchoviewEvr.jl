module EchoviewEvr

using Filetimes
using Dates

export regions, polygon, polygons

"""
An Echoview region.

See [documentation](http://bit.ly/2uH0O4a).
"""
struct Region
    name::String
    version::String
    classification::String
    boundingrectangle
    notes::String
    detectionsettings::String
    points
    regiontype::String
end

function readheader(f)
    line = readline(f)
    # Note that the file actually starts with a byte order mark U+FEFF
    @assert startswith(line, "\ufeffEVRG") "Invalid EVRG header."
    line
end

function readmultiline(f)
    n = parse(Int, readline(f))
    lines = String[]
    for i = 1:n
        line = readline(f)
        push!(lines, line)
    end
    join(lines)
end

function readpoints(f)
    line = readline(f)
    fields = split(line)
    # BUG points = fields[1:2:end-1]
    points = fields[1:end-1]
    regiontype = fields[end]
    return points, regiontype
end

function readblankline(f)
    line = readline(f)
    @assert length(line) < 1
end

function readregion(f)
    readblankline(f)

    line = readline(f)
    fields = split(line)
    version = fields[1]
    @assert version=="13"
    pointcount = fields[2]
    regionid = fields[3]
    selected = fields[4]
    @assert selected == "0"
    regioncreationtype = fields[5]
    dummy = fields[6]
    @assert dummy == "-1"
    boundingrectanglecalculated = fields[7]
    boundingrectangle = []
    if boundingrectanglecalculated == "1"
        # Not enitirely consistent with the documentation here?
        datep1 = fields[8]
        timep1 = fields[9]
        depthp1 = fields[10]
        datep2 = fields[11]
        timep2 = fields[12]
        depthp2 = fields[13]
        boundingrectangle = [datep1, timep1, depthp1,
                              datep2, timep2, depthp2]
    end

    notes = readmultiline(f)
    detectionsettings = readmultiline(f)
    classification = readline(f)
    points, regiontype = readpoints(f)
    name = readline(f)

    Region(name, version, classification, boundingrectangle,
           notes, detectionsettings, points, regiontype)

end

function regions(f::IOStream)

    function _it(chn1)
        readheader(f)
        n = parse(Int, readline(f))
        for i in 1:n
            region = readregion(f)
            put!(chn1, region)
        end
    end

    return Channel(_it, ctype=Region)
end

"""
    regions(filename::AbstractString)

`regions` returns an iterator over regions in the given Echoview EVR
file.

"""
function regions(filename::AbstractString)
    regions([filename])
end

"""
    load(filename::AbstractString)

Loads an Echoview region file.
"""
function load(filename::AbstractString)
    collect(regions([filename]))
end

"""
    regions(filenames::Vector{String})

`regions` returns an iterator over regions in the given Echoview EVR
files.

"""
function regions(filenames::Vector{String})

    function _it(chn1)
        for filename in filenames
            open(filename) do f
                for region in regions(f)
                    put!(chn1, region)
                end
            end
        end
    end

    return Channel(_it, ctype=Region)
end

function makefiletime(date, time)

    CCYY = parse(Int,date[1:4])
    MM = parse(Int, date[5:6])
    DD = parse(Int, date[7:8])

    HH = parse(Int, time[1:2])
    mm = parse(Int, time[3:4])
    SS = parse(Int, time[5:6])

    ssss = div(parse(Int, time[7:10]), 10)

    d = DateTime(CCYY, MM, DD, HH, mm, SS)

    ft = Filetimes.filetime(d)

    ft = ft + ssss *10000
end

function polygon(region::Region)
    p = region.points
    d = p[1:3:end]
    t = p[2:3:end]
    y = parse.(Float64,p[3:3:end])

    x = makefiletime.(d,t)

    return x,y
end

function polygons(ps::Vector{Region})
    polygon.(ps)
end

                  
function polygons(x)
    polygons(collect(regions(x)))
end

end # module
