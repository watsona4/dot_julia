__precompile__(true)
"""
Regex functions for Str strings

Copyright 2018-2019 Gandalf Software, Inc., Scott P. Jones, and other contributors to the Julia language
Licensed under MIT License, see LICENSE.md
Based in part on julia/base/regex.jl and julia/base/pcre.jl
"""
module StrRegex

import Base.Threads

using ModuleInterfaceTools

const BASE_REGEX_MT = isdefined(Base.PCRE, :PCRE_COMPILE_LOCK)

@api extend! StrBase

@api base Regex, match, compile, eachmatch

@api public RegexStr, RegexStrMatch, "@r_str", "@R_str"

const _not_found = StrBase._not_found

using Base: RefValue, replace_err, SubstitutionString

using PCRE2
const PCRE = PCRE2

const deb = RefValue(false)

const MATCH_CONTEXT = [(C_NULL,C_NULL,C_NULL)]

codeunit_index(::Type{UInt8})  = 1
codeunit_index(::Type{UInt16}) = 2
codeunit_index(::Type{UInt32}) = 3

match_context(::Type{T}, tid) where {T<:CodeUnitTypes} =
    @inbounds MATCH_CONTEXT[tid][codeunit_index(T)]

const JIT_STACK_START_SIZE = 32768
const JIT_STACK_MAX_SIZE = 1048576

function __init__()
    if (n = Threads.nthreads()) != 1
        resize!(MATCH_CONTEXT, n)
        fill!(MATCH_CONTEXT, (C_NULL, C_NULL, C_NULL))
    end
end

# UCP, UTF and NO_UTF_CHECK are based on the string type
const DEFAULT_COMPILER_OPTS = PCRE.ALT_BSUX
const DEFAULT_MATCH_OPTS    = 0%UInt32

const Binary_Regex_CSEs = Union{ASCIICSE,BinaryCSE,Text1CSE,Text2CSE,Text4CSE}
const Regex_CSEs = Union{Binary_Regex_CSEs,Latin_CSEs,UTF8_CSEs,UCS2_CSEs,UTF16CSE, UTF32_CSEs}

const _VALID = PCRE.NO_UTF_CHECK
const _UTF   = PCRE.UTF
const _UCP   = PCRE.UCP

_clear_opts(opt) = UInt32(opt) & ~(_VALID | _UTF | _UCP)

const comp_add   = (0%UInt32, _UCP, _UTF, _UCP|_UTF, _UTF|_VALID, _UCP|_UTF|_VALID)
const match_add  = (0%UInt32, 0%UInt32, 0%UInt32, 0%UInt32, _VALID, _VALID)

@noinline _check_compile(options) =
    (options & ~PCRE.COMPILE_MASK) == 0 ? UInt32(options) :
    throw(ArgumentError("invalid regex compile options: $options"))
@noinline _check_match(options) =
    (options & ~PCRE.MATCH_MASK) == 0 ? UInt32(options) :
    throw(ArgumentError("invalid regex match options: $options"))

function finalize! end

fin(exp) = finalizer(finalize!, exp) ; exp

# There are 18 valid combinations of size (8,16,32), UTF/no-UTF, possibly UCP, and NO_UTF_CHECK
# 
#  1 - Text1/Binary/ASCII   8
#  2 - Latin/_Latin         8,UCP
#  3                        8,UTF
#  4 - RawUTF8CSE           8,UCP,UTF
#  5                        8,UTF,NO_UTF_CHECK
#  6 - UTF8                 8,UCP,UTF,NO_UTF_CHECK

#  1 - Text2               16
#  2 - UCS2/_UCS2          16,UCP
#  3                       16,UTF
#  4 - RawUTF16CSE         16,UCP,UTF
#  5                       16,UTF,NO_UTF_CHECK
#  6 - UTF16               16,UCP,UTF,NO_UTF_CHECK

#  1 - Text4               32
#  2                       32,UCP
#  3                       32,UTF
#  4 - RawUTF32CSE         32,UCP,UTF
#  5                       32,UTF,NO_UTF_CHECK
#  6 - UTF32/_UTF32        32,UCP,UTF,NO_UTF_CHECK

