using TableWidgets, Interact, StatsPlots, JuliaDB, Blink

function mypipeline(t)
    (t isa Observables.AbstractObservable) || (t = Observable{Any}(t))

    filter = addfilter(t)
    editor = dataeditor(map(DataFrame, filter))
    plotter = dataviewer(editor)

    components = OrderedDict{Symbol, Any}(
        :filter => filter,
        :editor => editor,
        :plotter => plotter
    )
    wdg = Widget(
        components,
        layout = x -> tabulator(components)
    )
end

function mypipeline()
    wdg = filepicker()
    widget(mypipeline∘loadtable, wdg, init = wdg) # initialize the widget as a filepicker, when the filepicker gets used, replace with the output of `mypipeline` called with the loaded table
end

##

w = Window(async = false)
body!(w, mypipeline())
