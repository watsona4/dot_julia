## The BitField

Referencing individual bit positions within a carrier type (using UInt16 as an example).

----

| offset from the `lsbit`| 15| 14| 13| 12| 11| 10|  9|  8|  7|  6|  5|  4|  3|  2|  1|  0|
|:----------------------:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| most & least significant |`msbit`| |   |   |   |   |   |   |   |   |   |   |   |   |  |`lsbit`|


_The offset from the least significant bit gives the number of bit positions that must be shifted over to take the content occupying the `lsb(it)` and place it into the bit position given by that offset_.

----

A bitfield may be formed of a single bit's position or formed of as many bit positions as exist within the carrier type, and any number of contiguous bit positions in between.  The widest unsigned bits type is UInt128.  So, the bitfield of maximal span is a field comprised of all 128 bit positions available where the carrier type is UInt128.  For each of our available carrier types {UInt8, UInt16, UInt32, UInt64, UInt128}, there is an immediately associated bitfield of maximal span.  

| carrier type | maximal bitfield span |    comment     |
|:------------:|:---------------------:|:--------------:|
| UInt8        | 8                     |  prefer UInt16 unless app requires UInt8 |
| UInt16       | 16                    |                |
| UInt32       | 32                    |                |
| UInt64       | 64                    |                |
| UInt128      | 128                   |  prefer UInt64 unless app requires UInt128 |


To represent a bitfield, any bitfield that
```julia
struct BitField{<:UBits} <: AbstractBitField
    nbits::BitCount
    shift::BitCount
    maskof1s::U       # U is the `carrier` type
    maskof0s::U       #   an unsigned bits type
    name::Symbol
end
```
