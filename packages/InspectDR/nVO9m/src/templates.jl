#InspectDR: Plot generation templates
#-------------------------------------------------------------------------------

#Want more resolution on y-axis than default:
#TODO: is there a better way???
_yaxisscale(s::Symbol) = AxisScale(s, tgtmajor=8, tgtminor=2)

function Plot2D(xscale::Symbol, yscalelist::Vector{Symbol}; title::String="",
	xlabel::String="", ylabels::Vector{String}=String[], kwargs...)
	plot = InspectDR.Plot2D(;kwargs...)
	plot.xscale = AxisScale(xscale)

	#TODO: remove restriction once InspectDR deals better with 0 strips:
	if length(yscalelist) < 1
		yscalelist = [:lin]
	end

	plot.strips = [] #Reset
	for yscale in yscalelist
		strip = InspectDR.GraphStrip()
		push!(plot.strips, strip)
		strip.yscale = _yaxisscale(yscale)
	end

	a = plot.annotation
		a.title = title
		a.xlabel = xlabel
		a.ylabels = ylabels

	return plot
end
#Single y strip:
Plot2D(xscale::Symbol, yscale::Symbol; kwargs...) = Plot2D(xscale, [yscale]; kwargs...)

#Generate empty Bode plot:
function bodeplot(;title="Bode Plot", xlabel="Frequency (Hz)",
	ylabels=["Magnitude (dB)", "Phase (°)"], kwargs...)
	plot = InspectDR.Plot2D(:log10, [:dB20, :lin], title=title,
		xlabel=xlabel, ylabels=ylabels; kwargs...
	)

	#Control grid visibility:
	for strip in plot.strips
		strip.grid = InspectDR.GridRect(vmajor=true, vminor=true, hmajor=false)
	end

	return plot
end

#Generate empty transient plot:
function transientplot(yscalelist::Vector{Symbol}; title="Time-Domain Plot",
	xlabel="Time (s)", kwargs...)
	plot = Plot2D(:lin, yscalelist, title=title, xlabel=xlabel; kwargs...)
	plot.layout[:enable_legend] = true
	#plot.layout[:halloc_legend] = 150

	for graph in plot.strips
		graph.grid = InspectDR.GridRect(vmajor=true, vminor=true, hmajor=true)
	end

	#Use SI notation on both x & y axes:
	plot.layout[:format_xtick] = TickLabelStyle(NumericIO.UEXPONENT_SI) 
	plot.layout[:format_ytick] = TickLabelStyle(NumericIO.UEXPONENT_SI) 
	return plot
end
transientplot(yscale::Symbol=:lin; kwargs...) = transientplot([yscale]; kwargs...)

#Generate empty Smith chart:
function smithchart(t::Symbol=:Z; ref::Number=1.0, title="Smith Chart",
	xlabel = "Real(Γ)", ylabels = ["Imaginary(Γ)"], kwargs...)
	smithext = InspectDR.PExtents1D(min=-1.1,max=1.1) #WANTCONST A bit of padding
	plot = InspectDR.Plot2D(:lin, :lin, title=title, xlabel=xlabel, ylabels=ylabels; kwargs...)
	graph = plot.strips[1]
	graph.grid = InspectDR.GridSmith(t, ref=ref)
	plot.xext_full = smithext
	graph.yext_full = smithext
	return plot
end

#Last line
