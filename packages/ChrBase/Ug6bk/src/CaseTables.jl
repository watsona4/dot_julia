__precompile__(true)
"""
Case folding tables for Unicode characters

Copyright 2018 Gandalf Software, Inc., Scott P. Jones
Licensed under MIT License, see LICENSE.md
"""
module CaseTables

struct CaseTable
    l_tab::NTuple{128,UInt8}
    u_tab::NTuple{128,UInt8}
    t_tab::NTuple{64,UInt8}

    is_l_tab::NTuple{256, UInt8}
    is_u_tab::NTuple{256, UInt8}
    can_l_tab::NTuple{256, UInt8}
    can_u_tab::NTuple{256, UInt8}

    can_l_flg::UInt128
    can_u_flg::UInt128
    can_t_flg::UInt128
    can_sl_flg::UInt128
    can_su_flg::UInt128

    is_l_flg::UInt128
    is_u_flg::UInt128
    is_sl_flg::UInt128
    is_su_flg::UInt128

    siz_l_flg::UInt128
    siz_u_flg::UInt128
    max_siz_l::UInt32
    max_siz_u::UInt32
end

@static VERSION < v"0.7-" && (const islowercase = islower; const isuppercase = isupper)

# Calculate tables (later move these to library built based on Unicode tables with BinaryBuilder,
# loaded by BinaryProvider)

# For speed, we want to know which characters can be lowercased, uppercased, or titlecased
# We want to also know which ones increase or decrease in size in UTF-8 encoding

@inline utf8_len(cp::Unsigned) = ifelse(cp <= 0x7f, 1, ifelse(cp <= 0x7ff, 2, 3 + (cp > 0xffff)))
@inline utf8_len(ch::Char) = utf8_len(ch%UInt32)

const _z4 = 0%UInt32

const zerotup = (_z4, _z4, _z4, _z4, _z4, _z4, _z4, _z4,
                 _z4, _z4, _z4, _z4, _z4, _z4, _z4, _z4)

function _add_to_bv!(vec, tmp)
    tt = tuple(tmp...)
    tt == zerotup && return 0x0
    fill!(tmp, 0%UInt32)
    for (i, t) in enumerate(vec)
        (t == tt) && return UInt8(i)
    end
    push!(vec, tt)
    UInt8(length(vec))
end

