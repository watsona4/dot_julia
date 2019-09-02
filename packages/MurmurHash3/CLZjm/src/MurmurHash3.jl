"""
MurmurHash3 was written by Austin Appleby, and is placed in the public
domain. The author hereby disclaims copyright to this source code.

This version was translated into Julia by Scott P. Jones
It is licensed under the MIT license

Note - The x86 and x64 versions do _not_ produce the same results, as the
algorithms are optimized for their respective platforms. You can still
compile and run any of them on any platform, but your performance with the
non-native version will be less than optimal.
"""
module MurmurHash3
export mmhash128_a, mmhash128_u, mmhash128_c, mmhash32

u8(val)  = val%UInt8
u32(val) = val%UInt32
u64(val) = val%UInt64

@inline rotl(x::Unsigned, r) = (x << r) | (x >>> (sizeof(typeof(x))*8 - r))

@inline xor33(k::UInt64) = xor(k, k >>> 33)

@inline rotl27(k) = rotl(k, 27)
@inline rotl31(k) = rotl(k, 31)
@inline rotl33(k) = rotl(k, 33)

#-----------------------------------------------------------------------------
# Finalization mix - force all bits of a hash block to avalanche

@inline fmix(k::UInt64) = xor33(xor33(xor33(k) * 0xff51afd7ed558ccd) * 0xc4ceb9fe1a85ec53)

const c1 = 0x87c37b91114253d5
const c2 = 0x4cf5ad432745937f

@inline function mhblock(h1, h2, k1, k2)
    h1 = (rotl27(xor(h1, rotl31(k1 * c1) * c2)) + h2) * 5 + 0x52dce729
    h2 = (rotl31(xor(h2, rotl33(k2 * c2) * c1)) + h1) * 5 + 0x38495ab5
    h1, h2
end

@inline function mhbody(nblocks, pnt, h1, h2)
    for i = 1:nblocks
        h1, h2 = mhblock(h1, h2, unsafe_load(pnt), unsafe_load(pnt + 8))
        pnt += 16
    end
    pnt, h1, h2
end

@inline mhtail1(h1, k1) = xor(h1, rotl31(k1 * c1) * c2)
@inline mhtail2(h2, k2) = xor(h2, rotl33(k2 * c2) * c1)

@inline function mhfin(len, h1, h2)
    h1 = xor(h1, u64(len))
    h2 = xor(h2, u64(len))

    h1 += h2
    h2 += h1

    h1 = fmix(h1)
    h2 = fmix(h2)

    h1 += h2
    h1, h1 + h2
end

#---------------------------------------------------------------------------

up8(val)  = u32(val) << 8
up16(val) = u32(val) << 16
up24(val) = u32(val) << 24
up32(val) = u64(val) << 32
up40(val) = u64(val) << 40
up48(val) = u64(val) << 48
up56(val) = u64(val) << 56

dn6(val) = u8(val >>> 6)
dn12(val) = u8(val >>> 12)
dn18(val) = u8(val >>> 18)

msk6(val) = u8(val & 0x3f)

# Support functions for UTF-8 handling
@inline get_utf8_2(ch) = (0xc0 | dn6(ch),  0x80 | msk6(ch))
@inline get_utf8_3(ch) = (0xe0 | dn12(ch), 0x80 | msk6(dn6(ch)), 0x80 | msk6(ch))
@inline get_utf8_4(ch) = (0xf0 | dn18(ch), 0x80 | msk6(dn12(ch)),
                          0x80 | msk6(dn6(ch)), 0x80 | msk6(ch))

# Optimized in-place conversion to UTF-8 for hashing compatibly with isequal / String
@inline shift_n(v, n) = u64(v) << (((n & 7)%UInt)<<3)

# if cnt == 0 - 4, bytes must fit in k1
# cnt between 5 - 8, may overflow into k2
# if l == 8 - 12,  bytes must fit in k2
# cnt between 12 - 15, may overflow into k3

mergebytes(b1, b2)         = b1 | up8(b2)
mergebytes(b1, b2, b3)     = b1 | up8(b2) | up16(b3)
mergebytes(b1, b2, b3, b4) = b1 | up8(b2) | up16(b3) | up24(b4)

