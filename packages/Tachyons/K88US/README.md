```julia
using Tachyons

tach = class"f1 b pa5 bg-navy yellow br4 fl"

dom"div"(
    tachyons_css,               # loads the stylesheet
    tach(dom"div"("Tachyons")), # adds the classes to div
)
```
<img src="https://user-images.githubusercontent.com/25916/36969756-6de10308-208c-11e8-8d38-c0a2f8e4dc17.png" height="200">

A simple wrapper for [tachyons css](http://tachyons.io/) framework for good design with as little CSS as possible. For final control, use [CSSUtil](https://github.com/JuliaGizmos/CSSUtil.jl).

## Usage

This module exports 2 things:

1. `tachyons_css` -- a Scope object which loads the css file, place this somewhere in the DOM to load it.
2. `class""` -- a String macro which returns a function that adds the given classes to its input.

Here are the classes used in the example above:

- [`f1`](http://tachyons.io/docs/typography/scale/) -- the font size `f1` is the biggest and `f6` is the smallest in this scale.
- [`b`](http://tachyons.io/docs/typography/font-weight/) -- bold font
- [`pa5`](http://tachyons.io/docs/layout/spacing/) -- pad with 5
- [`bg-navy`](http://tachyons.io/docs/themes/skins/) -- background color
- [`yellow`](http://tachyons.io/docs/themes/skins/) -- foreground color
- [`br4`](http://tachyons.io/docs/themes/border-radius/) -- border radius
- [`fl`](http://tachyons.io/docs/layout/floats/) -- float

Check out the [Tachyons docs](http://tachyons.io/docs/) to find ones you're looking for.

| Build | Coverage |
|-------|----------|
| [![Build Status](https://travis-ci.org/JuliaGizmos/Tachyons.jl.svg?branch=master)](https://travis-ci.org/JuliaGizmos/Tachyons.jl) | [![codecov](https://codecov.io/gh/JuliaGizmos/Tachyons.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaGizmos/Tachyons.jl)
