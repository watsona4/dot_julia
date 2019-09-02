#InspectDR: IO functionnality for writing plots with Cairo
#-------------------------------------------------------------------------------

#==Constants
===============================================================================#
const MIMEpng = MIME"image/png"
const MIMEsvg = MIME"image/svg+xml"
const MIMEeps = MIME"image/eps"
const MIMEeps2 = MIME"application/eps" #Apparently this is also a MIME
const MIMEps = MIME"application/postscript" #TODO: support when Cairo.jl supports PSSurface
const MIMEpdf = MIME"application/pdf"

const MAPEXT2MIME = Dict{String,MIME}(
	".png" => MIMEpng(),
	".svg" => MIMEsvg(),
	".eps" => MIMEeps(),
	".pdf" => MIMEpdf(),
)

#If an easy way to read Cairo scripts back to a surface is found:
#const MIMEcairo = MIME"image/cairo"

#All supported MIMEs:
#EXCLUDE SVG so it can be turnd on/off??
const MIMEall = Union{MIMEpng, MIMEeps, MIMEeps2, MIMEpdf, MIMEsvg}


#=="Constructors"
===============================================================================#
_CairoSurface(io::IO, ::MIMEsvg, w::Float64, h::Float64) =
	Cairo.CairoSVGSurface(io, w, h)
_CairoSurface(io::IO, ::MIMEeps, w::Float64, h::Float64) =
	Cairo.CairoEPSSurface(io, w, h)
_CairoSurface(io::IO, ::MIMEeps2, w::Float64, h::Float64) =
	Cairo.CairoEPSSurface(io, w, h)
_CairoSurface(io::IO, ::MIMEpdf, w::Float64, h::Float64) =
	Cairo.CairoPDFSurface(io, w, h)


#=="withsurf" interface: Make uniform API for all output surfaces
===============================================================================#
function withsurf(fn::Function, stream::IO, mime::MIME, w::Float64, h::Float64)
	surf = _CairoSurface(stream, mime, w, h)
	ctx = CairoContext(surf)
	fn(ctx)
	Cairo.destroy(ctx)
	Cairo.destroy(surf)
end

#There is no PNG stream surface... must write from ARGB surface.
function withsurf(fn::Function, stream::IO, mime::MIMEpng, w::Float64, h::Float64)
	w = round(w); h = round(h)
	surf = Cairo.CairoARGBSurface(w, h)
	ctx = CairoContext(surf)
	fn(ctx)
	Cairo.destroy(ctx)
	Cairo.write_to_png(surf, stream)
	Cairo.destroy(surf)
end


#==MIME interface
===============================================================================#

#w, h: w/h of entire figure.
function _show(stream::IO, mime::MIME, mplot::Multiplot, w::Float64, h::Float64)
	yoffset = mplot.layout.values.valloc_title
	nrows, ncols = griddims_auto(mplot)
	wplot = w/ncols; hplot = (h-yoffset)/nrows

	withsurf(stream, mime, w, h) do ctx
		_reset(ctx)
		bb = BoundingBox(0,w,0,h)
		Cairo.save(ctx)
			drawrectangle(ctx, bb, mplot.layout.values.frame)
		Cairo.restore(ctx)
		render(ctx, mplot.title, Point2D(w/2, yoffset/2),
			mplot.layout.values.font_title, align=ALIGN_HCENTER|ALIGN_VCENTER
		)

		for (i, plot) in enumerate(mplot.subplots)
			bb = plot.plotbb
			if nothing == bb
				#Use auto-computed grid layout:
				row = div(i-1, ncols) + 1
				col = i - (row-1)*ncols
				xmin = (col-1)*wplot; ymin = yoffset+(row-1)*hplot
				bb = BoundingBox(xmin, xmin+wplot, ymin, ymin+hplot)
			end

			Cairo.save(ctx) #-----
			setclip(ctx, bb) #Avoid accidental overwrites.
			render(ctx, plot, bb)
			Cairo.restore(ctx) #-----
		end
	end