@inline function add_utf8(cnt, ch, k1::UInt64)
    if ch <= 0x7f
        cnt + 1, k1 | shift_n(ch, cnt)
    elseif ch <= 0x7ff
        b1, b2 = get_utf8_2(ch)
        cnt + 2, k1 | shift_n(mergebytes(b1, b2), cnt)
    elseif ch <= 0xffff
        b1, b2, b3 = get_utf8_3(ch)
        cnt + 3, k1 | shift_n(mergebytes(b1, b2, b3), cnt)
    else
        b1, b2, b3, b4 = get_utf8_4(ch)
        cnt + 4, k1 | shift_n(mergebytes(b1, b2, b3, b4), cnt)
    end
end

@inline function add_utf8_split(cnt, ch, k1::UInt64)
    if ch <= 0x7f
        cnt + 1, k1 | shift_n(ch, cnt), u64(0)
    elseif ch <= 0x7ff
        b1, b2 = get_utf8_2(ch)
        if (cnt & 7) == 7
            cnt + 2, k1 | up56(b1), u64(b2)
        else
            cnt + 2, k1 | shift_n(b1 | up8(b2), cnt), u64(0)
        end
    elseif ch <= 0xffff
        b1, b2, b3 = get_utf8_3(ch)
        if (cnt & 7) == 5
            cnt + 3, k1 | up40(b1) | up48(b2) | up56(b3), u64(0)
        elseif (cnt & 7) == 6
            cnt + 3, k1 | up48(b1) | up56(b2), u64(b3)
        else
            cnt + 3, k1 | up56(b1), u64(b2) | up8(b3)
        end
    else
        # This will always go over, may be 1, 2, 3 bytes in second word
        b1, b2, b3, b4 = get_utf8_4(ch)
        if (cnt & 7) == 5
            cnt + 4, k1 | up40(b1) | up48(b2) | up56(b3), u64(b4)
        elseif (cnt & 7) == 6
            cnt + 4, k1 | up48(b1) | up56(b2), b3 | up8(b4)
        else
            cnt + 4, k1 | up56(b1), u64(b2) | up8(b3) | up16(b4)
        end
    end
end

#-----------------------------------------------------------------------------

# AbstractString MurmurHash3, converts to UTF-8 on the fly
function mmhash128_8_c(str::AbstractString, seed::UInt32)
    k1 = k2 = u64(0)
    h1 = h2 = u64(seed)
    cnt = len = 0
    @inbounds for ch in str
        if cnt < 5
            cnt, k1 = add_utf8(cnt, u32(ch), k1)
        elseif cnt < 8
            cnt, k1, k2 = add_utf8_split(cnt, u32(ch), k1)
        elseif cnt < 13
            cnt, k2 = add_utf8(cnt, u32(ch), k2)
        else
            cnt, k2, k3 = add_utf8_split(cnt, u32(ch), k2)
            # When k1 and k2 are full, then hash another block
            if cnt > 15
                h1, h2 = mhblock(h1, h2, k1, k2)
                k1 = k3
                k2 = u64(0)
                len += 16
                cnt &= 15
            end
        end
    end
    # We should now have characters in k1 and k2, and total length in len
    if cnt != 0
        h1 = mhtail1(h1, k1)
        cnt > 8 && (h2 = mhtail2(h2, k2))
    end
    mhfin(len + cnt, h1, h2)
end

#----------------------------------------------------------------------------

# Note: this is designed to work on the Str/String types, where I know in advance that
# the start of the strings are 8-byte aligned, and it is safe to access a full
# 8-byte chunk always at the end (simply masking off the remaining 1-7 bytes)

@inline mask_load(pnt, left) = unsafe_load(pnt) & ((UInt64(1) << ((left & 7) << 3)) - 0x1)

function mmhash128_8_a(len::Integer, pnt::Ptr, seed::UInt32)
    pnt8, h1, h2 = mhbody(len >>> 4, reinterpret(Ptr{UInt64}, pnt), u64(seed), u64(seed))
    if (left = len & 15) > 0
        h1 = mhtail1(h1, left < 8 ? mask_load(pnt8, left) : unsafe_load(pnt8))
        left > 8 && (h2 = mhtail2(h2, mask_load(pnt8 + 8, left)))
    end
    mhfin(len, h1, h2)
end

function mmhash128_8_a(seed::Integer)
    h1 = fmix(2 * u64(seed))
    h2 = fmix(3 * u64(seed))
    h1 + h2, h1 + 2 * h2
