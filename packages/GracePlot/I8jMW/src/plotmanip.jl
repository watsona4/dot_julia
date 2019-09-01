#GracePlot functions to control Grace/xmgrace
#-------------------------------------------------------------------------------

#==Type definitions
===============================================================================#

#Map an individual attribute to a setter function:
const AttributeFunctionMap = Dict{Symbol, Function}

#Map an "AttributeList" element to a setter function:
#NOTE: Unlike individual attributes, typed obects do not need to be "set"
#      using keyword arguments
#TODO: Find way to restrict Dict to DataTypes inherited from AttributeList
#const AttributeListFunctionMap = Dict{DataType, Function}
#Use IdDict: Compatibility with precompile.
const AttributeListFunctionMap = IdDict #{DataType, Function}

#Map attribute fields to grace commands:
const AttributeCmdMap = Dict{Symbol, String}


#==Helper functions
===============================================================================#

#Copy in only attributes that are not "nothing" (thus "new"):
function copynew!(dest::T, newlist::T) where T<:AttributeList
	for attrib in fieldnames(newlist)
		v = getfield(newlist, attrib)

		if v != nothing
			setfield!(dest, attrib, v)
		end
	end
end

function setattrib(p::Plot, cmd::String, value::Any) #Catchall
	sendcmd(p, "$cmd $value")
end
function setattrib(p::Plot, cmd::String, value::Nothing)
	#Nothing to do
end
function setattrib(p::Plot, cmd::String, value::String)
	sendcmd(p, "$cmd \"$value\"") #Add quotes around string
end
function setattrib(p::Plot, cmd::String, value::GraceConstLitteral)
	sendcmd(p, "$cmd $(value.s)") #Send associated string, unquoted
end
function setattrib(p::Plot, cmd::String, value::Tuple{Number, Number})
	v1 = value[1]; v2 = value[2]
	sendcmd(p, "$cmd $v1, $v2") #Send out tuple
end
setattrib(p::Plot, cmd::String, value::Symbol) =
	setattrib(p, cmd, graceconstmap[value])

#Set plot attributes for a given element:
#-------------------------------------------------------------------------------
function setattrib(p::Plot, fmap::AttributeCmdMap, prefix::String, data::Any)
	for attrib in fieldnames(typeof(data))
		v = getfield(data, attrib)

		if v != nothing
			subcmd = get(fmap, attrib, nothing)

			if subcmd != nothing
				setattrib(p, "$prefix$subcmd", v)
			else
				dtype = typeof(data)
				@warn("Attribute \"$attrib\" of $dtype not currently supported.")
			end
		end
	end
end

#Set graph attributes for a given element:
#-------------------------------------------------------------------------------
function setattrib(g::GraphRef, fmap::AttributeCmdMap, prefix::String, data::Any)
	setactive(g)
	return setattrib(g.plot, fmap, prefix, data)
end
function setattrib(g::GraphRef, prefix::String, value::String)
	setactive(g)
	return setattrib(g.plot, prefix, value)
end

#Set dataset attribute:
#-------------------------------------------------------------------------------
function setattrib(ds::DatasetRef, fmap::AttributeCmdMap, data::Any)
	dsid = ds.id
	setattrib(ds.graph, fmap, "S$dsid ", data)
end
function setattrib(ds::DatasetRef, cmd::String, value::String)
	dsid = ds.id
	setattrib(ds.graph, "S$dsid $cmd", value)
end

#Core algorithm for "set" interface:
#-------------------------------------------------------------------------------
function _set(obj::Any, listfnmap::AttributeListFunctionMap, fnmap::AttributeFunctionMap, args...; kwargs...)
	for value in args
		setfn = get(listfnmap, typeof(value), nothing)

		if setfn != nothing
			setfn(obj, value)
		else
			argstr = string(typeof(value))
			objtype = typeof(obj)
			@warn("Argument \"$argstr\" not recognized by \"set(::$objtype, ...)\"")
		end
	end

	for (arg, value) in kwargs
		setfn = get(fnmap, arg, nothing)

		if setfn != nothing
			setfn(obj, value)
		else
			argstr = string(arg)
			objtype = typeof(obj)
			@warn("Argument \"$argstr\" not recognized by \"set(::$objtype, ...)\"")
		end
	end
	return
