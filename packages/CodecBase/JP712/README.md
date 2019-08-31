CodecBase.jl
============

[![TravisCI Status][travisci-img]][travisci-url]
[![codecov.io][codecov-img]][codecov-url]

## Installation

```julia
Pkg.add("CodecBase")
```

## Usage

```julia
using CodecBase

# UTF8-encoded text.
data = """
祇園精舎の鐘の声、諸行無常の響きあり。
沙羅双樹の花の色、盛者必衰のことわりをあらはす。
奢れる人も久しからず、唯春の夜の夢のごとし。
"""

# Base64-encoded data of the above.
base64 = """
56WH5ZyS57K+6IiO44Gu6ZCY44Gu5aOw44CB6Ku46KGM54Sh5b
i444Gu6Z+/44GN44GC44KK44CCCuaymee+heWPjOaoueOBruiK
seOBruiJsuOAgeebm+iAheW/heihsOOBruOBk+OBqOOCj+OCiu
OCkuOBguOCieOBr+OBmeOAggrlpaLjgozjgovkurrjgoLkuYXj
gZfjgYvjgonjgZrjgIHllK/mmKXjga7lpJzjga7lpKLjga7jgZ
TjgajjgZfjgIIK
"""

# Streaming API.
encoded = readstring(Base64EncoderStream(IOBuffer(data)))
@assert encoded == replace(base64, "\n", "")
decoded = read(Base64DecoderStream(IOBuffer(base64)))
@assert decoded == Vector{UInt8}(data)

# Byte array API.
encoded = transcode(Base64Encoder(), data)
@assert String(encoded) == replace(base64, "\n", "")
decoded = transcode(Base64Decoder(), base64)
@assert decoded == Vector{UInt8}(data)
```

This package exports following codecs and streams:

| Codec           | Stream                |
| --------------- | --------------------- |
| `Base16Encoder` | `Base16EncoderStream` |
| `Base16Decoder` | `Base16DecoderStream` |
| `Base32Encoder` | `Base32EncoderStream` |
| `Base32Decoder` | `Base32DecoderStream` |
| `Base64Encoder` | `Base64EncoderStream` |
| `Base64Decoder` | `Base64DecoderStream` |

See docstrings and
[TranscodingStreams.jl](https://github.com/bicycle1885/TranscodingStreams.jl)
for details.

[travisci-img]: https://travis-ci.org/bicycle1885/CodecBase.jl.svg?branch=master
[travisci-url]: https://travis-ci.org/bicycle1885/CodecBase.jl
[codecov-img]: http://codecov.io/github/bicycle1885/CodecBase.jl/coverage.svg?branch=master
[codecov-url]: http://codecov.io/github/bicycle1885/CodecBase.jl?branch=master
