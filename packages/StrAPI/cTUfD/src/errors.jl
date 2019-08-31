"""
Based partly on code in LegacyStrings that used to be part of Julia
Licensed under MIT License, see LICENSE.md

(Written by Scott P. Jones in series of PRs contributed to the Julia project in 2015)
"""
module StrErrors

## Error messages for Unicode / UTF support

const SHORT =
  "invalid UTF-8 sequence starting at index <<1>> (0x<<2>>) missing one or more continuation bytes"
const CONT =
  "invalid UTF-8 sequence starting at index <<1>> (0x<<2>>) is not a continuation byte"
const LONG =
  "invalid UTF-8 sequence, overlong encoding starting at index <<1>> (0x<<2>>)"
const NOT_LEAD =
  "not a leading Unicode surrogate code unit at index <<1>> (0x<<2>>)"
const NOT_TRAIL =
  "not a trailing Unicode surrogate code unit at index <<1>> (0x<<2>>)"
const NOT_SURROGATE =
  "not a valid Unicode surrogate code unit at index <<1>> (0x<<2>>)"
const MISSING_SURROGATE =
  "missing trailing Unicode surrogate code unit after index <<1>> (0x<<2>>)"
const INVALID =
  "invalid Unicode character starting at index <<1>> (0x<<2>> > 0x10ffff)"
const SURROGATE =
  "surrogate encoding not allowed in UTF-8 or UTF-32, at index <<1>> (0x<<2>>)"
const ODD_BYTES_16 =
  "UTF16String can't have odd number of bytes <<1>>"
const ODD_BYTES_32 =
  "UTF32String must have multiple of 4 bytes <<1>>"
const INVALID_ASCII =
  "invalid ASCII character at index <<1>> (0x<<2>> > 0x7f)"
const INVALID_LATIN1 =
  "invalid Latin1 character at index <<1>> (0x<<2>> > 0xff)"
const INVALID_CHAR =
  "invalid Unicode character (0x<<2>> > 0x10ffff)"
const INVALID_8 =
  "invalid UTF-8 data"
const INVALID_16 =
  "invalid UTF-16 data"
const INVALID_UCS2 =
  "invalid UCS-2 character (surrogate present)"
const INVALID_INDEX =
  "invalid character index <<1>>"
const DECOMPOSE_COMPOSE =
  "only one of decompose or compose may be true"
const COMPAT_STRIPMARK =
  "compat or stripmark true requires compose or decompose true"
const NL_CONVERSION =
  "only one newline conversion may be specified"
const NORMALIZE =
  " is not one of :NFC, :NFD, :NFKC, :NFKD"

end # module StrErrors

@static if isdefined(Base, :UnicodeError)
const StringError = UnicodeError
else

struct StringError <: Exception
    errmsg::String           # Error message
    errpos::Int32            # Position of invalid character
    errchr::UInt32           # Invalid character
    StringError(msg, pos, chr) = new(msg, pos%Int32, chr%UInt32)
end

_repmsg(msg, pos, chr) =
    replace(replace(msg, "<<1>>" => string(pos)), "<<2>>" =>  outhex(chr))
Base.show(io::IO, exc::StringError) =
    print(io, "StringError: ", _repmsg(exc.errmsg, exc.errpos, exc.errchr))
end
(::Type{StringError})(msg, pos=0%Int32) = StringError(msg, pos%Int32, 0%UInt32)

@noinline boundserr(s, pos)      = throw(BoundsError(s, pos))
@noinline strerror(err)          = throw(StringError(err))
@noinline strerror(err, pos, ch) = throw(StringError(err, pos, ch))
@noinline strerror(err, v)       = strerror(string(":", v, err))
@noinline nulerr()               = strerror("cannot convert NULL to string")
@noinline neginderr(s, n)        = strerror("Index ($n) must be non negative")
@noinline codepoint_error(T, v)  = strerror(string("Invalid CodePoint: ", T, " 0x", outhex(v)))
@noinline argerror(startpos, endpos) =
    strerror(string("End position ", endpos, " is less than start position (", startpos, ")"))

@noinline ascii_err()    = throw(ArgumentError("Not a valid ASCII string"))
@noinline ncharerr(n)    = throw(ArgumentError(string("nchar (", n, ") must be not be negative")))
@noinline repeaterr(cnt) = throw(ArgumentError("repeat count $cnt must be >= 0"))

@static isdefined(Base, :string_index_err) && (const index_error = Base.string_index_err)