end

#Core algorithm for "get" interface:
#-------------------------------------------------------------------------------
function getattrib(obj::Any, fnmap::AttributeFunctionMap, attrib::Symbol)
	getfn = get(fnmap, attrib, nothing)

	if nothing == getfn
		argstr = string(attrib)
		objtype = typeof(obj)
		throw("Argument \"$argstr\" not recognized by \"set(::$objtype, ...)\"")
	end

	return getfn(obj)
end

#Core algorithm for "addannotation" interface:
#(Just use set in the background... it does what you would want...)
#-------------------------------------------------------------------------------
function _addannotation(obj::Any, listfnmap::AttributeListFunctionMap, fnmap::AttributeFunctionMap, args...; kwargs...)
	return _set(obj::Any, listfnmap, fnmap, args...; kwargs...)
end

#==Plot-level functionality
===============================================================================#

#-------------------------------------------------------------------------------
updateall(p::Plot) = sendcmd(p, "UPDATEALL")
function redraw(p::Plot; update=true)
	if !p.guimode; return; end #Causes issues when !guimode
	result = sendcmd(p, "REDRAW")
	if update; updateall(p); end
	return result
end

#-------------------------------------------------------------------------------
function clearall(p::Plot; update::Bool=true, killdata::Bool=true)
	#Delete graphs in reverse order
	#(Grace wants to keep around lower numbered graphs)
	for gidx in (length(p.graphs):-1:1) .- 1
		clearall(graph(p, gidx), update=false, killdata=killdata)
	end

	#Trash old graph info:
	p.graphs = Graph[]

	#Sync up UI, if desired:
	if update
		updateall(p)
	end
end

#-------------------------------------------------------------------------------
function setpagesize(p::Plot, a::CanvasAttributes)
	p.canvas = a
	width = round(Int, val(TPoint(a.width)))
	height = round(Int, val(TPoint(a.height)))
	sendcmd(p, "PAGE SIZE $width, $height")
	#Will also stretch entire plot if RESIZE is used instead:
	#sendcmd(p, "PAGE RESIZE $width, $height")
	return a
end

#Return cached canvas width/height
#-------------------------------------------------------------------------------
getwcanvas(p::Plot) = p.canvas.width
gethcanvas(p::Plot) = p.canvas.height

#Obtain "VIEW" width/height (given cached canvas width/height)
#-------------------------------------------------------------------------------
function getaspectratio(p::Plot)
	w = val(TPoint(p.canvas.width))
	h = val(TPoint(p.canvas.height))
	return w/h
end

#Return canvas width in normalized "view" coordinates:
function getwview(p::Plot)
	ar=getaspectratio(p)
	return (ar>1) ? ar : 1
end

#Return canvas width in normalized "view" coordinates:
function gethview(p::Plot)
	ar=getaspectratio(p)
	return (ar>1) ? 1 : (1/ar)
end

#-------------------------------------------------------------------------------
setnumcols(p::Plot, cols::Int) = (p.ncols = cols)

#-------------------------------------------------------------------------------
function arrange(p::Plot, gdim::GraphCoord; offset=0.15, hgap=0.15, vgap=0.15)
	(rows, cols) = gdim
	sendcmd(p, "ARRANGE($rows, $cols, $offset, $hgap, $vgap)")
	setnumcols(p, cols)
	newsize = rows*cols
	delta = newsize - length(p.graphs)

	for i in 1:delta
		push!(p.graphs, Graph())
	end

	if delta < 0
		resize!(p.graphs, newsize)
		if p.activegraph >= newsize
			setactive(graph(p, newsize-1))
		end
	end
end

#Add new graph to a plot
#NOTE: update = true sends UPDATEALL command to avoid having the GUI out of
#      sync with the plot itself. User expected to call updateall manually when
#      using update=false
#-------------------------------------------------------------------------------
function add(p::Plot, args...; update=true, kwargs...)
	gidx = length(p.graphs)
	push!(p.graphs, Graph())
	g = graph(p, gidx)
	setenable(g, true)