end

#----------------------------------------------------------------------------

# Combine bits from k1, k2, k3
@inline shift_mix(shft, k1::T, k2::T, k3::T) where {T<:Union{UInt32,UInt64}} =
    k1 >>> shft | (k2 << (sizeof(T)*8 - shft)),
    k2 >>> shft | (k3 << (sizeof(T)*8 - shft)),
    k3 >>> shft

#----------------------------------------------------------------------------

function mmhash128_8_u(len::Integer, unaligned_pnt::Ptr, seed::UInt32)
    # Should optimize handling of short (< 16 byte) unaligned strings
    ulp = reinterpret(UInt, unaligned_pnt)
    pnt = reinterpret(Ptr{UInt64}, ulp & ~u64(7))
    fin = reinterpret(Ptr{UInt64}, (ulp + len + 0x7) & ~u64(7)) - 8
    shft = (ulp & u64(7))<<3
    # println("_mmhash128_8_u($len, $unaligned_pnt, $seed) => $pnt, $fin")
    h1 = h2 = u64(seed)
    k1 = unsafe_load(pnt) # Pick up first 1-7 bytes
    k2 = u64(0)
    while pnt < fin
        k1, k2, k3 = shift_mix(shft, k1, unsafe_load(pnt += 8), unsafe_load(pnt += 8))
        # print(" pnt=$pnt, k1=0x$(outhex(k1)), k2=0x$(outhex(k2))")
        h1, h2 = mhblock(h1, h2, k1, k2)
        # println(" => h1=0x$(outhex(h1)), h2=0x$(outhex(h2))")
        k1 = k3
    end
    # We should now have characters in k1 and k2, and total length in len
    if (len & 15) != 0
        h1 = mhtail1(h1, k1)
        (len & 15) > 8 && (h2 = mhtail2(h2, k2))
    end
    # println(" len=$len, h1=0x$(outhex(h1)), h2=0x$(outhex(h2))")
    mhfin(len, h1, h2)
end

#----------------------------------------------------------------------------

@inline xor16(k::UInt32) = xor(k, k >>> 16)
@inline xor13(k::UInt32) = xor(k, k >>> 13)

# I don't think these help the generated code anymore (but they make the code easier to read)
@inline rotl13(k) = rotl(k, 13)
@inline rotl15(k) = rotl(k, 15)
@inline rotl16(k) = rotl(k, 16)
@inline rotl17(k) = rotl(k, 17)
@inline rotl18(k) = rotl(k, 18)
@inline rotl19(k) = rotl(k, 19)

# Constants for mmhash_32
const d1 = 0xcc9e2d51
const d2 = 0x1b873593

@inline fmix(h::UInt32) = xor16(xor13(xor16(h) * 0x85ebca6b) * 0xc2b2ae35)

@inline mhblock(h1, k1) = rotl13(xor(h1, rotl15(k1 * d1) * d2))*5 + 0xe6546b64

@inline function mhbody(nblocks, pnt, h1)
    for i = 1:nblocks
        h1 = mhblock(h1, unsafe_load(pnt))
        pnt += 4
    end
    pnt, h1
end

function mmhash32(len, pnt, seed::UInt32)
    pnt, h1 = mhbody(len >>> 2, reinterpret(Ptr{UInt32}, pnt), seed)
    (len & 3) == 0 || (h1 = xor(h1, rotl15(unsafe_load(pnt)) * d1) * d2)
    fmix(xor(h1, u32(len)))
end

@inline function mhfin(len, h1, h2, h3, h4)
    h1 = xor(h1, u32(len))
    h2 = xor(h2, u32(len))
    h3 = xor(h3, u32(len))
    h4 = xor(h4, u32(len))

    h1 += h2; h1 += h3; h1 += h4; h2 += h1; h3 += h1; h4 += h1

    h1 = fmix(h1)
    h2 = fmix(h2)
    h3 = fmix(h3)
    h4 = fmix(h4)

    h1 += h2; h1 += h3; h1 += h4; h2 += h1; h3 += h1; h4 += h1

    up32(h2) | h1, up32(h4) | h3
end

#-----------------------------------------------------------------------------

# Calculate MurmurHash for 32-bit platforms