opt_index(::Type{C}) where {C<:CSE} = 1
# opt_index(::Type{C}) where {C<:Union{ASCIICSE, BinaryCSE, Text1CSE, Text2CSE, Text4CSE}} = 1
opt_index(::Type{C}) where {C<:Union{LatinCSE, _LatinCSE, UCS2CSE, _UCS2CSE}} = 2
opt_index(::Type{C}) where {C<:Union{RawUTF8CSE, RawUTF16CSE}} = 4
opt_index(::Type{C}) where {C<:Union{UTF8CSE, UTF16CSE, UTF32CSE, _UTF32CSE}} = 6

opt_index(::Type{S}) where {S<:AbstractString} = opt_index(cse(S))

# Match tables only need to be allocated for each size (8,16,32) and for each thread
mutable struct MatchTab
    match_data::NTuple{3, Ptr{Cvoid}}
    ovec::NTuple{3, Vector{Csize_t}}
    MatchTab() = new((C_NULL, C_NULL, C_NULL), (Csize_t[], Csize_t[], Csize_t[]))
end

md_free(::Type{T}, md) where {T<:CodeUnitTypes} =
    md == C_NULL || PCRE.match_data_free(T, md)

function finalize!(mt::MatchTab)
    md_free(UInt8,  mt.match_data[1])
    md_free(UInt16, mt.match_data[2])
    md_free(UInt32, mt.match_data[3])
    mt.match_data = (C_NULL, C_NULL, C_NULL)
    mt.ovec = (Csize_t[], Csize_t[], Csize_t[])
end

const empty_table = (C_NULL, C_NULL, C_NULL, C_NULL, C_NULL, C_NULL)

mutable struct RegexStr
    pattern::String
    compile_options::UInt32
    match_options::UInt32
    negated_options::UInt32
    table::Vector{NTuple{6, Ptr{Cvoid}}}
    match::Vector{MatchTab}

    function RegexStr(pattern::AbstractString,
                      compile_options::Integer,
                      match_options::Integer,
                      negated_options::Integer=0)
        re = new(String(pattern),
                 _check_compile(compile_options),
                 _check_match(match_options),
                 _check_compile(negated_options),
                 [empty_table for i=1:3],
                 [MatchTab() for i=1:Threads.nthreads()])
        compile(cse(pattern), pattern, re)
        fin(re)
    end
end

const tabtype = (UInt8,UInt16,UInt32)

function _finalize!(re::RegexStr, i)
    tab = re.table[i]
    typ = tabtype[i]
    for j = 1:6
        (r = tab[j]) == C_NULL || PCRE.code_free(typ, r)
    end
    re.table[i] = empty_table
end

function finalize!(re::RegexStr)
    _finalize!(re, 1)
    _finalize!(re, 2)
    _finalize!(re, 3)
    for m in re.match
        finalize!(m)
    end
end

_update_match(t, v, n) =
    (n == 1 ? (v, t[2], t[3]) : n == 2 ? (t[1], v, t[3]) : (t[1], t[2], v))

_update_table(t, v, n) =
    (n == 1 ? v : t[1], n == 2 ? v : t[2], n == 3 ? v : t[3],
     n == 4 ? v : t[4], n == 5 ? v : t[5], n == 6 ? v : t[6])

const RegexTypes = Union{Regex, RegexStr}

@noinline _mode_err()     = throw(ArgumentError("a and u mode not allowed together"))
@noinline _unknown_err(f) = throw(ArgumentError("unknown regex flag: $f"))

function _add_compile_options(flags)
    negated = 0%UInt32
    options = DEFAULT_COMPILER_OPTS
    for f in flags
        if f == 'a'
            (options & PCRE.UCP) && _mode_err()
            negated |= PCRE.UCP
        elseif f == 'u'
            (negated & PCRE.UCP) && _mode_err()
            options |= PCRE.UCP
        elseif f == 'i' ; options |= PCRE.CASELESS
        elseif f == 'm' ; options |= PCRE.MULTILINE
        elseif f == 's' ; options |= PCRE.DOTALL
        elseif f == 'x' ; options |= PCRE.EXTENDED
        else
            _unknown_err(f)
        end
    end
    options, negated
