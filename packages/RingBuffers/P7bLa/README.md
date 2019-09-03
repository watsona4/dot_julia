# RingBuffers

[![Build Status](https://travis-ci.org/JuliaAudio/RingBuffers.jl.svg?branch=master)](https://travis-ci.org/JuliaAudio/RingBuffers.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/lpjc1mv9stbkdhih?svg=true)](https://ci.appveyor.com/project/ssfrr/ringbuffers-jl)
[![codecov.io](https://codecov.io/github/JuliaAudio/RingBuffers.jl/coverage.svg?branch=master)](https://codecov.io/github/JuliaAudio/RingBuffers.jl?branch=master)

This package provides the `RingBuffer` type, which is a circular, fixed-size multi-channel buffer.

This package implements `read`, `read!`, and `write` methods on the `RingBuffer` type, and supports reading and writing NxM `AbstractArray` subtypes, where N is the channel count and M is the length in frames. It also supports reading and writing from `AbstractVector`s, in which case the memory is treated as a raw buffer with interleaved data.

Under the hood this package uses the `pa_ringbuffer` C implementation from PortAudio, which is a lock-free single-reader single-writer ringbuffer. The benefit of building on this is that you can write C modules for other libraries that can communicate with Julia over this lock-free ringbuffer using the `portaudio.h` header file. See the [PortAudio](https://github.com/JuliaAudio/PortAudio.jl) library for an example of using this to pass data between Julia's main thread and an audio callback in a different thread.