#	setactive(g)
	if update; updateall(p); end
	set(g, args...; kwargs...)

	return g
end

#Add plot annotation:
#-------------------------------------------------------------------------------
function addtext(p::Plot, a::TextAttributes)
	prefix = "    STRING"
	sendcmd(p, "WITH STRING")
	sendcmd(p, "$prefix ON")
	setattrib(p::Plot, "$prefix LOCTYPE", a.loctype)
	setattrib(p::Plot, "$prefix", a.loc)
	setattrib(p::Plot, "$prefix FONT", a.font)
	setattrib(p::Plot, "$prefix CHAR SIZE", a.size)
	setattrib(p::Plot, "$prefix COLOR", a.color)
	setattrib(p::Plot, "$prefix JUST", a.just)
	setattrib(p::Plot, "$prefix DEF", a.value) #This has to go last, for some reason
	#...so cannot use attribcmdmap method....
end

#-------------------------------------------------------------------------------
const defaults_attribcmdmap = AttributeCmdMap(
	:linewidth  => "LINEWIDTH",
	:linestyle  => "LINESTYLE",
	:color      => "COLOR",
	:pattern    => "PATTERN",
	:font       => "FONT",
	:charsize   => "CHAR SIZE",
	:symbolsize => "SYMBOL SIZE",
	:sformat    => "SFORMAT",
)

setdefaults(p::Plot, a::DefaultAttributes) = setattrib(p, defaults_attribcmdmap, "DEFAULT ", a)

#==Graph-level functionality
===============================================================================#

#-------------------------------------------------------------------------------
function Base.kill(g::GraphRef)
	gidx = graphindex(g)
	sendcmd(g.plot, "KILL G$gidx")
end

#-------------------------------------------------------------------------------
function setactive(g::GraphRef)
	gidx = graphindex(g)
	if g.plot.activegraph != gidx
		g.plot.activegraph = gidx
		sendcmd(g.plot, "WITH G$gidx")
	end
	return gidx
end

#-------------------------------------------------------------------------------
function setfocus(g::GraphRef)
	gidx = graphindex(g)
	sendcmd(g.plot, "FOCUS G$gidx")
end

#Convenience functions: Enables the use of set(::Plot, ...) interface:
#(Plot argument is otherwise redundant)
#-------------------------------------------------------------------------------
function setactive(p::Plot, g::GraphRef)
	_ensure(p==g.plot,
		ArgumentError("setactive: GraphRef does not match Plot to control."))
	setactive(g)
end

function setfocus(p::Plot, g::GraphRef)
	_ensure(p==g.plot,
		ArgumentError("setfocus: GraphRef does not match Plot to control."))
	setfocus(g)
end
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
function setenable(g::GraphRef, value::Bool)
	v = graceconstmap[value ? (:on) : (:off)]
	gidx = graphindex(g)
	setattrib(g.plot, "G$gidx", v)
end

#-------------------------------------------------------------------------------
function clearall(g::GraphRef; update::Bool=true, killdata::Bool=true)
	setenable(g, false)
	gdata = graphdata(g)

	if killdata
		#Delete datasets in reverse order
		#(Grace wants to keep around lower numbered datasets)
		for idx in (gdata.datasetcount-1:-1:0)
			killdataset(g, idx)
		end
	end

	#Sync up UI, if desired:
	if update
		updateall(p)
	end
end

#NOTE: AUTOSCALE X/Y does not seem to work...
#-------------------------------------------------------------------------------
function _autofit(g::GraphRef, x::Bool=false, y::Bool=false)
	cmd = "AUTOSCALE"
	if x && y
		; #Send command by itself
	elseif x
		cmd *= " XAXES"
	elseif y
		cmd *= " YAXES"
	else
		return 0
	end

	setactive(g)
	sendcmd(g.plot, cmd)
end
_autofit(g::GraphRef, x::Nothing, y::Nothing) = _autofit(g, true, true)
_autofit(g::GraphRef, x::Nothing, y::Bool) = _autofit(g, false, y)
_autofit(g::GraphRef, x::Bool, y::Nothing) = _autofit(g, x, false)
autofit(g::GraphRef; x=nothing, y=nothing) = _autofit(g, x, y)

