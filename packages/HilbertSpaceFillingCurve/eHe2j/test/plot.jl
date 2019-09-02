using Gadfly, HilbertSpaceFillingCurve

x,y,z = Int[],Int[], Int[]
for d = 0:1:2^12-1

    p = hilbert(d, 3, 16)
    push!(x,p[1]) 
    push!(y,p[2]) 
    push!(z,p[3]) 
end
#
p = plot(
    x=x+z/40,y=y+z/40,Geom.line(preserve_order=true),
    Guide.xlabel(""),Guide.ylabel(""),
    Coord.cartesian(xmax=15,ymax=15),
    Guide.xticks(ticks=nothing), Guide.yticks(ticks=nothing)
)
Gadfly.draw(PNG(joinpath(Pkg.dir(),"HilbertSpaceFillingCurve","data","figure.png"),12cm,12cm),p)
p