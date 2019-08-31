# Installation

To install [VegaLite.jl](https://github.com/queryverse/VegaLite.jl), run the following command in the julia Pkg REPL-mode:

```julia
(v1.0) pkg> add VegaLite
```

## REPL frontends

If you create plots from the standard julia REPL, they will show up in a browser window when displayed.

As an alternative you can install [ElectronDisplay.jl](https://github.com/queryverse/ElectronDisplay.jl) with `Pkg.add("ElectronDisplay")`. Whenever you load that package with `using ElectronDisplay`, any plot you display will then show up in an [electron](https://electronjs.org/) based window instead of a browser window.

## Notebook frontends

[VegaLite.jl](https://github.com/queryverse/VegaLite.jl) works with [Jupyter Lab](https://github.com/jupyterlab/jupyterlab), [Jupyter Notebook](http://jupyter.org/) and [nteract](https://nteract.io/).

The first step to use any of these notebooks frontends is to install them. The second step is to install the general julia integration by running the following julia code:

```julia
Pkg.add("IJulia")
```

At that point you should be able to use [VegaLite.jl](https://github.com/queryverse/VegaLite.jl) in notebooks that have a julia kernel.

We recommend that you use either [Jupyter Lab](https://github.com/jupyterlab/jupyterlab) or [nteract](https://nteract.io/) for the best [VegaLite.jl](https://github.com/queryverse/VegaLite.jl) experience: you will get the full interactive experience of [Vega-Lite](https://github.com/vega/vega-lite) in those two frontends without any further installations. While you can display plots in the classic [Jupyter Notebook](http://jupyter.org/), you won't get interactive plots in that environment without further setup steps.

## VS Code and Juno/Atom

If you plot from within VS Code with the [julia extension](https://marketplace.visualstudio.com/items?itemName=julialang.language-julia) or [Juno/Atom](http://junolab.org/), plots will show up in a plot pane in those editors.

Neither of the plot panes currently support the interactive features of [VegaLite.jl](https://github.com/queryverse/VegaLite.jl). There are plans to add support for interactive charts for both editors.

## Example Datasets

Many of the examples in the documentation use data from the [Vega Datasets](https://github.com/vega/vega-datasets) repository. You can access these datasets easily with the julia package [VegaDatasets.jl](https://github.com/queryverse/VegaDatasets.jl). To install that package, run the following julia code:

```julia
Pkg.add("VegaDatasets")
```
