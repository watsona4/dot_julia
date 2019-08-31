# Tropical Pacific SSTs

```julia
using DSP
using StatsBase: zscore, autocor
using DataFrames
using Compose, Gadfly
using SpacetimeFields, CoupledFields

expand_grid(xv, yv) = vcat([ [x y] for x in xv, y in yv]...) 
theme_red = Theme(default_color=colorant"red")

# NetCDF file:
# https://www.esrl.noaa.gov/psd/data/gridded/data.noaa.ersst.v4.html 
f2 = "sst.mnmean.v4.nc"

# NetCDF.ncinfo(f2)

ext1 = extent(126, 294 ,-19, 19)
r1 = nc2field(f2, "sst", ext1)

coord_map = Coord.cartesian(xmin=ext1.xmin-1, xmax=ext1.xmax+1, ymin=ext1.ymin-1, ymax=ext1.ymax+1)
xtix = Guide.xticks(ticks=collect(120:20:280)+10)
ytix = Guide.yticks(ticks=collect(-20:10:ext1.ymax+1))

t1 = ((1854+1/24):1/12:2017)[1:length(r1.time)]
ti = ((1945-1854)*12+1):((2010-1854)*12)
t2 = collect(t1[ti])

M1 = convert(Matrix, r1)

filt1 = digitalfilter(Bandpass(1/36, 1/23, fs=1), Butterworth(3))
filt2 = digitalfilter(Bandpass(1/72, 1/48, fs=1), Butterworth(3))

hpfield = filtfilt(filt1, M1)
lpfield = filtfilt(filt2, M1)

lat = convert(Vector{Float64},llgrid(r1)[1][:,2] )

# Can change the [0.85, 0.85] below 
lag = 0
Z0 = InputSpace(lpfield[ti+lag,:],hpfield[ti,:]) # zscores
Z = InputSpace(lpfield[ti+lag,:], hpfield[ti,:], [0.85, 0.85], lat[r1.good])

kpars = GaussianKP(Z.X)

srand(1234)
grid1 = expand_grid(linspace(0.15, 2.0, 10), linspace(-7, -2, 6))
grid1 = [grid1 fill(2.0, size(grid1,1)) ]
@time par = CVfn(grid1, Z.X, Z.Y, gKCCA, GaussianKP, dcv=1)
gKCCAm = gKCCA(par, Z.X, Z.Y, kpars)

############### Graphics Functions ################

function expvar{Q<:Matrix{Float64}}(j::Union{Int,Range{Int}}, model::ModelObj, X::Q, Y::Q)
    R = model.R[:,j][:,:]
    T = model.T[:,j][:,:]
    P_R = R * (R'R \ R')
    P_T = T * (T'T \ T')
    return    [ trace(X'*P_R*X)/trace(X'X)  trace(Y'*P_T*Y)/trace(Y'Y) ]
end

function fncor(j::Int, model::ModelObj)
    D = DataFrame(R = model.R[:,j], T = model.T[:,j], g=" ")
    D[:Component] = "<b>j=$j</b>"
    return D
end    

function fnmap(j::Int, model::ModelObj, Z::InputSpace, r1::stfield)
    b = [ cor(model.R[:,j], Z.X); cor(model.T[:,j], Z.Y) ]
    r2 = copy(r1, layers=1:2);
    r2.data[repmat(r2.good,2)] = b'
    label = ["XW", "YA"]
    D = convert(DataFrame, r2, 1:2, label)
    D[:Component] = "Component $j"
    return D
end    

###################################################

# Explained Variance
function fn1{Q<:Matrix{Float64}}(j::Int, X::Q, Y::Q)
    z = vec( expvar(j, gKCCAm, X, Y) )
    rt = ["R²<sub>X</sub>=", "R²<sub>Y</sub>="]
    zt = [x[1]*"$(x[2])%" for x in zip(rt, round(Int64,z*100))]
    return DataFrame(g=["XW","YA"], Component="Component $j", lon=255, lat=20, label = zt  )
end

D4mapt = vcat([fn1(j, lpfield[ti+lag,:], hpfield[ti,:]) for j in 1:2]...)

# Correlation pattern
D4cor = vcat([fncor(j, gKCCAm) for j in 1:2]...)
D4map = vcat([fnmap(j, gKCCAm, Z0, r1) for j in 1:2]...)

# Figure 4

 _j = "<sub>j</sub>"
labela = ["<b>XW</b>"*_j, "<b>YA</b>"*_j]
labelb = [string("<i>r</i>(",labela[1],", <b>X</b>)"), string("<i>r</i>(",labela[2],", <b>Y</b>)")]
labelc = ["Longitude (°E)", "Latitude (°N)"]

pa = plot(D4cor, x=:R, y=:T, xgroup=:g, ygroup=:Component,
Geom.subplot_grid(
    layer(Geom.point),
    layer(Geom.smooth(smoothing=0.75), theme_red, order=2),
    Guide.xlabel(labela[1])
),
    Guide.xlabel(""),Guide.ylabel(labela[2]),
    Guide.title(" "),
    Theme(plot_padding=0mm, default_point_size=0.6mm, background_color=colorant"white")
)


pb = plot(D4map, xgroup=:g, ygroup=:Component,
    Geom.subplot_grid(coord_map, xtix, ytix,
        layer( x=:lon, y=:lat, color= :z, Geom.rectbin, Theme(bar_spacing=-0.5mm)),
        layer(D4mapt, x=:lon, y=:lat, xgroup=:g, ygroup=:Component, 
            label=:label, Geom.label(position=:centered), order=2),
        Guide.xlabel(labelc[1]), Guide.ylabel("\n")
    ),
    Guide.xlabel(""), Guide.ylabel(labelc[2]),
    Guide.colorkey("<i>r</i>"),
    Guide.title(string(" "^5,labelb[1]," "^35,labelb[2])),
    Theme(plot_padding=0mm, key_position=:right, background_color=colorant"white")
)


M = Array(Compose.Context, (1,2))
M[1] = compose(context(0,0,1/4,1), render(pa))
M[2] = compose(context(0,0,3/4,1), render(pb));

p1 = hstack(M...)
draw(PNG("gKMAP.png",8inch,3.3inch), p1)
```