end

RegexStr(pattern::AbstractString) =
    RegexStr(pattern, DEFAULT_COMPILER_OPTS, 0%UInt32, DEFAULT_MATCH_OPTS)
RegexStr(pattern::AbstractString, flags::AbstractString) =
    RegexStr(pattern, _add_compile_options(flags)..., DEFAULT_MATCH_OPTS)

@static if isdefined(Main, :LETS_BE_PIRATES) && Core.eval(Main, :LETS_BE_PIRATES)
    import Base.@r_str
    macro r_str(pattern::ANY, flags...) ; cmp_all(RegexStr(pattern, flags...)) ; end
    # Yes, this is type piracy, but it is needed to make all string types work together easily
    Base.Regex(pattern::AbstractString, co::Integer, mo::Integer, no::Integer=0) =
        RegexStr(pattern, co, mo, no)
    Base.Regex(pattern::AbstractString, flags::AbstractString) = RegexStr(pattern, flags)
    Base.Regex(pattern::AbstractString) = RegexStr(pattern)
else
    Regex(pattern::MaybeSub{<:Str}, co, mo, no=0) = RegexStr(pattern, co, mo, no)
    Regex(pattern::MaybeSub{<:Str}, flags::AbstractString) = RegexStr(pattern, flags)
    Regex(pattern::MaybeSub{<:Str}) = RegexStr(pattern)
end

function check_compile(::Type{C}, re::RegexStr) where {C<:CSE}
    try
        compile(C, re)
    catch ex
        (ex isa PCRE.PCRE2_Error && ex.errno in (134, 177)) || rethrow()
    end
end

"""Precompile all of the common cases needed for String, UTF8Str, UTF16Str, and UniStr"""
function cmp_all(re::RegexStr)
    pat = re.pattern
    is_bmp(pat)   && check_compile(UCS2CSE,  re)
    is_latin(pat) && check_compile(LatinCSE, re)
    if is_unicode(pat)
        check_compile(RawUTF8CSE, re)
        check_compile(UTF32CSE, re)
        check_compile(UTF16CSE, re)
        check_compile(UTF8CSE,  re)
    end
    is_ascii(pat) && check_compile(ASCIICSE, re)
    re
end

macro R_str(pattern, flags...) cmp_all(RegexStr(pattern, flags...)) end

function show(io::IO, re::RegexStr)
    imsx = PCRE.CASELESS|PCRE.MULTILINE|PCRE.DOTALL|PCRE.EXTENDED|PCRE.UCP
    opts = re.compile_options
    neg  = re.negated_options
    if (opts & ~imsx) == DEFAULT_COMPILER_OPTS || neg != 0
        print(io, 'R')
        Base.print_quoted_literal(io, re.pattern)
        (opts & PCRE.CASELESS ) == 0 || print(io, 'i')
        (opts & PCRE.MULTILINE) == 0 || print(io, 'm')
        (opts & PCRE.DOTALL   ) == 0 || print(io, 's')
        (opts & PCRE.EXTENDED ) == 0 || print(io, 'x')
        (opts & PCRE.UCP      ) == 0 || print(io, 'u')
        (neg  & PCRE.UCP      ) == 0 || print(io, 'a')
    else
        print(io, "RegexStr(")
        show(io, re.pattern)
        print(io, ',')
        show(io, opts)
        neg == 0 || print(io, "," , neg)
        print(io, ')')
    end
end

struct RegexStrMatch{T<:AbstractString}
    match::SubString{T}
    captures::Vector{Union{Nothing,SubString{T}}}
    offset::Int
    offsets::Vector{Int}
    regex::RegexStr
end

get_regex(re::RegexStrMatch{T}) where {T<:AbstractString} =
    (C = cse(T) ; re.regex.table[codeunit_index(codeunit(C))][opt_index(C)])
get_regex(re::RegexMatch) = re.regex.regex

