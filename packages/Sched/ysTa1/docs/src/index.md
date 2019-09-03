# Sched.jl

A [Julia](https://julialang.org/) event scheduler inspired by [Python sched](https://docs.python.org/3/library/sched.html).

```@meta
CurrentModule = Sched
```

```@docs
Sched
```

## Install

`Sched` is a registered package.
To add it to your Julia packages, simply do the following in REPL:

```julia
Pkg.add("Sched")
```

## Usage

````@eval
Markdown.parse("""
```julia
$(readstring("sample/sample.jl"))
```
""")
````
[Download example](sample/sample.jl)

## Contents

```@contents
Pages = [
    "index.md",
]
```

## Syntax

```@docs
Scheduler
```

```@docs
enterabs
```

```@docs
enter
```

```@docs
cancel
```

```@docs
isempty
```

```@docs
Sched.run
```

```@docs
queue
```

## Package Internals
```@docs
Event
```

```@docs
Priority
```

```@docs
TimeFunc
```

```@docs
UTCDateTimeFuncStruct
```

```@docs
FloatTimeFuncStruct
```

## See also
 - [ExtensibleScheduler.jl](https://scls19fr.github.io/ExtensibleScheduler.jl/latest/) a more advanced and extensible [Julia](http://www.julialang.org) events scheduler
 - [https://discourse.julialang.org/t/julia-cron-like-event-scheduler/6899](https://discourse.julialang.org/t/julia-cron-like-event-scheduler/6899)
