#InspectDR: Trace control for plot widgets
#-------------------------------------------------------------------------------


#==Constants
===============================================================================#


#==Types
===============================================================================#
mutable struct TraceDialog
	wnd::Gtk.Window
	gplot::GtkPlot
	subplotidx::Int
	tracestore::_Gtk.ListStore
end


#==Helper functions
===============================================================================#
function refresh_title(dlg::TraceDialog)
	title = "InspectDR - $(dlg.gplot.src.title) (Traces)"
	set_gtk_property!(dlg.wnd, :title, title)
end


#==Callback functions
===============================================================================#
@guarded function cb_tracevisible_toggle(w::Ptr{Gtk.GObject}, pathstr, dlg::TraceDialog)
	treepath = gtk_tree_path_new_from_string(pathstr)
	idx = listindex(treepath)+1
	toggle_visibility(dlg, idx)
	nothing #Known value
end


#==Constructor-like functions
===============================================================================#
function TraceDialog(gplot::GtkPlot)
	tracestore = _Gtk.ListStore(Bool, String)
	treemodel = _Gtk.TreeModel(tracestore)
	tracelist = _Gtk.TreeView(treemodel)
		#Construct renderers:
		rTxt = _Gtk.CellRendererText()
		rTog = _Gtk.CellRendererToggle()
		c1 = _Gtk.TreeViewColumn("Visible", rTog, Dict("active" => 0), resizable=false)#, min_width=200)
		c2 = _Gtk.TreeViewColumn("Waveform", rTxt, Dict("text" => 1))
		push!(tracelist, c1, c2)

	vbox = _Gtk.Box(true, 0)
		push!(vbox, tracelist)
	wnd = Gtk.Window(vbox, "", 300, 150, true)
	Gtk.GAccessor.modal(wnd, true)
	Gtk.GAccessor.keep_above(wnd, true)

	tracedialog = TraceDialog(wnd, gplot, 1, tracestore)
	refresh(tracedialog)

	signal_connect(cb_tracevisible_toggle, rTog, "toggled", Nothing, (Ptr{Cchar},), false, tracedialog)
	return tracedialog
end


#==Main Functions
===============================================================================#
function refresh(dlg::TraceDialog)
	refresh_title(dlg)
	dlg.subplotidx = active_subplot(dlg.gplot)
	if dlg.subplotidx < 1
		empty!(dlg.tracestore)
		return
	end

	splot = dlg.gplot.subplots[dlg.subplotidx].src
	ntraces = length(splot.data)
	(nstore, ncols) = size(dlg.tracestore)

	nmin = min(ntraces, nstore)
	for i in 1:nmin #Overwrite existing data:
		d = splot.data[i]
		dlg.tracestore[i,1] = d.visible
		dlg.tracestore[i,2] = d.id
	end

	nmissing = max(0, ntraces-nstore)
	for i in nmin .+ (1:nmissing) #Add slots for new traces
		d = splot.data[i]
		push!(dlg.tracestore, (d.visible, d.id))
	end

	nextra = max(0, nstore-ntraces)
	for i in 1:nextra #Remove excess slots in store
		pop!(dlg.tracestore)
	end

	return
end

function toggle_visibility(dlg::TraceDialog, idx::Int)
	active = active_subplot(dlg.gplot)
	if idx > 0 && active > 0 && active == dlg.subplotidx
		#Don't toggle value unless active subplot matches dialog state...
		splot = dlg.gplot.subplots[dlg.subplotidx].src
		if idx <= length(splot.data)
			splot.data[idx].visible = !splot.data[idx].visible

			#Immediately update displayed waveforms:
			invalidate_datalist(splot)
		end
	end

	refresh(dlg)
	refresh(dlg.gplot)
#	refresh(dlg.gplot.subplots[dlg.subplotidx]) #Could just update subplot
	return
end


#==High-level functions
===============================================================================#
function tracedialog_show(gplot::GtkPlot)
	dlg = TraceDialog(gplot)
	Gtk.showall(dlg.wnd)
	return
end

#Last line
