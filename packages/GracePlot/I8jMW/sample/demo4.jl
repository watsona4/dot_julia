#GracePlot demonstration 4: simple 2x2 array of subplots
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
template = GracePlot.template("plot2x2thick_mono")


#==Generate plot
===============================================================================#
plot = GracePlot.new(fixedcanvas=true, template=template)
#Add 4 subplots:
let g, ds #HIDEWARN_0.7
for gidx in 0:3
	g = add(plot, subtitle = titles[gidx+1])

	#Add 10 datasets:
	for i in 1:10
		ds = add(g, x, i.*y[gidx+1])
	end

	autofit(g)
end
end

#Finalize:
redraw(plot)

#Last line
