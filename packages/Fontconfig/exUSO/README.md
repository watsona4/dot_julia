# Fontconfig

[![Build Status](https://travis-ci.org/JuliaGraphics/Fontconfig.jl.svg?branch=master)](https://travis-ci.org/JuliaGraphics/Fontconfig.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/iqmn3ungu9jfw4dj/branch/master?svg=true)](https://ci.appveyor.com/project/JuliaGraphics/fontconfig-jl/branch/master)


Fontconfig.jl provides basic binding to [fontconfig](http://www.freedesktop.org/wiki/Software/fontconfig/).


# Pattern

`Pattern` corresponds to the fontconfig type `FcPattern`. It respresents a set
of font properties used to match specific fonts.

It can be constructed in two ways. First with zero or more keyword arguments
corresponding to fontconfig font properties.

```julia
Fontconfig.Pattern(; args...)
```

For example
```julia
Fontconfig.Pattern(family="Helvetica", size=10, hinting=true)
```

Secondly, it can be constructed with a fontconfig specifications string
```julia
Fontconfig.Pattern(name::String)
```

For example
```julia
Fontconfig.Pattern("Helvetica-10")
```

# Match

The primary functionality fontconfig provides is matching font patterns. In
Fontconfig.jl this is done with the `match` function, corresponding to `FcMatch`
in fontconfig.
```julia
match(pat::Pattern)
```

It takes a `Pattern` and return a `Pattern` corresponding to the nearest
matching installed font.


# Format

Extracting property values from a `Pattern` can be done with the `format`
function, which wraps `FcPatternFormat`.

```julia
format(pat::Pattern, fmt::String="%{=fclist}")
```

See `man FcPatternFormat` for the format string specification.


# List

Fontconfig also provides a function `list` to enumerate all installed
fonts. Optionally, a `Pattern` can be provided to list just matching fonts. The
function will return a vector of `Pattern`s

```julia
list(pat::Pattern=Pattern())
```