function show(io::IO, m::RegexStrMatch{T}) where {T}
    print(io, "RegexStrMatch{$T}(")
    show(io, m.match)
    idx_to_capture_name = PCRE.capture_names(codeunit(T), get_regex(m))
    if !is_empty(m.captures)
        print(io, ", ")
        for i = 1:length(m.captures)
            # If the capture group is named, show the name.
            # Otherwise show its index.
            print(io, get(idx_to_capture_name, i, i), "=")
            show(io, m.captures[i])
            i < length(m.captures) && print(io, ", ")
        end
    end
    print(io, ")")
end

# Capture group extraction
getindex(m::RegexStrMatch, idx::Integer) = m.captures[idx]
function getindex(m::RegexStrMatch{T}, name::Symbol) where {T}
    idx = PCRE.substring_number_from_name(codeunit(T), get_regex(m), name)
    idx <= 0 && error("no capture group named $name found in regex")
    m[idx]
end

function outtab(tab)
    for rt in tab
        print(rt == C_NULL ? "0 " : "0x" * outhex(reinterpret(UInt, rt)) * " ")
    end
end

getindex(m::RegexStrMatch, name::AbstractString) = m[Symbol(name)]

get_comp_ind(opt) =
    ifelse((opt & _UTF) == 0, 1, ifelse((opt & _VALID) == 0, 3, 5)) + ((opt & _UCP) != 0)

function _make_match(CU, re, mt, cu_index)
    md = PCRE.match_data_create_from_pattern(CU, re, C_NULL)
    ov = PCRE.get_ovec(CU, md)
    mt.match_data = _update_match(mt.match_data, md, cu_index)
    mt.ovec       = _update_match(mt.ovec, ov, cu_index)
end

function compile(::Type{C}, pattern, regex::RegexStr) where {C<:Regex_CSEs}
    deb[] && println("compile(::Type{$C}, \"$pattern\", $regex)")
    CU = codeunit(C)
    cu_index = codeunit_index(CU)
    retab = regex.table[cu_index]
    cvtcomp = (regex.compile_options | comp_add[opt_index(C)]) & ~regex.negated_options
    ind = get_comp_ind(cvtcomp)
    # Get index based on actual options set
    re = retab[ind]
    if re == C_NULL
        pat = convert(Str{C,Nothing,Nothing,Nothing}, pattern)
        if PCRE.PCRE_LOCK === nothing
            re = PCRE.compile(pat, cvtcomp)
            deb[] && println("_update_table: ", cu_index, ", ", ind, ", ", retab, ", ", re)
            regex.table[cu_index] = _update_table(retab, re, ind)
            deb[] && println(" => ", regex.table[cu_index])
            PCRE.jit_compile(CU, re)
        else
            l = PCRE.PCRE_LOCK::Threads.SpinLock
            lock(l)
            try
                # Check again while locked if some other thread has compiled this
                if retab[ind] == C_NULL
                    re = PCRE.compile(pat, cvtcomp)
                    deb[] && println("_update_table: ", cu_index, ", ", ind, ", ", retab, ", ", re)
                    regex.table[cu_index] = _update_table(retab, re, ind)
                    deb[] && println(" => ", regex.table[cu_index])
                    PCRE.jit_compile(CU, re)
                end
            finally
                unlock(l)
            end
        end
    end
    tid = Threads.threadid()
    mt = regex.match[tid]
    mt.match_data[cu_index] == C_NULL || return regex
    if PCRE.PCRE_LOCK === nothing
        _make_match(CU, re, mt, cu_index)
    else
        l = PCRE.PCRE_LOCK::Threads.SpinLock
        lock(l)
        try
            # check again under lock
            mt.match_data[cu_index] == C_NULL && _make_match(CU, re, mt, cu_index)
        finally
            unlock(l)
        end
    end
    regex
end

compile(::Type{C}, regex::RegexStr) where {C<:Regex_CSEs} = compile(C, regex.pattern, regex)

function compile(::Type{C}, regex::Regex) where {C<:Regex_CSEs}
    ind = opt_index(C)
