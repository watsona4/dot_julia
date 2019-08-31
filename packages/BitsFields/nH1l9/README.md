# BitsFields.jl
#### Use adjacent bits as a bitfield. Use adjacent bitfields to copartition the useful.

----

#### Copyright ©&thinsp;2018 by Jeffrey Sarnoff. &nbsp;&nbsp; This work has been released under The MIT License.

-----

[![Build Status](https://travis-ci.org/JeffreySarnoff/BitsFields.jl.svg?branch=master)](https://travis-ci.org/JeffreySarnoff/BitsFields.jl)


-----

## Purpose

This package provides an easy way to describe and use bitfields within Julia.

## Worked Example

We want two bitfields, one that is six bits wide and another that is ten bits wide.
The total span for both bitfields is 6+10 == 16 bits, so a `UInt16` will hold them.

```
using BitsFields

field1span  =  6
field1shift =  0
field2span  = 10
field2shift = field1span

field1 = BitField(UInt16, :field1, field1span, field1shift)
field2 = BitField(UInt16, :field2, field2span, field2shift)

bitfields = BitFields(field1, field2)
```
To use the `bitfields`, provide a referenceable, type-matched and zeroed carrier. 
```
carrier = zero(bitfields)
```
Now we can set the fields and get their values.

```
field1value = 0x15
field2value = 0x02f6

set!(bitfields[1], field1value, carrier)
set!(bitfields[2], field2value, carrier)

get(bitfields[2], carrier)  # UInt16(0x02f6)

get(bitfields, carrier)     # [ UInt16(0x15), UInt16(0x02f6) ]
```

A bitfield may be changed, just set! it again.


## Demonstration

Each BitField embedded together as a sequence of BitFields share an unsigned integer bitstype.
All fields must specify the same unsigned type, as above where all six bitfields specify `UInt64`.
Any attempt to use more than one Unsigned type as "the mix UInts of different sizes is rejected.
So are attempts to use anything other than an unsigned bitstype for BitField embedding.

UInt64 is used for this when there is no unsigned type specified.  So you do not need to write it.

```julia
using BitsFields



#                    span      shift      name         bits used
bitfield1 = BitField(  8,            0, :field1);   #      8
bitfield2 = BitField(  4,            8, :field2);   #     12
bitfield3 = BitField( 12,          4+8, :field3);   #     24
bitfield4 = BitField( 16,       12+4+8, :field4);   #     40
bitfield5 = BitField( 20,    16+12+4+8, :field5);   #     60
bitfield6 = BitField(  4, 20+16+12+4+8, :field6);   #     64

bitfields = BitFields(bitfield1, bitfield2, bitfield3,
                      bitfield4, bitfield5, bitfield6);

namedfields = NamedTuple(bitfields)

namedfields.field1 === bitfields[1]
namedfields.field2 === bitfields[2]
namedfields.field3 === bitfields[3]
namedfields.field4 === bitfields[4]
namedfields.field5 === bitfields[5]
namedfields.field6 === bitfields[6]

```
## Use Case

Please see the example directory for a worked example with IEEE 754-2008 Floating Point Standard bit fields.
