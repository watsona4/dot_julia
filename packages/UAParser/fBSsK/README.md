# UAParser

[![Build Status](https://travis-ci.org/JuliaWeb/UAParser.jl.svg?branch=master)](https://travis-ci.org/JuliaWeb/UAParser.jl) </br>
[![Coverage Status](https://coveralls.io/repos/JuliaWeb/UAParser.jl/badge.svg)](https://coveralls.io/r/JuliaWeb/UAParser.jl)


UAParser is a Julia port of [ua-parser](https://github.com/ua-parser/uap-python), which itself is a multi-language port of [BrowserScope's](http://www.browserscope.org) [user agent string parser](http://code.google.com/p/ua-parser/). Per the [README file](https://github.com/ua-parser/uap-core/blob/master/README.md) of the main project:

> "The crux of the original parser--the data collected by [Steve Souders](http://stevesouders.com/) over the years--has been extracted into a separate [YAML file](https://github.com/tobie/ua-parser/blob/master/regexes.yaml) so as to be reusable _as is_ by implementations in other programming languages."

UAParser is a limited Julia implementation heavily influenced by the [Python code](https://github.com/ua-parser/uap-python) from the ua-parser library.

New regexes have were retrieved from [here](https://github.com/ua-parser/uap-core/blob/master/regexes.yaml) on 2018-12-19.

## UAParser API

The API for UAParser revolves around three functions: `parsedevice`, `parseos` and `parseuseragent`. Each function takes one argument, `user_agent_string::AbstractString` and returns a custom Julia type: `DeviceResult`, `OSResult`, or `UAResult`. The structure of each type is as follows:

```
  DeviceResult: family, brand, model

  UAResult: family, major, minor, patch

  OSResult: family, major, minor, patch, patch_minor
```

## Code examples

```julia
  using UAParser

  #Example user-agent string
  user_agent_string = "Mozilla/5.0 (iPhone; CPU iPhone OS 5_1 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9B179 Safari/7534.48.3"

  #Get device from user-agent string
  parsedevice(user_agent_string) #> DeviceResult("iPhone", "Apple", "iPhone")

  #Get browser information from user-agent string
  parseuseragent(user_agent_string) #> UAResult("Mobile Safari","5","1",missing)

  #Get os information
  parseos(user_agent_string) #> OSResult("iOS","5","1",missing,missing)

```

You can index into the results of these functions like any other Julia composite type.

```julia
  #Get just browser information, no version information
  x1 = parseuseragent(user_agent_string)
  x1.family #> "Mobile Safari"

  #Get the os, no version information
  x2 = parseos(user_agent_string)
  x2.family #> "iOS"
```

## A Note On Parser Accuracy

When this library was created, it became very obvious that it would be hard to replicate the Python parser code with 100% accuracy. The authors decided that a _reasonably accurate_ implementation was more useful than spending the time to achieve 100% accuracy.

The tests in this library test against the accuracy of the parser. As of v0.6 of this package, here are the accuracy statistics against the files provided by the main ua-core project:

```
parse_device: 15144/16017 (94.6%)
parse_os: 1517/1528 (99.3%)
parse_ua: 204/205 (99.5%)
```

Of course, if someone would like to achieve 100% accuracy, PRs will absolutely be reviewed.

## Licensing

The licensing of the UAParser Julia module is under the [default MIT Expat license](https://github.com/JuliaWeb/UAParser.jl/blob/master/LICENSE.md). The data
contained in regexes.yaml is Copyright 2009 Google Inc. and available under the Apache License, Version 2.0.