@static if BASE_REGEX_MT
    # Keep old match type in regex.extra (which doesn't seem to ever be used)
    oldind = reinterpret(UInt, regex.extra)%Int
    ind == oldind && return regex

    re = regex.regex
    regex.compile_options = cvtcomp = _clear_opts(regex.compile_options) | comp_add[ind]
    if oldind != 0
        S = tabtype[oldind]
        re == C_NULL || (PCRE.code_free(S, re); regex.regex = C_NULL)
    else
        S = Nothing
    end
    regex.regex = re = PCRE.compile(convert(Str{C,Nothing,Nothing,Nothing}, regex.pattern),
                                    cvtcomp)
    T = codeunit(C)
    PCRE.jit_compile(T, re)
    if S !== T
        S === Nothing || md_free(S, regex.match_data)
        regex.match_data = md = PCRE.match_data_create_from_pattern(T, re, C_NULL)
        regex.ovec = PCRE.get_ovec(T, md)
    end
    regex.extra = reinterpret(Ptr{Cvoid}, ind)
else
    cvtcomp = _clear_opts(regex.compile_options) | comp_add[ind]
    deb[] && println("ind = ", ind, ", old co = ", regex.compile_options, ", co = ", cvtcomp)
    regex
end
end

"""Get a thread-specific match context"""
function get_match_context(::Type{T}, tid) where {T<:CodeUnitTypes}
    cu_index = codeunit_index(T)
    if (mc = MATCH_CONTEXT[tid][cu_index]) == C_NULL
        mc = PCRE.match_context_create(T, C_NULL)
        js = PCRE.jit_stack_create(T, JIT_STACK_START_SIZE, JIT_STACK_MAX_SIZE, C_NULL)
        PCRE.jit_stack_assign(T, mc, C_NULL, js)
        MATCH_CONTEXT[tid] = _update_match(MATCH_CONTEXT[tid], mc, cu_index)
    end
    mc
end

_exec_err(rc) = error("StrRegex.exec error: $(PCRE.err_message(rc))")

function exec(C, re::RegexStr, subject, offset, options)
    deb[] && print("exec($re, \"$subject\", $offset, $options, match_data)")
    @preserve subject begin
        pnt = pointer(subject)
        siz = ncodeunits(subject)
        CU = eltype(pnt)
        0 <= offset <= siz || boundserr(subject, offset)
        tid = Threads.threadid()
        cu_index = codeunit_index(CU)
        tab = re.table[cu_index]
        cvtcomp = (re.compile_options | comp_add[opt_index(C)]) & ~re.negated_options
        ind = get_comp_ind(cvtcomp)
        deb[] && println(" => $tab, $ind")
        rc = PCRE.match(CU, tab[ind], pnt, siz, offset,
                        re.match_options | match_add[ind] | _check_match(options),
                        re.match[tid].match_data[cu_index], get_match_context(CU, tid))
        # rc == -1 means no match, -2 means partial match.
        #dump(re)
        rc < -2 && _exec_err(rc)
        rc >= 0
    end
end

function exec(C, re::Regex, subject, offset, options)
    @preserve subject begin
        pnt = pointer(subject)
        siz = ncodeunits(subject)
        T = eltype(pnt)
        #loc = bytoff(T, offset)
        0 <= offset <= siz || boundserr(subject, offset)
        opts = re.match_options | match_add[opt_index(C)] | _check_match(options)
        rc = PCRE.match(T, re.regex, pnt, siz, offset, opts, re.match_data,
                        get_match_context(T, Threads.threadid()))
        # rc == -1 means no match, -2 means partial match.
        rc < -2 && _exec_err(rc)
        rc >= 0
    end
end

comp_exec(C, re, subject, offset, options) = exec(C, compile(C, re), subject, offset, options)

get_range(ov, str, i = 0) = Int(ov[2*i+1]+1) : prevind(str, Int(ov[2*i+2]+1))

@static BASE_REGEX_MT || (get_ovec(::Type{<:Any}, re::Regex) = re.ovec)
get_ovec(::Type{T}, re::RegexStr) where {T<:CodeUnitTypes} =
     re.match[Threads.threadid()].ovec[codeunit_index(T)]
