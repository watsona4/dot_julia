# OpenPixelControl.jl

This package provides a [Julia](https://julialang.org) port of the [Python](https://raw.githubusercontent.com/zestyping/openpixelcontrol/master/python/opc.py) of the [openpixelcontrol](https://github.com/zestyping/openpixelcontrol) Client for the streaming protocol for controlling RGB LEDs.

# A small example
As an example, you can use the following small code example.
First start up your local [fadecandy server](https://github.com/scanlime/fadecandy)

Then, to set the first pixel to red, the second to blue after activating interpolation,
you can use the following small code

```
using OpenPixelControl
o = OpenPixelConnection()
setInterpolation(o,true)
setPixel(o, (RGB(1.,0.,0.), RGB(0.,0.,1.)) ) 
```

## License
```
# -----------------------------------------------------
# "THE COFFEE-AND-MATE-WARE LICENSE" (Revision 42/023)
# Ronny Bergmann <stackenlichten@ronnybergmann.net>
# wrote this file. As long as you retain this notice
# you can do whatever you want with this stuff. If we
# meet some day, and you think this stuff is worth it,
# you can buy me a coffee or (Club) Mate in return.
# -----------------------------------------------------
````