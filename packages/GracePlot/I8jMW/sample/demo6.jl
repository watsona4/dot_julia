#GracePlot demonstration 6: Building a template
#-------------------------------------------------------------------------------

using GracePlot
import GracePlot.Meter


#==Input data
===============================================================================#
x=collect(-10:0.1:10)


#==Configuration
===============================================================================#
pdefaults = defaults(linewidth=1, linestyle=:solid)
dataline = line(width=4)
frameline = line(width=2.5)
refsize = 20e-2 #Reference: 20cm canvas
(wpage, hpage) = (1.6, 1) #Relative dimensions
(nrows, ncols) = (2,2)
Δxlegend = .17

#Offsets from ideal graph boundary to allow sapce for tick labels, etc:
(Δxmin, Δxmax) = (.09, .02)
(Δymin, Δymax) = (.065, .055)


#==Position calculations
===============================================================================#
function graph_position(row, col) #0-based row/col
	(w, h) = ((wpage-Δxlegend)/ncols, hpage/nrows) #WANTCONST Graph  w/h
	(xstart, ystart) = (w*col, hpage-h*(row+1)) #WANTCONST 

	return limits(
		xmin = xstart+Δxmin, xmax = xstart+w-Δxmax,
		ymin = ystart+Δymin, ymax = ystart+h-Δymax
	)
end

function legend_position(row, col)
	gpos = graph_position(row, col)
	return (gpos.xmax, gpos.ymax)
end


#==Generate plot
===============================================================================#
plot = GracePlot.new(pdefaults, fixedcanvas=true)
	set(plot, canvas(Meter(refsize*wpage), Meter(refsize*hpage))) #Force canvas size
	w = get(plot, :wview); h = get(plot, :hview)
	@show w, h #Confirm canvas size

#Add subplots:
let g, y #HIDEWARN_0.7
for gidx in 1:4
g = add(plot, subtitle="Subplot $gidx")
	row = div(gidx-1, ncols) #0-based
	col = mod(gidx-1, ncols) #0-based
	set(g, frameline=frameline, view=graph_position(row, col))
	set(g, legend(display=false))

	for i in 1:10
		y = i*x/10
		ds = add(g, x, y, dataline, id="Dataset $i")
	end

	autofit(g)
end
end

#Position legend:
g = graph(plot, 1) #Get second graph
set(g, legend(loc=legend_position(0,1), loctype=:view, charsize=.75))
set(g, legend(display=true))

#Finalize:
redraw(plot)

#Last line
