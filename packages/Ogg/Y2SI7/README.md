# Ogg

[![Build Status](https://travis-ci.org/staticfloat/Ogg.jl.svg?branch=master)](https://travis-ci.org/staticfloat/Ogg.jl)

Basic bindings to `libogg` to read Ogg bitstreams.  Basic operation is to use `load()` to read in an array of packets which can then be decoded by whatever higher-level codec can use them (such as [`Opus.jl`](https://github.com/staticfloat/Opus.jl)), or use `save()` to write out a set of packets and their respective granule positions.  Manual use of this package is unusual, however if you are curious as to how `.ogg` files work, this package can act as a nice debugging tool.

To look into details of an `.ogg` file such as its actual pages, you must keep track of the `OggDecoder` object so you can inspect its internal fields `pages` and `packets`.  The definition of `load()` is roughly equivalent to:

```julia
dec = OggDecoder()
Ogg.decode_all_pages(dec, fio)
Ogg.decode_all_packets(dec, fio)
```

Where `fio` is an `IO` object you wish to decode.  The fields `dec.pages` and `dec.packets` now contains much information about the `.ogg` file you have just decoded.
