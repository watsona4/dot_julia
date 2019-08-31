# BitsFields.jl

## Overview

This package facilitates the use of __bit fields__.  It is written entirely in Julia and released under the MIT License.

### Terminology

A `bit field` is a contiguous sequence of one or more bits within a `carrier` type (the substrate).

- A `single bit field` is field that has exactly two states: {0b0, 0b1}. The span of a single bit field is one bit.
- A `multibit field` is a field that spans two or more adjacent bits.
- An `n⚬bit field` is a multibit field that spans `n` bits.

A `bit multifield` is a collection of one or more `bit fields` within a shared `carrier` type (the substrate).

The bit fields that compose a bit multifield may or may not be mutually contiguous (there is no requirement that the substrate is completely allocated to the constituent bit fields, nor that any specific bit be allocated).


[__The BitField__](thebitfield.md)

[__The BitMultiField__](multifields.md)

[_IEEE Standard Floating Point fields_](ieeestandard754-2008.md)

[_Worked Example: Float32 bitfields_](workeduse.md)

[__References__](references.md)
