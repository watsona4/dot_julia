# BulkSMS Overview

```@docs
BulkSMS
```

## Install

```julia
Pkg.clone("https://github.com/scls19fr/BulkSMS.jl")
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

[See examples](https://github.com/scls19fr/BulkSMS.jl/tree/master/sample)

## API

### Public

```@docs
BulkSMSClient
send
BulkSMS.ActionWhenLong
```

### Private

```@docs
BulkSMS.BulkSMSClientException
BulkSMS.BulkSMSResponse
BulkSMS._crop
BulkSMS._send
```

## See also

- [Pushover.jl](https://github.com/scls19fr/PushOver.jl) - A Julia package to send notifications using the Pushover Notification Service