#-------------------------------------------------------------------------------
const limits_attribcmdmap = AttributeCmdMap(
	:xmin => "XMIN",
	:xmax => "XMAX",
	:ymin => "YMIN",
	:ymax => "YMAX",
)

setview(g::GraphRef, a::CartesianLimAttributes) = setattrib(g, limits_attribcmdmap, "VIEW ", a)

#-------------------------------------------------------------------------------
const title_attribcmdmap = AttributeCmdMap(
	:value => "",
	:font  => "FONT",
	:size  => "SIZE",
	:color => "COLOR",
)

settitle(g::GraphRef, a::TextAttributes) = setattrib(g, title_attribcmdmap, "TITLE ", a)
setsubtitle(g::GraphRef, a::TextAttributes) = setattrib(g, title_attribcmdmap, "SUBTITLE ", a)
settitle(g::GraphRef, title::String) = settitle(g, text(title))
setsubtitle(g::GraphRef, title::String) = setsubtitle(g, text(title))

#-------------------------------------------------------------------------------
const label_attribcmdmap = AttributeCmdMap(
	:value => "",
	:font  => "FONT",
	:size  => "CHAR SIZE",
	:color => "COLOR",
)

setxlabel(g::GraphRef, a::TextAttributes) = setattrib(g, title_attribcmdmap, "XAXIS LABEL ", a)
setylabel(g::GraphRef, a::TextAttributes) = setattrib(g, title_attribcmdmap, "YAXIS LABEL ", a)
setxlabel(g::GraphRef, label::String) = setxlabel(g, text(label))
setylabel(g::GraphRef, label::String) = setylabel(g, text(label))

#-------------------------------------------------------------------------------
const frameline_attribcmdmap = AttributeCmdMap(
	:style => "LINESTYLE",
	:width => "LINEWIDTH",
)
setframeline(g::GraphRef, a::LineAttributes) = setattrib(g, frameline_attribcmdmap, "FRAME ", a)

const axes_attribcmdmap = AttributeCmdMap(
	:xmin => "WORLD XMIN", :xmax => "WORLD XMAX",
	:ymin => "WORLD YMIN", :ymax => "WORLD YMAX",
	:xscale  => "XAXES SCALE",
	:yscale  => "YAXES SCALE",
	:invertx => "XAXES INVERT",
	:inverty => "YAXES INVERT",
)
setaxes(g::GraphRef, a::AxesAttributes) = setattrib(g, axes_attribcmdmap, "", a)

const legend_attribcmdmap = AttributeCmdMap(
	:loctype   => "LOCTYPE",
	:loc       => "",
	:display   => "",
	:font      => "FONT",
	:charsize  => "CHAR SIZE",
	:color     => "COLOR",
	:length    => "LENGTH",
	:invert    => "INVERT",
	:hgap      => "HGAP",
	:vgap      => "VGAP",
	:boxcolor       => "BOX COLOR",
	:boxpattern     => "BOX PATTERN",
	:boxlinewidth   => "BOX LINEWIDTH",
	:boxlinestyle   => "BOX LINESTYLE",
	:boxfillcolor   => "BOX FILL COLOR",
	:boxfillpattern => "BOX FILL PATTERN",
)
setlegend(g::GraphRef, a::LegendAttributes) = setattrib(g, legend_attribcmdmap, "LEGEND ", a)


#==Dataset-level functionality
===============================================================================#

#Sadly, appears to be no way to kill data without linestyle, etc...
#-------------------------------------------------------------------------------
function killdataset(g::GraphRef, index::Int)
	gidx = graphindex(g)
	sendcmd(g.plot, "KILL G$gidx.S$index")
end

#-------------------------------------------------------------------------------
function add(g::GraphRef, x::DataVec, y::DataVec, args...; kwargs...)
	_ensure(length(x) == length(y),
		ArgumentError("GracePlot.add(): x & y vlengths must match."))
	p = g.plot
	gidx = graphindex(g)
	gdata = graphdata(g)
	dsid = gdata.datasetcount
	gdata.datasetcount += 1
	prefix = "G$(gidx).S$dsid"

	sendcmd(p, "$prefix TYPE XY")
	for (_x, _y) in zip(x, y)
		sendcmd(p, "$prefix POINT $_x, $_y")
	end

	ds = DatasetRef(g, dsid)
	set(ds, args...; kwargs...)
	return ds
