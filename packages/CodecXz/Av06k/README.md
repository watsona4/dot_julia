CodecXz.jl
==========

[![TravisCI Status][travisci-img]][travisci-url]
[![AppVeyor Status][appveyor-img]][appveyor-url]
[![codecov.io][codecov-img]][codecov-url]

## Installation

```julia
Pkg.add("CodecXz")
```

## Usage

```julia
using CodecXz

# Some text.
text = """
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean sollicitudin
mauris non nisi consectetur, a dapibus urna pretium. Vestibulum non posuere
erat. Donec luctus a turpis eget aliquet. Cras tristique iaculis ex, eu
malesuada sem interdum sed. Vestibulum ante ipsum primis in faucibus orci luctus
et ultrices posuere cubilia Curae; Etiam volutpat, risus nec gravida ultricies,
erat ex bibendum ipsum, sed varius ipsum ipsum vitae dui.
"""

# Streaming API.
stream = XzCompressorStream(IOBuffer(text))
for line in eachline(XzDecompressorStream(stream))
    println(line)
end
close(stream)

# Array API.
compressed = transcode(XzCompressor, text)
@assert sizeof(compressed) < sizeof(text)
@assert transcode(XzDecompressor, compressed) == Vector{UInt8}(text)
```

This package exports following codecs and streams:

| Codec            | Stream                 |
| ---------------- | ---------------------- |
| `XzCompressor`   | `XzCompressorStream`   |
| `XzDecompressor` | `XzDecompressorStream` |

See docstrings and [TranscodingStreams.jl](https://github.com/bicycle1885/TranscodingStreams.jl) for details.

[travisci-img]: https://travis-ci.org/bicycle1885/CodecXz.jl.svg?branch=master
[travisci-url]: https://travis-ci.org/bicycle1885/CodecXz.jl
[appveyor-img]: https://ci.appveyor.com/api/projects/status/2otqmsovdp76og60?svg=true
[appveyor-url]: https://ci.appveyor.com/project/bicycle1885/codecxz-jl
[codecov-img]: http://codecov.io/github/bicycle1885/CodecXz.jl/coverage.svg?branch=master
[codecov-url]: http://codecov.io/github/bicycle1885/CodecXz.jl?branch=master