# Constants for mmhash128_4
const e1 = 0x239b961b
const e2 = 0xab0e9789
const e3 = 0x38b34ae5
const e4 = 0xa1e38b93

@inline function mhblock(h1, h2, h3, h4, k1, k2, k3, k4)
    h1 = (rotl19(xor(h1, rotl15(k1 * e1) * e2)) + h2)*5 + 0x561ccd1b
    h2 = (rotl17(xor(h2, rotl16(k2 * e2) * e3)) + h3)*5 + 0x0bcaa747
    h3 = (rotl15(xor(h3, rotl17(k3 * e3) * e4)) + h4)*5 + 0x96cd1c35
    h4 = (rotl13(xor(h4, rotl18(k4 * e4) * e1)) + h1)*5 + 0x32ac3b17
    h1, h2, h3, h4
end

@inline function mhbody(nblocks, pnt, h1, h2, h3, h4)
    for i = 1:nblocks
        h1, h2, h3, h4 =
            mhblock(h1, h2, h3, h4,
                    unsafe_load(pnt), unsafe_load(pnt+4), unsafe_load(pnt+8), unsafe_load(pnt+12))
        pnt += 16
    end
    pnt, h1, h2, h3, h4
end

function mmhash128_4(len, pnt, seed::UInt32)
    pnt, h1, h2, h3, h4 = mhbody(len >>> 4, pnt, seed, seed, seed, seed)
    if (left = len & 15) != 0
        h1  = xor(h1, rotl16(unsafe_load(pnt) * e1) * e2)
        if left > 4
            h2  = xor(h2, rotl16(unsafe_load(pnt+4) * e2) * e3)
            if left > 8
                h3  = xor(h3, rotl17(unsafe_load(pnt+8) * e3) * e4)
                left > 12 && (h4  = xor(h4, rotl18(unsafe_load(pnt+12) * e4) * e1))
            end
        end
    end
    mhfin(len, h1, h2, h3, h4)
end

@inline shift_n_32(v, n) = u32(v) << (((n & 7)%UInt)<<3)

@inline function get_utf8(cnt, ch)
    if ch <= 0x7f
        cnt + 1, u32(ch)
    elseif ch <= 0x7ff
        b1, b2 = get_utf8_2(ch)
        cnt + 2, mergebytes(b1, b2)
    elseif ch <= 0xffff
        b1, b2, b3 = get_utf8_3(ch)
        cnt + 3, mergebytes(b1, b2, b3)
    else
        b1, b2, b3, b4 = get_utf8_4(ch)
        cnt + 4, mergebytes(b1, b2, b3, b4)
    end
end

@inline function add_utf8_split(cnt, ch, k1::UInt32)
    if ch <= 0x7f
        cnt + 1, k1 | shift_n_32(ch, cnt), u32(0)
    elseif ch <= 0x7ff
        b1, b2 = get_utf8_2(ch)
        if (cnt & 7) == 3
            cnt + 2, k1 | up24(b1), u32(b2)
        else
            cnt + 2, k1 | shift_n_32(b1 | up8(b2), cnt), u32(0)
        end
    elseif ch <= 0xffff
        b1, b2, b3 = get_utf8_3(ch)
        if (cnt & 7) == 1
            cnt + 3, k1 | up8(b1) | up16(b2) | up24(b3), u32(0)
        elseif (cnt & 7) == 2
            cnt + 3, mergebytes(k1, b1, b2), u32(b3)
        else
            cnt + 3, k1 | up24(b1), b2 | up8(b3)
        end
    else
        # This will always go over, may be 1, 2, 3 bytes in second word
        b1, b2, b3, b4 = get_utf8_4(ch)
        if (cnt & 7) == 1
            cnt + 4, mergebytes(k1, b1, b2, b3), u32(b4)
        elseif (cnt & 7) == 2
            cnt + 4, mergebytes(k1, b1, b2), b3 | up8(b4)
        else
            cnt + 4, k1 | up24(b1), mergebytes(b2, b3, b4)
        end
    end
end

const mmhash128_c = @static sizeof(Int) == 8 ? mmhash128_8_c : mmhash128_4
const mmhash128_a = @static sizeof(Int) == 8 ? mmhash128_8_a : mmhash128_4
const mmhash128_u = @static sizeof(Int) == 8 ? mmhash128_8_c : mmhash128_4 # Todo: fix unaligned

end # module MurmurHash3
