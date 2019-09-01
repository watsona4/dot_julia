#GracePlot base types & core functions
#-------------------------------------------------------------------------------


#==Constants
===============================================================================#
const DEFAULT_DPI = 200 #Reasonable all-purpose resolution


#==Configuration
===============================================================================#
mutable struct Config
	command::String
end

function Config()
	command = get(ENV, "GRACEPLOT_COMMAND", "xmgrace")
	Config(command)
end

const config = Config()


#==Main type definitions
===============================================================================#

#Data vector type (don't support complex numbers):
const DataVec{T<:Real} = Vector{T}

#Graph coordinate (zero-based):
const GraphCoord = Tuple{Int, Int}

#-------------------------------------------------------------------------------
mutable struct Dataset
	x::DataVec
	y::DataVec
end

#-------------------------------------------------------------------------------
mutable struct Graph
	datasetcount::Int

	Graph() = new(0)
end

#-------------------------------------------------------------------------------
mutable struct CanvasAttributes <: AttributeList
	width::AbstractLength
	height::AbstractLength
end
canvas(width::AbstractLength, height::AbstractLength) = CanvasAttributes(width, height)

#-------------------------------------------------------------------------------
mutable struct Plot
	process::Base.Process
	guimode::Bool
	dpi::Int #Default rendering resolution

	#Width/height stored so user knows what it is
	#>>Smallest of height/width is considered unity by Grace<<
	canvas::CanvasAttributes

	ncols::Int #Number of columns assumed when accessing graphs with GraphCoord
	graphs::Vector{Graph}
	activegraph::Int
	log::Bool #set to true to log commands
end

#-------------------------------------------------------------------------------
mutable struct GraphRef
	plot::Plot
	index::Int
end

#-------------------------------------------------------------------------------
mutable struct DatasetRef
	graph::GraphRef
	id::Int
end

#-------------------------------------------------------------------------------
mutable struct DefaultAttributes <: AttributeList
	linewidth
	linestyle
	color
	pattern
	font #==
		Times-Roman, Times-Italic, Times-Bold, Times-BoldItalic
		Helvetica, Helvetica-Oblique, Helvetica-Bold, Helvetica-BoldOblique
		Courier, Courier-Oblique, Courier-Bold, Courier-BoldOblique
		Symbol, ZapfDingbats ==#
	charsize   #Multiplied by 100, for some reason; Affects axis labels
	symbolsize #Multiplied by 100, for some reason
	sformat
end
eval(genexpr_attriblistbuilder(:defaults, DefaultAttributes)) #"defaults" constructor

#-------------------------------------------------------------------------------
mutable struct CartesianLimAttributes <: AttributeList
	xmin; xmax
	ymin; ymax
end
eval(genexpr_attriblistbuilder(:limits, CartesianLimAttributes)) #"limits" constructor

#-------------------------------------------------------------------------------
mutable struct TextAttributes <: AttributeList
	#Common attributes
	value::String
	font
	size
	color

	#Non-common (for annotations)
	loctype #:view/world
	loc #(x, y)
	just
end
eval(genexpr_attriblistbuilder(:text, TextAttributes, reqfieldcnt=1)) #"text" constructor

#-------------------------------------------------------------------------------
mutable struct LineAttributes <: AttributeList
	_type
	style
	width
	color
	pattern
end
eval(genexpr_attriblistbuilder(:line, LineAttributes, reqfieldcnt=0)) #"line" constructor

#-------------------------------------------------------------------------------
mutable struct GlyphAttributes <: AttributeList #Don't use "Symbol" - name used by Julia
	shape
	size
	color
	pattern
	fillcolor
	fillpattern
	linewidth
	linestyle
	char #ASCII value: Use a letter as a glyph?
	charfont
	skip
end
eval(genexpr_attriblistbuilder(:glyph, GlyphAttributes, reqfieldcnt=0)) #"glyph" constructor

#-------------------------------------------------------------------------------
mutable struct FrameAttributes <: AttributeList
	frametype
	color
	pattern
	bkgndcolor
	bkgndpattern

	linestyle
	linewidth
