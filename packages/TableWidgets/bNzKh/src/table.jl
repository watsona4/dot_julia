function format(x)
    io = IOBuffer()
    show(IOContext(io, :compact => true, :typeinfo => typeof(x)), x)
    String(take!(io))
end

function row(r, i; format = TableWidgets.format)
	fields = propertynames(r)

    node("tr",
        node("th", format(i)),
        (node("td", format(getproperty(r, field))) for field in fields)...)
end

rendertable(t; kwargs...) = render_row_iterator(Tables.rows(t); kwargs...)
rendertable(t, r::Integer; kwargs...) = render_row_iterator(Iterators.take(Tables.rows(t), r); kwargs...)

function render_row_iterator(t;
    format = TableWidgets.format, className = "is-striped is-hoverable", row = TableWidgets.row)

    fr, lr = Iterators.peel(t)

    names = propertynames(fr)
    headers = node("tr", node("th", ""), (node("th", string(n)) for n in names)...) |> node("thead")

    first_row = row(fr, 1; format = format)
    body = node("tbody", first_row, (row(r, i+1; format = format) for (i, r) in enumerate(lr))...)
    className = "table interact-widget $className"
    n = slap_design!(node("table", headers, body, className = className))
end

"""
`head(t, r=6)`

Show first `r` rows of table `t` as HTML table.
"""
function head(t, r = 6; kwargs...)
    t isa AbstractObservable || (t = Observable{Any}(t))
    r isa AbstractObservable || (r = Observable{Int}(r))
    h = @map rendertable(&t, &r; kwargs...)

    Widget{:head}([:rows => r, :head => h], output = t, layout = i -> i[:head])
end

function toggled(wdg::AbstractWidget; readout = true, label = "Show")
    toggled_wdg = togglecontent(wdg, label = label, value = readout)
    Widget{:toggled}([:toggle => toggled_wdg], output = observe(wdg), layout = i -> i[:toggle])
end

"""
`dataeditor(t, rows; label = "Show table")`

Create a textbox to preprocess a table: displays the result using `toggled(head(t, rows))`.
"""
function dataeditor(t, args...; readout = true, label = "Show table", kwargs...)
    (t isa AbstractObservable) || (t = Observable{Any}(t))
    output = Observable{Any}(t[])
    wdg = Widget{:dataeditor}(output = output)
    wdg[:input] = t
    wdg[:display] = toggled(head(observe(wdg), args...; kwargs...); readout = readout, label = label)
    wdg[:text] = textarea(placeholder = "Write transformation to apply to the table")
    parsetext!(wdg; text = observe(wdg, :text), on = (observe(wdg, :text)), default = identity)
    wdg[:apply] = button("Apply")
    wdg[:reset] = button("Reset", className = "is-danger")
    @map! observe(wdg) begin
        &wdg[:apply]
        (wdg[:function][])(&t)
    end
    @on begin
        &wdg[:reset]
        wdg[:text][] = ""
        observe(wdg)[] = t[]
    end
    @layout! wdg Widgets.div(:text, hbox(:apply, hskip(1em), :reset), :display)
end
