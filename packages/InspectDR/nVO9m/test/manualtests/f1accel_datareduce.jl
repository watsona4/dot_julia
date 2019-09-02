#Controlled HF noise plot (test data reduction)
using InspectDR
using Colors

#==Input constants
===============================================================================#
dfltline = line(color=RGB24(0, 0, 1), width=1, style=:solid)


#==Input data
===============================================================================#
function gennoise(xv, yv; step=.01, npts=20, lo=0, hi=1)
	xmax = xv[end]
	xnew = xmax+collect(step:step:(npts*step))
	ynew = similar(xnew)
	v = Float64[lo, hi]
	for i in 1:length(ynew)
		ynew[i] = v[(i&0x1)+1]
	end
	append!(xv, xnew)
	append!(yv, ynew)
end

function addpts(ynew, xv, yv; step=1.0)
	xmax = xv[end]
	npts = length(ynew)
	xnew = xmax+collect(step:step:(npts*step))
	append!(xv, xnew)
	append!(yv, ynew)
end

#Generate dataset:
	x = Float64[0]
	y = Float64[0]
	addpts(Float64[1.1,-.1,], x,y) #Force maximum y-extents
	addpts(Float64[1,1,1,0,0], x,y)
	gennoise(x,y)
	addpts(Float64[0,1,1,1,0,0], x,y)
	gennoise(x,y)
	addpts(Float64[1,1,1,0,0], x,y)
	gennoise(x,y)
	addpts(Float64[1,1,1,0,0], x,y)


#==Generate plot
===============================================================================#
plot = InspectDR.Plot2D()
wfrm = add(plot, x, y+1)
wfrm.line = dfltline
plot.xres=1000 #Force resolution

a = plot.annotation
a.title = "Sample Plot (λ)"
a.xlabel = "Time (s)"
a.ylabels = ["Signal Voltage (V)"]

gplot = display(InspectDR.GtkDisplay(), plot)

:Test_Complete