end

#_show() Plot: Leverage write to Multiplot
function _show(stream::IO, mime::MIME, plot::Plot, w::Float64, h::Float64)
	mplot = Multiplot()
	mplot.valloc_title = 0
	push!(mplot.subplots, plot)
	_show(stream, mime, mplot, w, h)
end

#_show() Plot2D: Auto-coumpute w/h
function _show(stream::IO, mime::MIME, plot::Plot2D)
	bb = plotbounds(plot.layout.values, grid1(plot))
	_show(stream, mime, plot, bb.xmax, bb.ymax)
end

#Default show/MIME behaviour: MethodError
Base.show(io::IO, mime::MIME, mplot::Multiplot) =
	throw(MethodError(show, (io, mime, mplot)))
Base.show(io::IO, mime::MIME, plot::Plot) =
	throw(MethodError(show, (io, mime, plot)))

#Maintain text/plain MIME support (Is this ok?).
Base.show(io::IO, ::MIME"text/plain", plot::Plot) = Base.show(io, plot)
Base.show(io::IO, ::MIME"text/plain", mplot::Multiplot) = Base.show(io, mplot)

#show() Plot/Multiplot: Supported MIMEs:
Base.show(io::IO, mime::MIMEall, mplot::Multiplot) =
	_show(io, mime, mplot, size_auto(mplot)...)
Base.show(io::IO, mime::MIMEall, plot::Plot) =
	_show(io, mime, plot)


#=="showable" interface
===============================================================================#
Base.showable(mime::MIME"text/plain", mplot::Multiplot) = true
Base.showable(mime::MIME, mplot::Multiplot) = false #Default
Base.showable(mime::MIMEall, mplot::Multiplot) = true #Supported
Base.showable(mime::MIMEsvg, mplot::Multiplot) = defaults.rendersvg #depends

Base.showable(mime::MIME"text/plain", p::Plot) = true
Base.showable(mime::MIME, p::Plot) = Base.showable(mime::MIME, Multiplot())


#=="write" interface
===============================================================================#

#_write() Multiplot:
function _write(path::String, mime::MIME, mplot::Multiplot, w::Float64, h::Float64)
	io = open(path, "w")
	_show(io, mime, mplot, w, h)
	close(io)
end

#_write() Plot: Leverage write to Multiplot
function _write(path::String, mime::MIME, plot::Plot, w::Float64, h::Float64)
	mplot = Multiplot()
	mplot.layout[:valloc_title] = 0
	push!(mplot.subplots, plot)
	_write(path, mime, mplot, w, h)
end

#_write() Multiplot: Auto-coumpute w/h
_write(path::String, mime::MIME, mplot::Multiplot) =
	_write(path, mime, mplot, size_auto(mplot)...)

#_write() Plot2D: Auto-coumpute w/h
function _write(path::String, mime::MIME, plot::Plot2D)
	bb = plotbounds(plot.layout.values, grid1(plot))
	_write(path, mime, plot, bb.xmax, bb.ymax)
end


#==Non-MIME write interface (convenience functions)
===============================================================================#

write_png(path::String, mplot::Multiplot) = _write(path, MIMEpng(), mplot)
write_svg(path::String, mplot::Multiplot) = _write(path, MIMEsvg(), mplot)
write_eps(path::String, mplot::Multiplot) = _write(path, MIMEeps(), mplot)
write_pdf(path::String, mplot::Multiplot) = _write(path, MIMEpdf(), mplot)

write_png(path::String, plot::Plot) = _write(path, MIMEpng(), plot)
write_svg(path::String, plot::Plot) = _write(path, MIMEsvg(), plot)
write_eps(path::String, plot::Plot) = _write(path, MIMEeps(), plot)
write_pdf(path::String, plot::Plot) = _write(path, MIMEpdf(), plot)

#Last line
