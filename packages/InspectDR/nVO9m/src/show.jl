#InspectDR: show functions
#-------------------------------------------------------------------------------

function Base.show(io::IO, plot::Plot2D)
	n = length(plot.strips)
	print(io, "Plot2D(\"$(plot.annotation.title)\", $n strips)")
end

function Base.show(io::IO, mplot::Multiplot)
	n = length(mplot.subplots)
	print(io, "Multiplot(\"$(mplot.title)\", $n subplots)")
end

if GtkAvailable

function Base.show(io::IO, w::PlotWidget)
	plot = w.src
	n = length(plot.strips)
	print(io, "PlotWidget(\"$(plot.annotation.title)\", $n strips)")
end

function Base.show(io::IO, gplot::GtkPlot)
	mplot = gplot.src
	n = length(mplot.subplots)
	print(io, "GtkPlot(\"$(mplot.title)\", $n subplots)")
end

end

#Last line