# case tables should be:
# 128-bit bitmap to say whether a particular range of 512 code points can be folded
# 64-byte ntuple{32,UInt16}
function case_tables()
    bitvec = NTuple{16,UInt32}[]  # each element represents 512 characters
    tupvec = NTuple{32,UInt16}[]  # each element represents 32 characters
    offvec = NTuple{32,UInt8}[]   # each element maps 1024 character range to offsets in tupvec

    sizvecl = Pair{UInt16,UInt64}[]
    sizvecu = Pair{UInt16,UInt64}[]

    # Top level tables
    l_tab  = fill(0x0, 128)
    u_tab  = fill(0x0, 128)
    t_tab  = fill(0x0, 64)

    # The elements of these are all offsets into bitvec
    is_l_tab  = fill(0x0, 256)
    is_u_tab  = fill(0x0, 256)
    can_l_tab = fill(0x0, 256)
    can_u_tab = fill(0x0, 256)
    is_l_flg = is_u_flg = is_sl_flg = is_su_flg = 0%UInt128

    # These tables get reused, stored in offvec
    l_off = fill(0x0, 32)
    u_off = fill(0x0, 32)
    t_off = fill(0x0, 32)

    # These tables get reused, stored in tupvec
    tmp_l = fill(0x0000, 32)
    tmp_u = fill(0x0000, 32)
    tmp_t = fill(0x0000, 32)

    # These tables get reused, stored in bitvec
    bit_is_l  = fill(0%UInt32, 16)
    bit_is_u  = fill(0%UInt32, 16)
    bit_can_l = fill(0%UInt32, 16)
    bit_can_u = fill(0%UInt32, 16)

    # Handle BMP
    l_mid = u_mid = t_mid = false
    can_l_flg = can_u_flg = can_t_flg = 0%UInt128
    siz_l_flg = siz_u_flg = 0%UInt128
    max_siz_l = max_siz_u = 0%UInt32
    tmp_is_l = tmp_is_u = tmp_can_l = tmp_can_u = 0%UInt32
    for rng in (0x0080:0x20:0xd7e0, 0xe000:0x20:0xffe0), base in rng
        hipos  = (base >>> 10) + 1
        hibit  = UInt128(1) << (base >>> 9)
        midbits = ((base >>> 5) & 0x1f) + 1

        # Handle block of 32 characters
        l_flg = u_flg = t_flg = false
        diff_l = diff_u = 0%UInt64
        for off = 0x00:0x1f
            cp = UInt16(base + off)
            lowbit = UInt32(1) << off
            ch = Char(cp)
            cl = UInt16(lowercase(ch))
            cu = UInt16(uppercase(ch))
            ct = UInt16(titlecase(ch))
            tmp_l[off+1] = cl
            tmp_u[off+1] = cu
            tmp_t[off+1] = ct
            islowercase(ch) && (tmp_is_l |= lowbit)
            isuppercase(ch) && (tmp_is_u |= lowbit)
            cp === cl === cu === ct && continue
            sizc = utf8_len(ch)
            sizu = utf8_len(cu)
            sizt = utf8_len(ct)
            if cl !== cp
                l_flg = true
                tmp_can_l |= lowbit
                diff = utf8_len(cl) - sizc
                -2 <= diff <= 1 || error("Size difference for $cp -> $cl is $diff")
                diff == 0 || (diff_l |= (UInt64(diff & 3)<<(off<<1)); max_siz_l = cp)
            end
            if cu !== cp
                u_flg = true
                tmp_can_u |= lowbit
                diff = sizu - sizc
                -2 <= diff <= 1 || error("Size difference for $cp -> $cu is $diff")
                diff == 0 || (diff_u |= (UInt64(diff & 3)<<(off<<1)); max_siz_u = cp)
            end
            if ct !== cu
                t_flg = true
                sizu == sizt ||
                    error("Titlecase and Uppercase are not same size in UTF-8: " *
                          "$cp $cu:$sizu $ct:$sizt")
            end
        end

        bitoff = ((base >>> 5) & 0xf) + 1
        bit_is_l[bitoff]  = tmp_is_l
        bit_is_u[bitoff]  = tmp_is_u
        bit_can_l[bitoff] = tmp_can_l
        bit_can_u[bitoff] = tmp_can_u

        tmp_is_l = tmp_is_u = tmp_can_l = tmp_can_u = 0%UInt32

        if l_flg
            can_l_flg |= hibit
            l_mid = true # Have at least one in this set of blocks
            push!(tupvec, tuple(tmp_l...))
            l_off[midbits] = UInt8(length(tupvec))
        end
        if u_flg
            can_u_flg |= hibit
            u_mid = true
            push!(tupvec, tuple(tmp_u...))
            u_off[midbits] = UInt8(length(tupvec))
        end
        if t_flg
            can_t_flg |= hibit
            t_mid = true
            push!(tupvec, tuple(tmp_t...))
            t_off[midbits] = UInt8(length(tupvec))
        else
            t_off[midbits] = u_off[midbits]
        end

        diff_l == 0 || (siz_l_flg |= hibit; push!(sizvecl, base => diff_l))
        diff_u == 0 || (siz_u_flg |= hibit; push!(sizvecu, base => diff_u))

        if bitoff == 16
            # Reset bits
            pos  = (base >>> 9) + 1
            (is_l_tab[pos]  = _add_to_bv!(bitvec, bit_is_l)) == 0  || (is_l_flg |= hibit)
            (is_u_tab[pos]  = _add_to_bv!(bitvec, bit_is_u)) == 0  || (is_u_flg |= hibit)
            (can_l_tab[pos] = _add_to_bv!(bitvec, bit_can_l)) == 0 || (can_l_flg |= hibit)
            (can_u_tab[pos] = _add_to_bv!(bitvec, bit_can_u)) == 0 || (can_u_flg |= hibit)
        end

        # Check for end of chunk
        midbits == 32 || continue

        if l_mid
            push!(offvec, tuple(l_off...))
            l_tab[hipos] = UInt8(length(offvec))
            fill!(l_off, 0x0)
            l_mid = false
        end
        if u_mid
            push!(offvec, tuple(u_off...))
            u_tab[hipos] = UInt8(length(offvec))
            fill!(u_off, 0x0)
            u_mid = false
        end
        if t_mid
            push!(offvec, tuple(t_off...))
            t_tab[hipos] = UInt8(length(offvec))
            t_mid = false
        else
            t_tab[hipos] = u_tab[hipos]
        end
    end

    # Handle SLP
    can_sl_flg = can_su_flg = 0%UInt128

    for base in 0x0000:0x20:0xffe0
        hipos  = (base >>> 10) + 65
        hibit  = (1%UInt128) << ((base >>> 9) & 0x7f)
        midbits = ((base >>> 5) & 0x1f) + 1

        # Handle block of 32 characters
        l_flg = u_flg = false
        for off = 0x00:0x1f
            cp = UInt32(0x10000 + base + off)
            ch = Char(cp)
            cl = UInt32(lowercase(ch))
            cu = UInt32(uppercase(ch))
            ct = UInt32(titlecase(ch))
            lowbit = UInt32(1) << off
            islowercase(ch) && (tmp_is_l |= lowbit)
            isuppercase(ch) && (tmp_is_u |= lowbit)
            tmp_l[off+1] = cl%UInt16
            tmp_u[off+1] = cu%UInt16
            cp === cl === cu === ct && continue
            ct == cu || error("titlecase: $cp -> $ct not same as uppercase $cu")
            sizc = 4
            sizl = utf8_len(cl)
            sizu = utf8_len(cu)
            sizl == sizu == 4 || error("UTF-8 sizes not 4: $cp: $cl=$sizl, $cu=$sizu")
            if cl !== cp
                tmp_can_l |= lowbit
                l_flg = true
            end
            if cu !== cp
                tmp_can_u |= lowbit
                u_flg = true
            end
        end

        if l_flg
            l_mid = true
            push!(tupvec, tuple(tmp_l...))
            l_off[midbits] = UInt8(length(tupvec))
        end
        if u_flg
            u_mid = true
            push!(tupvec, tuple(tmp_u...))
            u_off[midbits] = UInt8(length(tupvec))
        end

        bitoff = ((base >>> 5) & 0xf) + 1
        bit_is_l[bitoff] = tmp_is_l
        bit_is_u[bitoff] = tmp_is_u
        bit_can_l[bitoff] = tmp_can_l
        bit_can_u[bitoff] = tmp_can_u

        tmp_is_l = tmp_is_u = tmp_can_l = tmp_can_u = 0%UInt32

        if bitoff == 16
            # Reset bits
            pos  = (base >>> 9) + 129
            (is_l_tab[pos]  = _add_to_bv!(bitvec, bit_is_l)) == 0  || (is_sl_flg |= hibit)
            (is_u_tab[pos]  = _add_to_bv!(bitvec, bit_is_u)) == 0  || (is_su_flg |= hibit)
            (can_l_tab[pos] = _add_to_bv!(bitvec, bit_can_l)) == 0 || (can_sl_flg |= hibit)
            (can_u_tab[pos] = _add_to_bv!(bitvec, bit_can_u)) == 0 || (can_su_flg |= hibit)
        end

        # Check for end of chunk
        midbits == 32 || continue

        if l_mid
            push!(offvec, tuple(l_off...))
            l_tab[hipos] = UInt8(length(offvec))
            fill!(l_off, 0x0)
            l_mid = false
        end
        if u_mid
            push!(offvec, tuple(u_off...))
            u_tab[hipos] = UInt8(length(offvec))
            fill!(u_off, 0x0)
            u_mid = false
        end
    end

    # Check that there are no upper / lower / title case characters above SLP
    for cp in 0x20000:0x10ffff
        ch = Char(cp)
        ch == lowercase(ch) == uppercase(ch) == titlecase(ch) ||
            error("$cp has lower/upper/titlecase")
    end

    (CaseTable(tuple(l_tab...), tuple(u_tab...), tuple(t_tab...),
               tuple(is_l_tab...), tuple(is_u_tab...),
               tuple(can_l_tab...), tuple(can_u_tab...),
               can_l_flg, can_u_flg, can_t_flg, can_sl_flg, can_su_flg,
               is_l_flg, is_u_flg, is_sl_flg, is_su_flg,
               siz_l_flg, siz_u_flg, max_siz_l, max_siz_u),
     tuple(tupvec...), tuple(offvec...), tuple(bitvec...),
     tuple(sizvecl...), tuple(sizvecu...))
end

const ct, tupvec, offvec, bitvec, sizvecl, sizvecu = case_tables()

end # module CaseTables
