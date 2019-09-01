# :art: Galleries (Sample Output) :art:

[:chart_with_upwards_trend: Sample plots](https://github.com/ma-laforge/FileRepo/tree/master/GracePlot/sampleplots/README.md) (might be out of date).

**Generated With Other Modules:**

 - [:satellite: SignalProcessing.jl](https://github.com/ma-laforge/FileRepo/tree/master/SignalProcessing/sampleplots/grace_old/README.md) (Using EasyPlotGrace.jl; See [CData.jl](https://github.com/ma-laforge/CData.jl) for details.  Likely out of date.)

# GracePlot.jl

[![Build Status](https://travis-ci.org/ma-laforge/GracePlot.jl.svg?branch=master)](https://travis-ci.org/ma-laforge/GracePlot.jl)

## Description

The GracePlot.jl module is a simple control interface for Grace/xmgrace - providing more publication-quality plotting facilities to Julia.

 - GracePlot.jl is ideal for seeding a Grace session with plot data before fine-tuning the output with Grace itself.
 - Grace "templates" (.par) files can then be saved/re-loaded to maintain a uniform appearance in publication.
 - The user is encouraged to pre-process data using math facilities from Julia instead of those built-in to Grace.

## Samples

The [sample](sample/) directory contains a few demonstrations on how to use GracePlot.jl.

The [template](sample/template/) directory contains a repository of sample Grace template (parameter) files.

## Installation

The GracePlot.jl module requires the user to install the Grace plotting tool:<br>
<http://plasma-gate.weizmann.ac.il/Grace/>

More detailed instructions can be found [here](https://github.com/ma-laforge/HowTo/blob/master/grace/grace_install.md#Installation)

## Configuration

By default, GracePlot.jl assumes Grace is accessible from the environment path as `xmgrace`.  To specify a different command/path, simply set the `GRACEPLOT_COMMAND` environment variable.

The value of `GRACEPLOT_COMMAND` can therefore be set from `.juliarc.jl` with the following:

	ENV["GRACEPLOT_COMMAND"] = "/home/laforge/bin/xmgrace2"

## Select Documentation

### Axes

Objects describing axis types are created with the `paxes` function:
```
log_lin = paxes(xscale = :log, yscale = :lin)
```
**Supported scales:** `:lin`, `:log`, `:reciprocal`.

The `paxes` function also allows the user to specify axis ranges:
```
ax_rng = paxes(xmin = 0.1, xmax = 1000, ymin = 1000, ymax = 5000)
```

### Line Style

Objects describing line style are created with the `line` function:
```
default_line = line(style=:ldash, width=8, color=1)
```

**Supported styles:** `:none`, `:solid`, `:dot`, `:dash`, `:ldash`, `:dotdash`, `:dotldash`, `:dotdotdash`, `:dotdashdash`.

### Glyphs

Objects describing display glyphs (markers/symbols) are created with the `glyph` function:
```
glyph(shape=:diamond, color=5)
```

**Supported shapes:** `:circle`, `:o`, `:square`, `:diamond`, `:uarrow`, `:larrow`, `:darrow`, `:rarrow`, `:cross`, `:+`, `:diagcross`, `:x`, `:star`, `:*`, `:char` (see demo2 for use of `:char`).

## Known Limitations

GracePlot.jl currently provides a relatively "bare-bones" interface (despite offering significant functionality).

 - Does not currently provide much in terms of input validation.
 - Does not support the entire Grace control interface.
  - In particular: GracePlot.jl does not support Grace math operations.  Users are expected to leverage Julia for processing data before plotting.
 - On certain runs, Grace will complain that some commands cannot be executed... almost like commands are sent too fast for Grace, or something...  Not sure what this is.  Try re-running.

### SVG Issues

GracePlot.jl will post-process SVG files in an attempt to support the W3C 1999 standard.  The changes enable most new web browsers to display the SVG outputs.  Note, however, that text will not appear correctly on these plots.

The EPS format is therefore suggested if high-quality vector plots are desired.

### Crashes

The ARRANGE command appears to cause [crashes/logouts](CrashIssues.md) on certain Linux installs with relatively high occurance.

### Compatibility

Extensive compatibility testing of GracePlot.jl has not been performed.  The module has been tested using the following environment(s):

 - Linux / Julia-1.1.1 / Grace-5.1.25.

## Disclaimer

The GracePlot.jl API is not perfect.  Backward compatibility issues are to be expected as the module matures.