get_ovec(::Type{C}, re::RegexStr) where {C<:CSE} = get_ovec(codeunit(C), re)


function _match(::Type{C}, re, str, idx, opts) where {C<:CSE}
    comp_exec(C, re, str, idx - 1, opts) || return nothing
    ov = get_ovec(C, re)
    n = div(length(ov),2) - 1
    rng = get_range(ov, str)
    mat = SubString(str, rng)
    cap = Union{Nothing,SubString{typeof(str)}}[ov[2*i+1] == PCRE.UNSET ? nothing :
                                                SubString(str, get_range(ov, str, i)) for i=1:n]
    RegexStrMatch(mat, cap, rng.start, Int[ ov[2*i+1]+1 for i=1:n ], re)
end

regex_type_error(T, S) =
    throw(ArgumentError("$T matching is not supported for $S; use UniStr(s) to convert"))

match(re::Regex, str::MaybeSub{<:Str}, idx::Integer, add_opts=0) =
    regex_type_error(Regex, typeof(str))

match(re::Regex, str::MaybeSub{<:Str{<:Regex_CSEs}}, idx::Integer, add_opts::UInt32=UInt32(0)) =
    _match(basecse(str), re, str, Int(idx), add_opts)

match(r::RegexStr, str::AbstractString, idx::Integer, add_opts=0) =
    regex_type_error(RegexStr, typeof(str))

match(re::RegexStr, str::MaybeSub{<:Str}, idx::Integer, add_opts::UInt32=UInt32(0)) =
    _match(basecse(str), re, str, Int(idx), add_opts)

match(re::RegexStr, str::MaybeSub{String}, idx::Integer, add_opts::UInt32=UInt32(0)) =
    _match(RawUTF8CSE, re, str, Int(idx), add_opts)

match(re::Regex, str::MaybeSub{<:Str})   = match(re, str, 1)
match(re::RegexStr, str::AbstractString) = match(re, str, 1)

@inline __find(::Type{C}, re, str, idx) where {C} =
    comp_exec(C, re, str, idx, 0) ? get_range(get_ovec(C, re), str) : _not_found

@inline _find(::Type{C}, re, str) where {C} = __find(C, re, str, 0)

@inline _find(::Type{C}, re, str, idx) where {C} =
    (idx-1 <= ncodeunits(str)
     ? __find(C, re, str, idx-1)
     : (@boundscheck boundserr(str, idx) ; return _not_found))

find(::Type{Fwd}, re::RegexTypes, str::AbstractString, idx::Integer) =
    regex_type_error(typeof(re), typeof(str))

find(::Type{Fwd}, re::RegexTypes, str::MaybeSub{<:Str{C}}, idx::Integer) where {C<:Regex_CSEs} =
    _find(C, re, str, idx)
find(::Type{Fwd}, re::RegexTypes, str::MaybeSub{<:Str{_LatinCSE}}, idx::Integer) =
    _find(LatinCSE, re, str, idx)
find(::Type{Fwd}, re::RegexTypes, str::MaybeSub{String}, idx::Integer) =
    _find(RawUTF8CSE, re, str, idx)

find(::Type{First}, re::RegexTypes, str::AbstractString) = find(Fwd, re, str, 1)

find(::Type{First}, re::RegexTypes, str::MaybeSub{<:Str{C}}) where {C<:Regex_CSEs} =
    __find(C, re, str, 0)
find(::Type{First}, re::RegexTypes, str::MaybeSub{<:Str{_LatinCSE}}) =
    __find(LatinCSE, re, str, 0)
find(::Type{First}, re::RegexTypes, str::MaybeSub{String}) = 
    __find(RawUTF8CSE, re, str, 0)

# Borrow idea from @dalum on GitHub (sakse on Julia Discourse), PR #29790
starts_with(s::AbstractString, r::RegexStr) =
    comp_exec(UTF8CSE, r, UTF8Str(s), 0, PCRE.ANCHORED)