end

#-------------------------------------------------------------------------------
const dsline_attribcmdmap = AttributeCmdMap(
	:_type => "LINE TYPE",
	:style => "LINE LINESTYLE",
	:width => "LINE LINEWIDTH",
	:color => "LINE COLOR",
)
setline(ds::DatasetRef, a::LineAttributes) = setattrib(ds, dsline_attribcmdmap, a)

#-------------------------------------------------------------------------------
const glyph_attribcmdmap = AttributeCmdMap(
	:shape       => "SYMBOL",
	:size        => "SYMBOL SIZE",
	:color       => "SYMBOL COLOR",
	:pattern     => "SYMBOL PATTERN",
	:fillcolor   => "SYMBOL FILL COLOR",
	:fillpattern => "SYMBOL FILL PATTERN",
	:linewidth   => "SYMBOL LINEWIDTH",
	:linestyle   => "SYMBOL LINESTYLE",
	:char        => "SYMBOL CHAR",
	:charfont    => "SYMBOL CHAR FONT",
	:skip        => "SYMBOL SKIP",
)
setglyph(ds::DatasetRef, a::GlyphAttributes) = setattrib(ds, glyph_attribcmdmap, a)

setdatasetid(ds::DatasetRef, id::String) = setattrib(ds, "LEGEND", id)

#==Define cleaner "set" interface (minimize # of "export"-ed functions)
===============================================================================#

#-------------------------------------------------------------------------------
const empty_listfnmap = AttributeListFunctionMap()
const empty_fnmap = AttributeFunctionMap()

#-------------------------------------------------------------------------------
const setplot_listfnmap = AttributeListFunctionMap(
	CanvasAttributes  => setpagesize,
	DefaultAttributes => setdefaults,
)
const setplot_fnmap = AttributeFunctionMap(
	:ncols  => setnumcols,
	:active => setactive,
	:focus  => setfocus,
)
set(p::Plot, args...; kwargs...) = _set(p, setplot_listfnmap, setplot_fnmap, args...; kwargs...)

#-------------------------------------------------------------------------------
const setgraph_listfnmap = AttributeListFunctionMap(
	AxesAttributes   => setaxes,
	LegendAttributes => setlegend,
)
const setgraph_fnmap = AttributeFunctionMap(
	:enable    => setenable,
	:view      => setview,
	:title     => settitle,
	:subtitle  => setsubtitle,
	:xlabel    => setxlabel,
	:ylabel    => setylabel,
	:frameline => setframeline,
)
set(g::GraphRef, args...; kwargs...) = _set(g, setgraph_listfnmap, setgraph_fnmap, args...; kwargs...)

#-------------------------------------------------------------------------------
const setds_listfnmap = AttributeListFunctionMap(
	LineAttributes  => setline,
	GlyphAttributes => setglyph,
)
const setds_fnmap = AttributeFunctionMap(
	:id => setdatasetid,
)
set(ds::DatasetRef, args...; kwargs...) = _set(ds, setds_listfnmap, setds_fnmap, args...; kwargs...)

#==Define cleaner "get" interface (minimize # of "export"-ed functions)
===============================================================================#
const getplot_fnmap = AttributeFunctionMap(
	:wcanvas  => getwcanvas,
	:hcanvas  => gethcanvas,
	:wview    => getwview,
	:hview    => gethview,
)
Base.get(p::Plot, attrib::Symbol) = getattrib(p, getplot_fnmap, attrib)


#==Define cleaner "addannotation" interface (minimize # of "export"-ed functions)
===============================================================================#

#-------------------------------------------------------------------------------
const addannot_listfnmap = AttributeListFunctionMap(
	TextAttributes  => addtext,
)
addannotation(p::Plot, args...; kwargs...) = _addannotation(p, addannot_listfnmap, empty_fnmap, args...; kwargs...)

#Last line
