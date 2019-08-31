using BitsFields
using Test


field1span  =  6
field1shift =  0
field2span  = 10
field2shift = field1span

field1 = BitField(UInt16, field1span, field1shift, :field1)
field2 = BitField(UInt16, field2span, field2shift, :field2)

bitfields = BitFields(field1, field2)

workingbits = zero(bitfields)


field1value = 0x15
field2value = 0x02f6

set!(bitfields[1], field1value, workingbits)
set!(bitfields[2], field2value, workingbits)

@test get(bitfields[2], workingbits) == UInt16(0x02f6)

@test get(bitfields, workingbits)    == [ UInt16(0x15), UInt16(0x02f6) ]



#                    span      shift      name         bits used
bitfield1 = BitField(  8,            0, :field1);   #      8
bitfield2 = BitField(  4,            8, :field2);   #     12
bitfield3 = BitField( 12,          4+8, :field3);   #     24
bitfield4 = BitField( 16,       12+4+8, :field4);   #     40
bitfield5 = BitField( 20,    16+12+4+8, :field5);   #     60
bitfield6 = BitField(  4, 20+16+12+4+8, :field6);   #     64

bitfields = BitFields(bitfield1, bitfield2, bitfield3,
                      bitfield4, bitfield5, bitfield6);

valfield1 = 0xae;
valfield2 = 0x06;
valfield3 = 0x05f3;
valfield4 = 0x3113;
valfield5 = 0x7654;
valfield6 = 0x03;

target = zero(bitfields)

set!(bitfields[1], valfield1, target)
set!(bitfields[2], valfield2, target)
set!(bitfields[3], valfield3, target)
set!(bitfields[4], valfield4, target)
set!(bitfields[5], valfield5, target)
set!(bitfields[6], valfield6, target)

@test get(bitfield1, target) == valfield1
@test get(bitfield2, target) == valfield2
@test get(bitfield3, target) == valfield3
@test get(bitfield4, target) == valfield4
@test get(bitfield5, target) == valfield5
@test get(bitfield6, target) == valfield6

fields = get(bitfields, target)

result = [ 0x00000000000000ae,
           0x0000000000000006,
           0x00000000000005f3,
           0x0000000000003113,
           0x0000000000007654,
           0x0000000000000003 ]

@test fields == result

@test fields[1] == valfield1
@test fields[2] == valfield2
@test fields[3] == valfield3
@test fields[4] == valfield4
@test fields[5] == valfield5
@test fields[6] == valfield6


namedfields = NamedTuple(bitfields)

@test namedfields.field1 == bitfields[1]
@test namedfields.field2 == bitfields[2]
@test namedfields.field3 == bitfields[3]
@test namedfields.field4 == bitfields[4]
@test namedfields.field5 == bitfields[5]
@test namedfields.field6 == bitfields[6]

