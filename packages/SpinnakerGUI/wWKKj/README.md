# SpinnakerGUI

A [CImGui.jl](https://github.com/Gnimuc/CImGui.jl)-based GUI for controlling FLIR/PointGrey cameras through the Spinnaker API via [Spinnaker.jl](https://github.com/samuelpowell/Spinnaker.jl)

![](SpinnakerGUI%20Screenshot.png)

## Install
```julia
] add SpinnakerGUI
```

## Run
```
start()
```
On first run the GUI will use default window size and location values, but on close, will save layout state to an `imgui.ini` settings file in the current working directory that will used if present in the working directory of future sessions.

## Recording
Videos are encoded in H.264, with lossless compression by default, and saved in the current working directory. Different compression rates (see [ffmpeg crf](https://trac.ffmpeg.org/wiki/Encode/H.264)) can be set by setting the `compression` at start:
```julia
start(compression=23)
```
