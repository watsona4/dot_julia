# Example 2

```julia
using StatsBase: zscore
using DataFrames, Compose, Gadfly
using CoupledFields

function rHypersphere(n::Int, k::Int)
    Q = qrfact(randn(k,k))[:Q]
    return Q[:,1:n]  
end

function simfn(n::Int, p::Int, sc::Float64, sige::Float64)
    Wx = rHypersphere(2,p)
    Wy = rHypersphere(2,2)
    X = sc*rand(n,p)-(sc/2)
    E = sige*randn(n,1)
    xstar = X * Wx
    ystar = zscore([6.3*xstar[:,1].*exp(-0.1*xstar[:,1].^2) randn(n,1)],1)
    Y =  ystar / Wy
    return zscore(X,1), Y, xstar, ystar
end

createDF = function(df::Int, Y::Matrix{Float64})
    Xs = bf(gKCCAm.R[:,1], df)
    CCAm = cca([-9. -9.], Xs, Y)
    return DataFrame(x=gkCCAm.R[:,1], y= CCAm.T[:,1], y2 = CCAm.R[:,1]-mean(CCAm.R[:,1]), df="<i>df</i>=$df")
end    

srand(1234)
X, Y, xstar, ystar = simfn(200, 2,30.0, 0.1)

kpars = GaussianKP(X)
gKCCAm = gKCCA([0.2, -5, 1], X, Y, kpars )

plotfn = function(v) 
    mlfs = 10pt
    D1= vcat([createDF(df, Y) for df in v]...)
    
plot(D1, xgroup=:df,
    Geom.subplot_grid(Coord.cartesian(ymin=-3, ymax=3),
        layer(x=:x, y=:y2, Geom.line,  Theme(default_color=colorant"red")),
        layer(x=:x, y=:y, Geom.point)
    ),
    Guide.ylabel("<b>YA</b><sub>1</sub>"),
    Theme(plot_padding=0mm, major_label_font_size=mlfs)
 )
end

pb = plotfn(4:6)
Gadfly.add_plot_element!(pb, Guide.xlabel("<b>XW</b><sub>1</sub> (gKCCA)" ))

M = Array(Compose.Context, (2,1))
M[1] = compose(context(0,0, 1.0, 0.45), render(plotfn(1:3)))
M[2] = compose(context(0,0, 1.0, 0.55), render(pb))

vstack(M...)
```

![](Fig_example2.png)