starts_with(s::MaybeSub{<:Str{C}}, r::RegexStr) where {C<:Regex_CSEs} =
    comp_exec(C, r, s, 0, PCRE.ANCHORED)
ends_with(s::AbstractString, r::RegexStr) =
    comp_exec(UTF8CSE, r, UTF8Str(s), 0, PCRE.ENDANCHORED)
ends_with(s::MaybeSub{<:Str{C}}, r::RegexStr) where {C<:Regex_CSEs} =
    comp_exec(C, r, s, 0, PCRE.ENDANCHORED)

function _write_capture(io, ::Type{C}, group::Integer, md) where {C<:CSE}
    T = codeunit(C)
    len = PCRE.sub_length_bynumber(T, md, group)
    buf, out = _allocate(T, len)
    PCRE.sub_copy_bynumber(T, md, group, out, len+1)
    print(io, Str(C, buf))
end

function Base._replace(io, repl_s::SubstitutionString,
                       str::T, r, re::RegexStr) where {T<:AbstractString}
    SUB_CHAR = '\\'
    GROUP_CHAR = 'g'
    LBRACKET = '<'
    RBRACKET = '>'
    tid = Threads.threadid()
    C = cse(T)
    CU = codeunit(C)
    cu_index = codeunit_index(CU)
    md = re.match[tid].match_data[cu_index]
    regex = re.table[cu_index][opt_index(C)]
    repl = repl_s.string
    pos = 1
    lst = lastindex(repl)
    # This needs to be careful with writes!
    while pos <= lst
        ch = repl[pos]
        if ch == SUB_CHAR
            nxt = nextind(repl, pos)
            nxt > lst && replace_err(repl)
            ch = repl[nxt]
            if ch == SUB_CHAR
                print(io, SUB_CHAR)
                pos = nextind(repl, nxt)
            elseif is_digit(ch)
                group = parse(Int, ch)
                pos = nextind(repl, nxt)
                while pos <= lst && (ch = repl[pos]; is_digit(ch))
                    group = 10 * group + parse(Int, ch)
                    pos = nextind(repl, pos)
                end
                _write_capture(io, C, group, md)
            elseif ch == GROUP_CHAR
                pos = nextind(repl, nxt)
                (pos > lst || repl[pos] != LBRACKET) && replace_err(repl)
                pos = nextind(repl, pos)
                pos > lst && replace_err(repl)
                groupstart = pos
                while repl[pos] != RBRACKET
                    pos = nextind(repl, pos)
                    pos > pos && replace_err(repl)
                end
                #  TODO: avoid this allocation
                groupname = SubString(repl, groupstart, prevind(repl, pos))
                if all(isdigit, groupname)
                    _write_capture(io, C, parse(Int, groupname), md)
                else
                    gn = convert(T, groupname)
                    group = PCRE.substring_number_from_name(CU, regex, gn)
                    group < 0 && replace_err("Group $groupname not found in regex $re")
                    _write_capture(io, C, group, md)
                end
                pos = nextind(repl, pos)
            else
                replace_err(repl)
            end
        else
            print(io, ch)
            pos = nextind(repl, pos)
        end
    end
end

struct RegexStrMatchIterator{T<:AbstractString}
    regex::RegexStr
    string::T
    overlap::Bool
end
RegexStrMatchIterator(r::RegexStr, s::AbstractString) = RegexStrMatchIterator(r, s, false)

compile(itr::RegexStrMatchIterator{T}) where {T} = (compile(cse(T), itr.regex); itr)
eltype(::Type{RegexStrMatchIterator{T}}) where {T} = RegexStrMatch{T}
firstindex(itr::RegexStrMatchIterator) = match(itr.regex, itr.string, 1, UInt32(0))
IteratorSize(::Type{RegexStrMatchIterator{T}}) where {T<:AbstractString} = Base.SizeUnknown()

