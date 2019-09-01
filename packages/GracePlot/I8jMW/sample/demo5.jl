#GracePlot demonstration 5: Another multi-plot
#-------------------------------------------------------------------------------

using GracePlot

#==Input data
===============================================================================#
x=collect(-10:0.1:10)
y = []
for i in 1:4
	push!(y, (x.^i)./(10^i)) #Normalized powers of x 
end
titles = ["Linear", "Quadratic", "Cubic", "Quartic"]


#=="Defaults"
===============================================================================#

pdefaults = defaults(font="Courier-BoldOblique",
	linewidth=2.5, linestyle=:solid,
	charsize=2, symbolsize=.75
)


#==Generate plot
===============================================================================#
plot = GracePlot.new()
set(plot, pdefaults)

#Add 4 subplots:
for gidx in 0:3
	g = add(plot, subtitle = titles[gidx+1])

	#Add 10 datasets:
	for i in 1:10
		ds = add(g, x, i.*y[gidx+1], glyph(shape=i, skip=20))
	end

	autofit(g)
end

#Make it a multi-graph plot:
#arrange(plot, (1, 4))
arrange(plot, (2, 3))

#Finalize:
redraw(plot)

#Last line