end

#-------------------------------------------------------------------------------
mutable struct LegendAttributes <: AttributeList
	loctype #:view/world
	loc #(x, y)

	display #true/false

	font
	charsize #Multiplied by 100, for some reason
	color
	length
	invert

	#Between items:
	hgap
	vgap

	boxcolor
	boxpattern
	boxlinewidth
	boxlinestyle
	boxfillcolor
	boxfillpattern
end
eval(genexpr_attriblistbuilder(:legend, LegendAttributes)) #"legend" constructor

#-------------------------------------------------------------------------------
mutable struct AxesAttributes <: AttributeList
	xmin; xmax; ymin; ymax
	xscale; yscale #:lin/:log/:reciprocal
	invertx; inverty #:on/:off
end
eval(genexpr_attriblistbuilder(:paxes, AxesAttributes, reqfieldcnt=0)) #"axes" constructor

#-------------------------------------------------------------------------------
mutable struct AxisTickAttributes <: AttributeList #???
	majorspacing
	minortickcount
	placeatrounded
#	autotickdivisions
	direction #in/out/both
end

#Properties for Major/Minor ticks:???
#-------------------------------------------------------------------------------
mutable struct TickAttributes <: AttributeList
	size
	color
	linewidth
	linestyle
end


#==Other constructors/accessors
===============================================================================#
function new(args...; guimode::Bool=true, dpi::Int=DEFAULT_DPI,
		fixedcanvas::Bool=true, template=nothing, emptyplot::Bool=true, kwargs...)
	defaultcanvasratio = 1.6 #WANTCONST Roughly golden ratio
	basecmd = config.command
	canvasarg = fixedcanvas ? [] : "-free"
		#-free: Stretch canvas to client area
	templatearg = template!=nothing ? ["-param" "$template"] : []
	guiarg = guimode ? [] : "-hardcopy"
	#Other switches:
	#   -dpipe 0: STDIN; -pipe switch seems broken
	cmd = `$basecmd -dpipe 0 -nosafe -noask $guiarg $canvasarg $templatearg`
	process = open(cmd, "w")
	activegraph = -1 #None active @ start

	#Default width/height (32cm x 20cm - roughly golden ratio):
	c = 0.01 #WANTCONST centi
	h = 20c; w = h*defaultcanvasratio
	ncols = 2 #Assume 2 graph columns, by default

	plot = Plot(process, guimode, dpi, canvas(Meter(w), Meter(h)), ncols,
		Graph[Graph()], activegraph, false
	)
	#At this point, plot.canvas is still basically meaningless...

	#Only update plot canvas size (send to xmgrace) if not reading template...
	#(Template might already have a canvas size set)
	#...So when templates are used, the value of plot.canvas is meaningless...
	if nothing == template
		set(plot, plot.canvas)
		arrange(plot, (1, 1)) #Fit plot to new canvas size
	end

	if emptyplot
		clearall(plot)
		if nothing == template
			kill(graph(plot, 0))
		end
	end

	set(plot, args...; kwargs...)
	return plot
end

Plot() = new() #Alias for code using type name for constructor.

graphindex(g::GraphRef) = g.index
graph(p::Plot, idx::Int) = GraphRef(p, idx)
graph(p::Plot, coord::GraphCoord) =
	((row,col) = coord; return GraphRef(p, p.ncols*row+col))
graphdata(g::GraphRef) = g.plot.graphs[graphindex(g)+1]

#==Communication
===============================================================================#
function sendcmd(p::Plot, cmd::String)
	write(p.process, cmd)
	write(p.process, "\n")
	if p.log; (@info("$cmd\n")); end
end

function flushpipe(p::Plot)
	flush(p.process)
end

Base.close(p::Plot) = sendcmd(p, "EXIT")
#Base.close(p::Plot) = kill(p.process)


#==Other helper functions
===============================================================================#

#Escape all quotes from a string expression.
#-------------------------------------------------------------------------------
escapequotes(s::String) = replace(s, r"\"", "\\\"")


#Last line