function iterate(itr::RegexStrMatchIterator, (offset,prevempty)=(1,false))
    opts_nonempty = UInt32(PCRE.ANCHORED | PCRE.NOTEMPTY_ATSTART)
    while true
        mat = match(itr.regex, itr.string, offset, prevempty ? opts_nonempty : UInt32(0))

        if mat === nothing
            if prevempty && offset <= sizeof(itr.string)
                offset = nextind(itr.string, offset)
                prevempty = false
                continue
            else
                break
            end
        else
            if itr.overlap
                offset = isempty(mat.match) ? mat.offset : nextind(itr.string, mat.offset)
            else
                offset = mat.offset + ncodeunits(mat.match)
            end
            return (mat, (offset, isempty(mat.match)))
        end
    end
    nothing
end

eachmatch(re::RegexStr, str::AbstractString; overlap = false) =
    RegexStrMatchIterator(re, str, overlap)

const MS_Str    = MaybeSub{<:Str}
const MS_String = MaybeSub{String}

split(str::MS_Str, splitter::Regex;
      limit::Integer=0, keepempty::Bool=true, keep::Union{Nothing,Bool}=nothing) =
    __split(str, splitter, limit, checkkeep(keepempty, keep, :split), splitarr(str))
split(str::MS_Str, splitter::RegexStr;
      limit::Integer=0, keepempty::Bool=true, keep::Union{Nothing,Bool}=nothing) =
    __split(str, splitter, limit, checkkeep(keepempty, keep, :split), splitarr(str))
split(str::MS_String, splitter::RegexStr;
      limit::Integer=0, keepempty::Bool=true, keep::Union{Nothing,Bool}=nothing) =
    __split(str, splitter, limit, checkkeep(keepempty, keep, :split), splitarr(str))

rsplit(str::MS_Str, splitter::Regex;
      limit::Integer=0, keepempty::Bool=true, keep::Union{Nothing,Bool}=nothing) =
    __rsplit(str, splitter, limit, checkkeep(keepempty, keep, :rsplit), splitarr(str))
rsplit(str::MS_Str, splitter::RegexStr;
      limit::Integer=0, keepempty::Bool=true, keep::Union{Nothing,Bool}=nothing) =
    __rsplit(str, splitter, limit, checkkeep(keepempty, keep, :rsplit), splitarr(str))
rsplit(str::MS_String, splitter::RegexStr;
      limit::Integer=0, keepempty::Bool=true, keep::Union{Nothing,Bool}=nothing) =
    __rsplit(str, splitter, limit, checkkeep(keepempty, keep, :rsplit), splitarr(str))

replace(str::MS_Str, pat_repl::Pair{Regex}; count::Integer=typemax(Int)) =
    __replace(str, pat_repl; count=count)
replace(str::MS_Str, pat_repl::Pair{RegexStr}; count::Integer=typemax(Int)) =
    __replace(str, pat_repl; count=count)
replace(str::String, pat_repl::Pair{RegexStr}; count::Integer=typemax(Int)) =
    __replace(str, pat_repl; count=count)
replace(str::SubString{String}, pat_repl::Pair{RegexStr}; count::Integer=typemax(Int)) =
    __replace(str, pat_repl; count=count)

## comparison ##

==(a::RegexTypes, b::RegexTypes) =
    a.pattern == b.pattern &&
    a.compile_options == b.compile_options &&
    a.match_options == b.match_options

## hash ##
hash(r::RegexStr, h::UInt) =
    hash(r.match_options,
         hash(r.compile_options,
              hash(r.pattern, h + UInt === UInt64 ? 0x67e195eb8555e72d : 0xe32373e4)))

_occurs_in(r::RegexTypes, s::AbstractString, off::Integer) =
    comp_exec(UTF8CSE, r, UTF8Str(s), off, 0)
_occurs_in(r::RegexTypes, s::MaybeSub{<:Str{C}}, off::Integer) where {C<:Regex_CSEs} =
    comp_exec(C, r, s, off, 0)

occurs_in(needle::RegexStr, hay::AbstractString; off::Integer=0) = _occurs_in(needle, hay, off)
occurs_in(needle::Regex, hay::MaybeSub{<:Str}; off::Integer=0)   = _occurs_in(needle, hay, off)

@api freeze

end # module StrRegex
