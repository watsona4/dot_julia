module ForTheBadge

    using Colors
    using Luxor
    using Luxor: julia_blue, julia_purple, julia_green, julia_red
    
    """
        badge(
            labels; # must be the same length as kwargs, so if you
            fonts = ("Roboto Medium", "Montserrat ExtraBold")
            bgcolours = (colorant"#a7bfc1", colorant"#5593c8"),
            textcolours = (colorant"white", colorant"white"),
            padding = 13,
            h = 50,
            ext = :pdf,
            filename = join(labels, "_") * ".\$ext",
            textsize = 20,
            texttype = :path,
            showbadge = true
        )

        badge(labels...; kwargs...)


    Provided labels, font sizes and colours of the appropriate type,
    this function will create a badge in the style of (ForTheBadge)[https://forthebadge.com/].

    Input must be in the form of tuples.

    ## Keyword arguments

        * `texttype` may be `:path` or `:text`.
        * `ext` may be `:pdf`, `:png`, or `:svg`.
        * `showbadge` controls whether the badge is opened
          by the system viewer after it is drawn.

    ## Examples:

    ```julia
    # To generate the logo:
    badge(
        "FOR", "THE", "BADGE", ".jl";
        filename = "logo.svg",
        textcolours = (colorant"white", colorant"white", colorant"white", colorant"white"),
        bgcolours = (julia_green, julia_purple, julia_red, julia_blue),
        fonts = ("Roboto Medium", "Roboto Medium", "Montserrat ExtraBold", "Roboto Medium")
    )
    ```
    """
    function badge(
            labels;
            fonts = ("$(@__DIR__)../assets/fonts/Roboto-Medium.ttf", "$(@__DIR__)../assets/fonts/Montserrat-ExtraBold.otf"),
            bgcolours = (colorant"#a7bfc1", colorant"#5593c8"),
            textcolours = (colorant"white", colorant"white"),
            padding = 13,
            h = 50,
            ext = :pdf,
            filename = join(labels, "_") * ".$ext",
            textsize = 20,
            texttype = :path,
            showbadge = true
        ) where N where T

        @assert length(labels) == length(fonts) == length(bgcolours) == length(textcolours)

        Drawing(800, h, :png) # initialize a dummy, in-memory drawing to get text extents

        fontsize(textsize) # set the font size

        rawextents = [begin fontface(fonts[i]); ceil(textextents(labels[i])[3]) + padding * 2 end for i in eachindex(labels)]
        finish()
        pushfirst!(rawextents, 0.0)

        extents = [sum(rawextents[1:i]) for i in eachindex(rawextents)]

        xlength = sum(rawextents)

        midpoints = ((rawextents[i]) / 2 + ((i == zero(typeof(i))) ? 0 : sum(rawextents[1:i-1])) for i in eachindex(extents)) |> collect

        Drawing(xlength, h, filename)

        for (k, p) in enumerate(midpoints[2:end])
            sethue(bgcolours[k])
            box(Point(extents[k], 0), Point(extents[k+1], 50), :fill)
            sethue(textcolours[k])
            fontface(fonts[k])
            fontsize(textsize)
            textoutlines(labels[k], Point(p, 25), halign=:center, valign=:middle)
            fillpreserve()
        end

        finish()

        showbadge && preview()

        filename
    end

    badge(labels...; kwargs...) = badge(Tuple(labels); kwargs...)

    export badge

    export julia_blue, julia_purple, julia_green, julia_red

end
