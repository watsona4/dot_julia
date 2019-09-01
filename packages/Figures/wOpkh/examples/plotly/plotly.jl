function example_plotly(route="",client_id="")
    n = 10
    data = [Scatter(;x=1:n,y=rand(n))]
    layout = Layout(;
        title = Title(text="Create a new <div> and plot a single trace"),
        width = 650,
        height = 450
    )
    config = Config(displayModeBar=false)
    if isempty(route) && isempty(client_id)
        Plotly.newPlot("Plot1",data,layout=layout,config=config)
    else
        Plotly.newPlot(route,client_id,"Plot1",data,layout=layout,config=config)
    end

    trace1 = Scatter(x = 1:n, y = rand(n))
    trace2 = Scatter(x = 1:n, y = rand(n))
    data = [trace1, trace2]
    layout = Layout(
        title = Title(text="Create a new <div> and plot an array of traces"),
        width = 650,
        height = 450
    )
    config = Config(displayModeBar=false)
    if isempty(route) && isempty(client_id)
        Plotly.newPlot("Plot2",data,layout=layout,config=config)
    else
        Plotly.newPlot(route,client_id,"Plot2",data,layout=layout,config=config)
    end

    trace1 = Scatter(
        x = [1, 2, 3, 4],
        y = [10, 15, 13, 17],
        mode = "markers")

    trace2 = Scatter(
        x = [2, 3, 4, 5],
        y = [16, 5, 11, 10],
        mode = "lines")

    trace3 = Scatter(
        x = [1, 2, 3, 4],
        y = [12, 9, 15, 12],
        mode = "lines+markers")

    data = [trace1, trace2, trace3]

    layout = Layout(
        title = Title(text="Line and Scatter Plot"),
        width = 650,
        height = 450)

    config = Config(displayModeBar=false)
    if isempty(route) && isempty(client_id)
        Plotly.newPlot("Plot3",data,layout=layout,config=config)
    else
        Plotly.newPlot(route,client_id,"Plot3",data,layout=layout,config=config)
    end

    country = ["Switzerland (2011)", "Chile (2013)", "Japan (2014)",
            "United States (2012)", "Slovenia (2014)", "Canada (2011)",
            "Poland (2010)", "Estonia (2015)", "Luxembourg (2013)",
            "Portugal (2011)"]

    votingPop = [40, 45.7, 52, 53.6, 54.1, 54.2, 54.5, 54.7, 55.1, 56.6]
    regVoters = [49.1, 42, 52.7, 84.3, 51.7, 61.1, 55.3, 64.2, 91.1, 58.9]

    trace1 = Scatter(
        x=votingPop,
        y=country,
        mode="markers",
        name="Percent of estimated voting age population",
        marker=Marker(
            color="rgba(156, 165, 196, 0.95)",
            line = Line(
                color="rgba(156, 165, 196, 1.0)",
                width=1),
            size=16,
            symbol="circle"))

    trace2 = Scatter(
        x=regVoters,
        y=country,
        mode="markers",
        name="Percent of estimated registered voters")

    trace2.attributes.marker = Marker(
        color = "rgba(204, 204, 204, 0.95)",
        line = Line(
            color = "rgba(217, 217, 217, 1.0)",
            width = 1),
        symbol = "circle",
        size = 16)

    data = [trace1, trace2]

    layout = Layout(
        paper_bgcolor = "rgb(254, 247, 234)",
        plot_bgcolor = "rgb(254, 247, 234)",
        title = Title(text="Votes cast for ten lowest voting age population in OECD countries"),
        width = 600,
        height = 600,
        hovermode = "closest",
        margin = Margin(l = 140, r = 40, b = 50, t = 80),
        xaxis = Axis(
            showgrid = false,
            showline = true,
            linecolor = "rgb(102, 102, 102)",
            title = Title(
                font = Font(
                    color = "rgb(204, 204, 204)"))))
            # tick font_font_color = "rgb(102, 102, 102)",
            # autotick = false,
            # dtick = 10,
            # ticks="outside",
            # tickcolor="rgb(102, 102, 102)",
            # legend=Legend(
            #     font_size=10,
            #     yanchor="middle",
            #     xanchor="right"),
            #             )

    config = Config(displayModeBar=false,scrollZoom=false,doubleClick="reset")
    if isempty(route) && isempty(client_id)
        Plotly.newPlot("Plot4",data,layout=layout,config=config)
    else
        Plotly.newPlot(route,client_id,"Plot4",data,layout=layout,config=config)
    end
    return
end

# example_plotly()
