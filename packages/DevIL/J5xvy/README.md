# DevIL

DevIL / OpenIL binding for Julia

Lib version: 1.7.8

Currently only IL is bound, ILU and ILUT are not.

## Usage

For usage information & documentation please visit 
http://openil.sourceforge.net/

## Essentials

If you don't read the docs, at least read this: you need to call `ilInit()` before calling any other IL functions, otherwise it might crash your session with null pointer access.

Here's what a typical cycle of loading an image looks like:

```Julia
using DevIL

ilInit()

ilBindImage(ilGenImage())
ilLoadImage("example.png")
w = ilGetInteger(IL_IMAGE_WIDTH)
h = ilGetInteger(IL_IMAGE_HEIGHT)
dataPtr = ilGetData()
# do stuff with the image data and when we're done
ilDeleteImage(ilGetInteger(IL_CUR_IMAGE))

# when we're done with the library
ilShutDown()
```

## Contacts & Issues

For problems with the Julia binding, please visit https://github.com/JuliaGL/DevIL.jl
