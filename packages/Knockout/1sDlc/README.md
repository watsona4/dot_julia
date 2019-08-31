# Knockout
[![Build Status](https://travis-ci.org/JuliaGizmos/Knockout.jl.svg?branch=master)](https://travis-ci.org/JuliaGizmos/Knockout.jl)  [![codecov](https://codecov.io/gh/JuliaGizmos/Knockout.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaGizmos/Knockout.jl)

A Julia wrapper for [Knockout.js](http://knockoutjs.com/). It uses [WebIO](https://github.com/JuliaGizmos/WebIO.jl) to load JavaScript and to do Julia to JS communication. [Go here](https://github.com/JuliaGizmos/WebIO.jl/blob/master/README.md) to get started with WebIO.

## Usage

The package exports a single `knockout` function:

### `knockout(template, data; options...)`


- `template` acts as the "structre" of the UI. It's normal HTML, but can use variables from `data`. See the [Knockout documentation](http://knockoutjs.com/documentation/introduction.html) for more details. You can compose the template (like any HTML) [using WebIO](https://github.com/JuliaGizmos/WebIO.jl#composing-content).
- `data` is an iterable of `propertyName => value` pairs (e.g. a `Dict`) which populates the template.

```julia
using Knockout, WebIO

template = node(:p, "{{message}}", attributes = Dict("data-bind" => "visible : visible"))
knockout(template, [:message=>"hello", :visible=>true])
```

If a property's value is an observable, this function syncs the property and the observable. Here's how you can update the properties bound to the template from Julia.

```julia
using Observables
ob = Observable("hello")
knockout(template, [:message=>ob, :visible=>true])
```
Now if at any time you run `ob[] = "hey there!"` on Julia, you should see the contents of the message update in the UI. Try making an observable for `:visible` property and set it to true or false, you should see the message toggle in and out of view!

To initiate JS to Julia communication you must set an event handler on `scope[propertyName]` (by calling `on(f, scope[propertyName])`)  _before_ rendering the scope.

Here's an example of JS to Julia communication:

```julia
incoming = Observable("")
on(println, incoming) # print to console on every update

template = node(:input, attributes = Dict("type"=>"text", "data-bind" => "value : message"))()
knockout(template, [:message=>incoming])
```

This will cause the value of the textbox to flow back to Julia, and should get printed to STDOUT since we have a listener to print it. The value only gets updated on `change` (meaning when the widget loses focus). To update it on `input` (meaning whenever the user interacts with the widget) use:

```julia
incoming = Observable("")
on(println, incoming) # print to console on every update

template = node(:input, attributes = Dict("type"=>"text", "data-bind" => "value : message, valueUpdate : 'input'"))()
knockout(template, [:message=>incoming])
```

You can specify that you want some knockout observable to be computed as a function of other observables,
e.g `knockout(...; computed = Dict(:fullName => @js function(){this.firstName() + ' ' + this.lastName()}))`.
You can pass functions that you want available in the Knockout scope as keyword arguments to
`knockout` E.g. `knockout(...; methods=Dict(:sayhello=>@js function(){ alert("hello!") }))` (Tip: use [JSExpr.jl](https://github.com/JuliaGizmos/JSExpr.jl) for the `@js` macro)

## Acknowledgments

This package is strongly inspired by [Vue.jl](https://github.com/JuliaGizmos/Vue.jl). It basically is a word by word translation of Vue.jl for Knockout.js. Knockout.js solves one major technical difficulty of Vue.js: the impossibility of nesting instances.
