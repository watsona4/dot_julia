#GracePlot demonstration 2: Multi-graph plot stress test
#-------------------------------------------------------------------------------

using GracePlot


#==Input data
===============================================================================#
x=collect(-10:0.1:10)
y2 = x.^2
y3 = x.^3


#=="Defaults"
===============================================================================#
pdefaults = defaults(linewidth=2.5, linestyle=:solid)
thinline = line(width=0.5)
thickline = line(style=:ldash, width=8, color=1)
thickframeline = line(width=2.5)
loglin = paxes(xscale = :log, yscale = :lin)
stdleg = legend(loc=(.9, 1/3-1/20), loctype=:view, charsize=.75)

#==Generate plot
===============================================================================#
plot = GracePlot.new()
@show get(plot, :wview), get(plot, :hview) #Not useful yet
set(plot, pdefaults)
#Try a multi-graph plot:
arrange(plot, (3, 2), offset=0.08, hgap=0.15, vgap=0.3)
g = graph(plot, (2, 0)) #Get a reference to graph (1,2)
	txt = text("Parabola (\\f{Times-Italic}y=x\\f{}\\S2\\N)", size=2)
	set(g, stdleg, xlabel = text("x-axis", color=2), ylabel = "y-axis")
	set(g, unsupported = "no dice")
	set(g, subtitle = txt)
	set(g, frameline = thickframeline)
	#Add datasets:
	ds = add(g, x, y2, id="y^2")
		set(ds, glyph(shape=:diamond, color=5), glyph(skip=10))
		set(ds, line(color=3))
	ds = add(g, x, 2 .* y2, id="2y^2")
		set(ds, glyph(shape=:char, char=Int('!'), size=2, skip=10))
	autofit(g)
g = graph(plot, (0, 1))
	set(g, subtitle = "Cubic Function (\\f{Times-Italic}y=x\\f{}\\S3\\N)")
	#Add datasets:
	ds = add(g, x, y3, thickline)
		set(ds, line(style=3, width=8, color=1)) #Overwrite defaults
	autofit(g)
	#autofit(g, x=true) #Not supported by Grace v5.1.23?
g = graph(plot, (1, 1)) #Play around with another graph
	#Test message logging functionality:
	plot.log = true
	set(g, paxes(xmin = 0.1, xmax = 1000, ymin = 1000, ymax = 5000))
	set(g, loglin, paxes(inverty = :on))
	plot.log = false

#Finalize:
set(plot, focus=g)
redraw(plot)

#Other possible operations... but don't test here:
#sleep(1); close(plot)

#Last line

