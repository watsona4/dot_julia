# :art: Galleries (Sample Output) :art:

[:chart_with_upwards_trend: Sample plots](https://github.com/ma-laforge/FileRepo/tree/master/InspectDR/sampleplots/README.md) (might be out of date).

**Generated With Other Modules:**

- [:chart_with_upwards_trend: CData.jl output](https://github.com/ma-laforge/FileRepo/tree/master/SignalProcessing/sampleplots/README.md).
- [:chart_with_upwards_trend: JuliaPlots/Plots.jl output](https://github.com/ma-laforge/FileRepo/blob/master/InspectDR/sampleplots_Plots/README.md).

# InspectDR.jl: Fast, Interactive Plots

[![Build Status](https://travis-ci.org/ma-laforge/InspectDR.jl.svg?branch=master)](https://travis-ci.org/ma-laforge/InspectDR.jl)

| <img src="https://github.com/ma-laforge/FileRepo/blob/master/InspectDR/sampleplots/demo11.png" width="425"> | <img src="https://github.com/ma-laforge/FileRepo/blob/master/InspectDR/sampleplots/demo2.png" width="425"> |
| :---: | :---: |

| <img src="https://github.com/ma-laforge/FileRepo/blob/master/SignalProcessing/sampleplots/demo15.png" width="850"> |
| :---: |

## Description

InspectDR is a fast plotting tool with a responsive GUI, targeting quick navigation of simulation results.  In design applications, InspectDR allows for efficient, interactive data exploration, thus shortening each iteration of the design cycle.

**Motivation:** Despite their great quality, most of Julia's current plotting options were found to be either too slow, and/or provide inadequate interactivity for the author's needs.

The InspectDR library is implemented using **3 distinct plot layers**:

- **Plot image layer:** Implemented with the [Cairo library](https://cairographics.org/), the plot image layer allows the user to render (multi-) plots as simple images.
- **Plot widget layer:** Library users can also integrate plots to their own [GTK+](https://www.gtk.org/) application by instantiating a single InspectDR widget.
- **Plot application layer:** Most end users will likely display/interact with plots/data using the built-in Julia/[GTK+](https://www.gtk.org/) multi-plot application.

Users are encouraged to open an issue if it is unclear how to utilize a particular layer.  Documentation is a bit limited at the moment.

### Features/Highlights

The following highlights a few interesting features of InspectDR:

- Publication-quality output.
- Included as a "backend" of [JuliaPlots/Plots.jl](https://github.com/JuliaPlots/Plots.jl).
- Relatively short load times / time to first plot.
- Designed with larger datasets in mind:
  - Responsive even with moderate (>200k points) datasets.
  - Confirmed to handle 2GB datsets with reasonable speed on older desktop running Windows 7 (drag+pan of data area highly discouraged).
- Support for Smith charts (admittance & impedance - see [Plot Templates](#Templates_Scales)).
- Support for various types of annotation:
  - User-programmable text, polyline, vertical & horizontal bars.
  - Drag & drop &Delta;-markers (Measures/displays &Delta;x, &Delta;y & slope).
- Interactive [mouse/keybindings](#Bindings).
  - Fast & simple way to pan/zoom into data.
  - In line with other similar tools.
  - Create drag & drop &Delta;-markers.
- [Layout & Stylesheets](#Layout_Stylesheets).
  - See [demo targeting IEEE publications @300 dpi](sample/demo12.jl)
  - Add custom stylesheets.

See following subsections for more information.

#### Responsive

Quick to first plot, and easy to navigate data using supported [mouse/keybindings](#Bindings)

<a name="F1Accel"></a>
#### "F1" Acceleration

InspectDR.jl includes specialized algorithms to accellerate plotting of large "F1" datasets (functions of 1 argument) in order to maintain a good "real-time" (interactive) user experience.

A dataset is defined as a function of 1 argument ("F1") if it satisfies:

	y = f(x), where x: sorted, real vector

Examples of "F1" datasets include **time domain** (`y(x=time)`) and **frequncy domain** (`X(w)`) data.

"F1" acceleration is obtained by dropping points in order to speed up the rendering process.

***IMPORTANT:*** "F1" acceleration tends to generate erroneous-looking plots whenever glyphs are displayed.  This is because the dropped points may become very noticeable.  Consequently, InspectDR will, by default, only apply "F1" acceleration on datasets drawn without glyphs (lines only).

To change when InspectDR applies "F1" acceleration to drop points, look for the `:droppoints` entry in the [Configuration/Defaults](#Config_Defaults) section.

#### 2D Plot Support

InspectDR.jl also supports generic 2D plotting.  More specifically, the tool is capable of plotting arbitrary 2D datasets that satisfy:

	(x,y) = (u[i], v[i]), for i in [1...N]

Examples of of such plots (where x-values are not guaranteed to be sorted) include:

- Nyquist plots
- Lissajous plots
- Smith/polar (S-Parameter) charts

<a name="Bindings"></a>
#### Mouse/Keybindings

InspectDR.jl supports keybindings to improve/accelerate user control.  The following tables lists supported bindings:

| Pan/Zoom Function | Mouse/Key |
| ----------------: | :-------: |
| Zoom out to full extents | `CTRL` + `f` |
| Zoom out horizontally to full extents | `CTRL` + `h` |
| Zoom out vertically to full extents | `CTRL` + `v` |
| Box zoom (in) | `right-click` + `mousemove`|
| Zoom in / zoom out | `+` / `-` |
| Zoom in / zoom out | `CTRL` + `mousewheel`|
| Pan up / pan down | &uArr; / &dArr; |
| Pan up / pan down | `mousewheel` |
| Pan left / pan right | &lArr; / &rArr; |
| Pan left / pan right | `SHIFT` + `mousewheel`|
| Pan anywhere | (`SHIFT` + `left-click`) + `mousemove` |

| Annotate Function | Mouse/Key |
| ----------------: | :-------: |
| Add reference marker | `r` |
| Add &Delta;-marker (rel. to last reference) | `d` |
| Add &Delta;-marker & set as reference | `D` |
| Move marker | `left-click` + `mousemove` control point|
| Delete marker | `DEL` (when moving marker) |
| Move &Delta;-marker info box | `left-click` + `mousemove` box |
| Re-center &Delta;-marker info box | `0` (when moving box) |

#### Mouse Pan/Zoom Locks
There are also keybindings to lock directionnality during mouse pan / zoom operations:

| Function | Key |
| -------: | :---: |
| Lock along horizontal | `h` |
| Lock along vertical | `v`|
| Allow both directions | `b` |

## Select Documentation

Note that many types & functions are not exported from InspectDR in order to avoid namespace pollution.  That being said, the module name will often be omitted below in an attempt to improve readability.

### Plot Objects

Principal objects:

- **`InspectDR.Plot`**: An abstract plot object.
- **`InspectDR.Plot2D <: Plot`**:  A 2D plot object.  Construct empty 2D plot using `InspectDR.Plot2D(title="Plot Title")`.
- **`InspectDR.Multiplot`**:  A multi-plot object.  Construct empty multi-plot using: `InspectDR.Multiplot(title="Multiplot Title")`.

Subplots (`T<:Plot`) are added to a multi-plot object using the `add()` method:
```
mplot = InspectDR.Multiplot()
plot1 = InspectDR.Plot2D()
plot2 = InspectDR.Plot2D()

add(mplot, plot1)
add(mplot, plot2)
```

Similarly, the `add()` method adds waveforms to plots/subplots:
```
wfrm = add(plot1, x, y, id="Waveform label")
```

**WARNING:** Only `Vector` data can be added (`AbstractVector`/`Range` not currently supported).

#### Displaying Plots

InspectDR provides the `GtkDisplay` object derived from `Base.Multimedia.Display`.  `GtkDisplay` is used in combination with `Base.display()`, to spawn a new instance of a GTK-based GUI.

To display a single `plot::Plot` object, one simply calls:
```
gplot = display(InspectDR.GtkDisplay(), plot)
```

Similarly, to display `mplot::Multiplot` object, one calls:
```
gplot = display(InspectDR.GtkDisplay(), mplot)
```

To programmatically close a Gtk plot window, the `close()` function can be used:
```
close(gplot)
```

<a name="Templates_Scales"></a>
### Plot Templates/Axis Scales

In order to support stacked graphs with independent y-axes (tied to the same x-axis), specifying axis scales is a bit involved:

- `InspectDR.Plot2D.xscale` controls the x-axis scale.
- `InspectDR.Plot2D.strips[STRIP_INDEX].yscale` controls the y-axis scale.

To streamline control over plot axes/grids/labels/..., it is highly recommended to use the following **plot templates**:

1. `Plot2D(xscale, yscalelist; kwargs...)`: Generic 2D plot template.

    - `Plot2D(:lin, :log, title="title", xlabel="X", ylabels=["log(Y)"])`: Construct plot with a linear X-axis & log10 Y-axis.
    - `Plot2D(:log10, [:dB20, :lin, :lin], title="title", xlabel="X", ylabels=["Y1 (dB)", "Y2", "Y3"])`: Construct plot with a log10 X-axis, and 2 Y-strips: the top-most with a dB20 Y-scale, and the next two with linear Y-scale.

2. `bodeplot(; kwargs...)`: Template for generating Bode plots.
    - `bodeplot()`: Default `kwargs` already set: `xlabel="Frequency (Hz)"`, ylabels=["Magnitude (dB)", "Phase (°)]"`.

3. `transientplot(yscalelist; kwargs...)`: Template for plotting transient data.
    - `transientplot([:lin, :lin, :lin], title="title", ylabels=["Voltage", "Voltage", "Current"])`: `xlabel` already set to `"Time (s)"`, by default.

4. `smithchart(TYPE; ref, kwargs...)`: Template for plotting onto a Smith Chart.
    - `smithchart(:Z, ref=50)`: Impedance (`Z`) Smith Chart with a 50&Omega; reference. Default `kwargs` already set: `xlabel="Real(Γ)"`, `ylabels=["Imaginary(Γ)"]"`.
    - `smithchart(:Y, ref=75)`: Admittance (`Y`) Smith Chart with a 75&Omega; reference.

NOTE: X/Y-axis scales are specified using one of the following `::Symbols`:

- `:lin`
- `:log10`, `:log` (= `:log10`)
- `:ln`, `:log2`: Grid lines might need improvement here.
- `:dB20`, `:dB10`

<a name="Layout_Stylesheets"></a>
### Layout & Stylesheets

The appearance of InspectDR plots is configured through the `.layout` properties of `::Plot2D` & `::Multiplot` objects.  Until better documentation is available, one is encouraged to look at the fields of the `PlotLayout` & `MultiplotLayout` for more information:
```
#To control apperance of Plot2D elements:
?InspectDR.PlotLayout

#To control apperance of Multiplot elements:
?InspectDR.MultiplotLayout
```

The `.layout` properties should be accessed using the `[]` operators, using the field names names of `PlotLayout` / `MultiplotLayout` as arguments:

```
plot.layout[:valloc_top] = 20 #Modify space above data area
```

#### Pre-defined Stylesheets

InspectDR uses "Stylesheets" to control the default values of plot elements.  To apply a different stylesheet to a given plot, use the `setstyle!` methods:

```
InspectDR.setstyle!(::Plot2D, stylesheet::Symbol; kwargs...)
InspectDR.setstyle!(::Multiplot, stylesheet::Symbol; kwargs...)
```

Currently supported values for `stylesheet` include:
- `:screen`
- `:IEEE`

Custom stylesheets are added by extending `InspectDR.getstyle()`, as done in [stylesheets.jl](src/stylesheets.jl) (Search for: `StyleID{:screen}` & `StyleID{:IEEE}`).

#### Legends

At this point in time, legends have limited configurability.  When displayed, legends will consume fixed horizontal real-estate.  The idea is to display a large number of labels without hiding the data area.

In order to display the legend of a `plot::Plot2D` object, one would set:
```
plot.layout[:enable_legend] = true #Enables legend
plot.layout[:halloc_legend] = 150 #Control size of legend
```

<a name="Config_Defaults"></a>
### Configuration/Defaults

Default InspectDR.jl settings can be overwritten once the module is loaded by editing the `InspectDR.defaults` structure:

```
#Dissalow SVG MIME output for performance reasons:
InspectDR.defaults.rendersvg = false

#Change when plots drop points to enable "F1"-acceleration:
#(One of: {:always, :never, :noglyph, :hasline})
InspectDR.defaults.pointdropmatrix = InspectDR.PDM_DEFAULTS[:always]

#Enable time stamp & legend:
InspectDR.defaults.plotlayout[:enable_timestamp] = true
InspectDR.defaults.plotlayout[:enable_legend] = true

#Set data-area dimensions (saving single plot):
InspectDR.defaults.plotlayout[:halloc_data] = 500
InspectDR.defaults.plotlayout[:valloc_data] = 350

#Set plot dimensions (saving multi-plot):
InspectDR.defaults.mplotlayout[:halloc_plot] = 500
InspectDR.defaults.mplotlayout[:valloc_plot] = 350

#Configure # of columns in multi-plot outputs:
InspectDR.defaults.mplotlayout[:ncolumns] = 2
```

Until better documentation is available, one is encouraged to look at the fields of the `PlotLayout` for more information:
```
?InspectDR.PlotLayout
```

Defaults can also be specified *before* importing InspectDR.jl with the help of `Main.DEFAULTS_INSPECTDR::Dict`.  Simply create the variable in your `~/.juliarc.jl` file, using the following pattern:
```
DEFAULTS_INSPECTDR = Dict(
	:rendersvg => false,

	#Special options available @ initialization:
	:droppoints => :always, #One of: {:always, :never, :noglyph, :hasline}
	:notation_x => :SI,   #Change x-axis notation
	:notation_y => :SI,   #Change y-axis notation
	:fontname => "Sans",  #Change default font family
	:fontscale => 1.2,    #Scale up/down font default sizes

	#Basic plot options:
	:enable_timestamp => true,
	:enable_legend => true,
	:halloc_legend => 150,

	#Supported multiplot options:
	:ncolumns => 2,
	:halloc_plot => 500,
	:valloc_plot => 350,
)
```

<a name="SampleUsage"></a>
## Sample Usage

 - Sample code to construct InspectDR objects can be found [here](sample/).
 - Sample IJulia (Jupyter) notebooks can be found [here](notebook/).
 - Sample [Blink](https://github.com/JunoLab/Blink.jl) ([Electron](https://github.com/electron/electron) backend) projects can be found [here](Blink/).

<a name="KnownLimitations"></a>
## Known Limitations

- Stability of [IJulia (Jupyter) notebooks](notebook/) is not very good at the moment.  Also: many examples are not yet ported to Julia 1.0.
- Documentation is a bit limited at the moment.  See [Sample Usage](#SampleUsage) to learn from examples.
- API is still a bit rough.  User often has to manipulate data structures directly.
  - Workaround: Use [JuliaPlots/Plots.jl](https://github.com/JuliaPlots/Plots.jl) as a "frontend" (increases plot times).
- Font control is not ideal.  The default font might not be available on all platforms - and the fallback font might not have Unicode characters to display exponent values (ex: `10⁻¹⁵`).  Some Greek characters might also be missing.
  - Workaround: Overwrite default font, as described in [Configuration/Defaults](#Config_Defaults).
- Legends not very configurable (currently optimized to display many labels @ cost of horizontal real-estate).
- Does not yet render plot data in separate thread (will improve interactive experience with large datasets).
- Mouse events currently function even outside data area (a bit odd).
- Significant slowdowns observed when zooming **deep** into non-F1 data... Can likely be solved by discarding data outside plot extents.
  - Workaround: make sure x-values are sorted (F1-acceleration discards data & is less prone to slowdowns).
- By default, "F1"-acceleration is only applied to datasets drawn without glyphs (lines only).
  - Look for the `:droppoints` entry in the [Configuration/Defaults](#Config_Defaults) section to change this behaviour.

### Compatibility

Extensive compatibility testing of InspectDR.jl has not been performed.  The module has been tested using the following environment(s):

- Windows / Linux / Julia-1.1.1 / Gtk 0.17.0 (GTK+ 3) / Cairo 0.6.0

## Disclaimer

The InspectDR.jl module is not yet mature.  Expect significant changes.
