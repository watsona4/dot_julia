# Media

[![Build Status](https://travis-ci.org/JunoLab/Media.jl.svg?branch=master)](https://travis-ci.org/JunoLab/Media.jl)

Media.jl provides a display system which enables the user handle multiple input/output devices and decide what media types get displayed where. It's used by DevTools.jl and Juno.

Set media types:

```julia
using Media
media(Gadfly.Plot, Media.Graphical)
media(DataFrames.DataFrame, Media.Tabular)
```

Hook media and concrete types up to outputs:

```julia
setdisplay(Media.Graphical, BlinkDisplay._display)
```

which means "display graphical output on the BlinkDisplay device". You could also set tabular data (e.g. Matrices and DataFrames) to display with Blink.jl:

```julia
setdisplay(Media.Tabular, BlinkDisplay._display)
rand(5, 5) #> Displays in pop up window
```

or set the display for specific types (abstract or concrete):

```julia
setdisplay(FloatingPoint, BlinkDisplay._display)
2.3 #> Displays with Blink
```

In principle you can also set displays for a given input device, although this needs more support from Base to work well.

Use

```julia
unsetdisplay(Media.Tabular)
```

to undo the change.
