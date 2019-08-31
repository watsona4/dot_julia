# TODO:
const BIG_ENDIAN = ENDIAN_BOM == 0x01020304

# TODO: endianness

const INIT_STATE = UInt32[0x67452301,
                          0xEFCDAB89,
                          0x98BADCFE,
                          0x10325476,
                          0xC3D2E1F0]

const K0  = 0x00000000
const K1  = 0x5A827999
const K2  = 0x6ED9EBA1
const K3  = 0x8F1BBCDC
const K4  = 0xA953FD4E
const KK0 = 0x50A28BE6
const KK1 = 0x5C4DD124
const KK2 = 0x6D703EF3
const KK3 = 0x7A6D76E9
const KK4 = 0x00000000

@inline ROTL32(num, shift::T) where T = (num << shift) | (num >> (T(32) - shift))
@inline F0(x, y, z) = x ⊻ y ⊻ z
@inline F1(x, y, z) = (x & y) | (~x & z)
@inline F2(x, y, z) = (x | ~y) ⊻ z
@inline F3(x, y, z) = (x & z) | (y & ~z)
@inline F4(x, y, z) = x ⊻ (y | ~z)

const left_p = ( 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
                 8, 5, 14, 2, 11, 7, 16, 4, 13, 1, 10, 6, 3, 15, 12, 9,
                 4, 11, 15, 5, 10, 16, 9, 2, 3, 8, 1, 7, 14, 12, 6, 13,
                 2, 10, 12, 11, 1, 9, 13, 5, 14, 4, 8, 16, 15, 6, 7, 3,
                 5, 1, 6, 10, 8, 13, 3, 11, 15, 2, 4, 9, 12, 7, 16, 14 )
const left_q = ( 11, 14, 15, 12, 5, 8, 7, 9, 11, 13, 14, 15, 6, 7, 9, 8,
                 7, 6, 8, 13, 11, 9, 7, 15, 7, 12, 15, 9, 11, 7, 13, 12,
                 11, 13, 6, 7, 14, 9, 13, 15, 14, 8, 13, 6, 5, 12, 7, 5,
                 11, 12, 14, 15, 14, 15, 9, 8, 9, 14, 5, 6, 8, 6, 5, 12,
                 9, 15, 5, 11, 6, 8, 13, 12, 5, 12, 13, 14, 11, 8, 5, 6 )
const right_p = ( 6, 15, 8, 1, 10, 3, 12, 5, 14, 7, 16, 9, 2, 11, 4, 13,
                  7, 12, 4, 8, 1, 14, 6, 11, 15, 16, 9, 13, 5, 10, 2, 3,
                  16, 6, 2, 4, 8, 15, 7, 10, 12, 9, 13, 3, 11, 1, 5, 14,
                  9, 7, 5, 2, 4, 12, 16, 1, 6, 13, 3, 14, 10, 8, 11, 15,
                  13, 16, 11, 5, 2, 6, 9, 8, 7, 3, 14, 15, 1, 4, 10, 12 )
const right_q = ( 8, 9, 9, 11, 13, 15, 15, 5, 7, 7, 8, 11, 14, 14, 12, 6,
                  9, 13, 15, 7, 12, 8, 9, 11, 7, 7, 12, 7, 6, 15, 13, 11,
                  9, 7, 15, 11, 8, 6, 6, 14, 12, 13, 5, 14, 13, 13, 7, 5,
                  15, 5, 8, 11, 14, 14, 6, 14, 6, 9, 12, 9, 12, 5, 15, 8,
                  8, 5, 12, 9, 12, 5, 14, 6, 8, 13, 6, 5, 15, 13, 11, 11 )

# Left lane generator macro
macro L(i)
    # @assert i <= 80
    # @assert i >= 1

    # Rotate the words
    ww = (:a, :b, :c, :d, :e)
    a = ww[((81 - i) % 5) + 1]
    b = ww[((82 - i) % 5) + 1]
    c = ww[((83 - i) % 5) + 1]
    d = ww[((84 - i) % 5) + 1]
    e = ww[((85 - i) % 5) + 1]

    f = Symbol("F", div(i - 1, 16))
    k = Symbol("K", div(i - 1, 16))

    r = left_p[i]
    s = left_q[i]

    return esc(quote
        t = $a + $f($b, $c, $d) + $k + unsafe_load(buf, $r)
        $a = ROTL32(UInt32( t), UInt8($s)) + $e
        $c = ROTL32(UInt32($c), UInt8(10))
    end)
end

# Right lane generator macro
macro R(i)
    # @assert i <= 80
    # @assert i >= 1

    # Rotate the words
    ww = (:a, :b, :c, :d, :e)
    a = ww[((81 - i) % 5) + 1]
    b = ww[((82 - i) % 5) + 1]
    c = ww[((83 - i) % 5) + 1]
    d = ww[((84 - i) % 5) + 1]
    e = ww[((85 - i) % 5) + 1]

    f = Symbol("F",  4 - div(i - 1, 16))
    k = Symbol("KK",     div(i - 1, 16))

    r = right_p[i]
    s = right_q[i]

    return esc(quote
        t = $a + $f($b, $c, $d) + $k + unsafe_load(buf, $r)
        $a = ROTL32(UInt32( t), UInt8($s)) + $e
        $c = ROTL32(UInt32($c), UInt8(10))
    end)
end
