# Kpax3.jl Release Notes

## Changes from v0.4.0 to v0.5.0

* Add dependency on `RecipesBase`
* Remove dependency on `GR`, `Plots`, and `StatPlots`

## Changes from v0.3.0 to v0.4.0

* Upgrade to Julia 1.0
* Switched plotting library from `Gadfly` to `Plots`

## Changes from v0.2.0 to v0.3.0

* Added function plotD for plotting the dataset with highlighted amino acids
* Modified function plotP for reducing its output and memory size
* Added axis labels to plotP
* Updated the tutorial with the new plotD function
* Created a convenient command line script for running Kpax3. You can find it on [GitHub Gist](https://gist.github.com/albertopessia/fd9df11fb2bdb158ad91936c4638d6fd)

## Changes from v0.1.0 to v0.2.0

* Upgrade to Julia 0.6
* It is now possible to load generic categorical data from _csv_ files with the `CategoricalData` function
