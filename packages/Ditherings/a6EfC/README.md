# Ditherings
Dithering Algorithms for Julia

# Basic Usage Examples
`julia> using Ditherings`

---
#### Simple Reduced Precision Colour
`julia> img = load("lenna.png");`

![alt text](https://github.com/NTimmons/Ditherings/blob/master/docs/Lenna.png?raw=true)

---
#### Switch to zero or one per pixel
`julia> Ditherings.FloydSteinbergDither4Sample(img, Ditherings.ZeroOne)`

![alt text](https://github.com/NTimmons/Ditherings/blob/master/docs/FS12_01.png?raw=true)

---
#### Switch to zero or one per channel
`julia> Ditherings.FloydSteinbergDither4Sample(img, Ditherings.ZeroOne_PerChannel)`

![alt text](https://github.com/NTimmons/Ditherings/blob/master/docs/FS12_01PerChannel.png?raw=true)

# Approach

The aim of these funcions is that you can call a function which represents an error diffusion shape, and then pass in a palette function which maps the input function into the reduced precision space. Optionally you can also pass in custom weights for the error diffusion kernel
