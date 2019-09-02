# InspectDR sample usage from [Blink](https://github.com/JunoLab/Blink.jl) ([Electron](https://github.com/electron/electron) backend)

Samples in this directory require the user to first install Interact, Blink & NumericIO:

```
julia> ]
(v1.0) pkg> add Interact
(v1.0) pkg> add Blink
(v1.0) pkg> add NumericIO
(v1.0) pkg> add Colors
(v1.0) pkg> add DSP
(v1.0) pkg> add FFTW
```

***NOTE:*** DSP & FFTW packages are only required for `5_dspfilters.jl`.

:warning: AtomShell must first be installed.  See installation instructions on the [Blink](https://github.com/JunoLab/Blink.jl) GitHub page.
