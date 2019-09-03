# Pushover.jl Overview

```@docs
Pushover
```

## Install

```julia
Pkg.add("Pushover")
```

or

```julia
Pkg.clone("https://github.com/scls19fr/Pushover.jl")
```

## Usage

````@eval
using Markdown
Markdown.parse("""
```
$(read("../../sample/send_message.jl", String))
```
""")
````

[See examples](https://github.com/scls19fr/Pushover.jl/tree/master/sample)

## See also

- [BulkSMS.jl](https://github.com/scls19fr/BulkSMS.jl) - A Julia package to send SMS (Short Message Service) using BulkSMS API
