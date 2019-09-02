# InteractBulma

[![Build Status](https://travis-ci.org/piever/InteractBulma.jl.svg?branch=master)](https://travis-ci.org/piever/InteractBulma.jl)
[![codecov.io](http://codecov.io/github/piever/InteractBulma.jl/coverage.svg?branch=master)](http://codecov.io/github/piever/InteractBulma.jl?branch=master)

Package to create Bulma themes to style Interact apps with [Bulma](https://bulma.io/) css.

To learn how to use Interact, check out the [Interact documentation](https://juliagizmos.github.io/Interact.jl/latest/).

## Theming instruction

InteractBulma provides a `compile_theme` function to create a theme (a CSS file) based on variables and overrides. Check out the Bulma [documentation](https://bulma.io/documentation/customize/) to learn what variables can be used and how.

The function `compile_theme(output)` has two optional keyword arguments (`variables` and `overrides`) with the path of the `scss` file you want to use to customize variables or to add overrides respectively. `output=mktempdir()` is the folder chosen to store the resulting css files (main.css and main_confined.css).

### Example usage

Here we will use variables from the [flatly](https://jenil.github.io/bulmaswatch/flatly/) theme:

```julia
using Interact
using InteractBulma: compile_theme, examplefolder
variables_file = joinpath(examplefolder, "flatly", "_variables.scss") # here you would use your own style
mytheme = compile_theme(variables = variables_file)
settheme!(mytheme)
button() # test the new looks of Interact widgets
```
