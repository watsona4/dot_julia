#=
Constants for PCRE2 library API

Copyright 2018 Gandalf Software, Inc., Scott P. Jones, and contributors to pcre2.h
(based on pcre2.h (copyright University of Cambridge), see PCRE2_LICENSE)
Licensed under MIT License, see LICENSE.md
=#

# The following option bits can be passed to pcre2_compile(), pcre2_match(), or pcre2_dfa_match().
# PCRE2_NO_UTF_CHECK affects only the function to which it is passed. Put these bits at the most
# significant end of the options word so others can be added next to them

const ANCHORED            = 0x80000000
const NO_UTF_CHECK        = 0x40000000
const ENDANCHORED         = 0x20000000

# The following option bits can be passed only to pcre2_compile().
# However, they may affect compilation, JIT compilation, and/or interpretive execution.
# The following tags indicate which:

# C   alters what is compiled by pcre2_compile()
# J   alters what is compiled by pcre2_jit_compile()
# M   is inspected during pcre2_match() execution
# D   is inspected during pcre2_dfa_match() execution

const ALLOW_EMPTY_CLASS   = 0x00000001  # C
const ALT_BSUX            = 0x00000002  # C
const AUTO_CALLOUT        = 0x00000004  # C
const CASELESS            = 0x00000008  # C
const DOLLAR_ENDONLY      = 0x00000010  #   J M D
const DOTALL              = 0x00000020  # C
const DUPNAMES            = 0x00000040  # C
const EXTENDED            = 0x00000080  # C
const FIRSTLINE           = 0x00000100  #   J M D
const MATCH_UNSET_BACKREF = 0x00000200  # C J M
const MULTILINE           = 0x00000400  # C
const NEVER_UCP           = 0x00000800  # C
const NEVER_UTF           = 0x00001000  # C
const NO_AUTO_CAPTURE     = 0x00002000  # C
const NO_AUTO_POSSESS     = 0x00004000  # C
const NO_DOTSTAR_ANCHOR   = 0x00008000  # C
const NO_START_OPTIMIZE   = 0x00010000  #   J M D
const UCP                 = 0x00020000  # C J M D
const UNGREEDY            = 0x00040000  # C
const UTF                 = 0x00080000  # C J M D
const NEVER_BACKSLASH_C   = 0x00100000  # C
const ALT_CIRCUMFLEX      = 0x00200000  #   J M D
const ALT_VERBNAMES       = 0x00400000  # C
const USE_OFFSET_LIMIT    = 0x00800000  #   J M D
const EXTENDED_MORE       = 0x01000000  # C
const LITERAL             = 0x02000000  # C

## An additional compile options word is available in the compile context.

const EXTRA_ALLOW_SURROGATE_ESCAPES  = 0x00000001  # C
const EXTRA_BAD_ESCAPE_IS_LITERAL    = 0x00000002  # C
const EXTRA_MATCH_WORD               = 0x00000004  # C
const EXTRA_MATCH_LINE               = 0x00000008  # C

## These are for pcre2_jit_compile().

const JIT_COMPLETE        = 0x00000001  # For full matching */
const JIT_PARTIAL_SOFT    = 0x00000002
const JIT_PARTIAL_HARD    = 0x00000004

## These are for pcre2_match(), pcre2_dfa_match(), and pcre2_jit_match().
## Note that PCRE2_ANCHORED and PCRE2_NO_UTF_CHECK can also be passed to these functions
## (though pcre2_jit_match() ignores the latter since it bypasses all sanity checks).

const NOTBOL              = 0x00000001
const NOTEOL              = 0x00000002
const NOTEMPTY            = 0x00000004  # ) These two must be kept
const NOTEMPTY_ATSTART    = 0x00000008  # ) adjacent to each other
const PARTIAL_SOFT        = 0x00000010
const PARTIAL_HARD        = 0x00000020

## These are additional options for pcre2_dfa_match()

const DFA_RESTART         = 0x00000040
const DFA_SHORTEST        = 0x00000080

## These are additional options for substitute(), which passes any others through to match()

const SUBSTITUTE_GLOBAL           = 0x00000100
const SUBSTITUTE_EXTENDED         = 0x00000200
const SUBSTITUTE_UNSET_EMPTY      = 0x00000400
const SUBSTITUTE_UNKNOWN_UNSET    = 0x00000800
const SUBSTITUTE_OVERFLOW_LENGTH  = 0x00001000

## A further option for match(), not allowed for dfa_match(), ignored for jit_match()

const NO_JIT              = 0x00002000

## Options for pattern_convert()

const CONVERT_UTF                    = 0x00000001
const CONVERT_NO_UTF_CHECK           = 0x00000002
const CONVERT_POSIX_BASIC            = 0x00000004
const CONVERT_POSIX_EXTENDED         = 0x00000008
const CONVERT_GLOB                   = 0x00000010
const CONVERT_GLOB_NO_WILD_SEPARATOR = 0x00000030
const CONVERT_GLOB_NO_STARSTAR       = 0x00000050

## Newline and \R settings, for use in compile contexts. The newline values must be kept in step
## with values set in config.h and both sets must all be greater than zero.

const NEWLINE_CR          = 1
const NEWLINE_LF          = 2
const NEWLINE_CRLF        = 3
const NEWLINE_ANY         = 4
const NEWLINE_ANYCRLF     = 5
const NEWLINE_NUL         = 6

const BSR_UNICODE         = 1
const BSR_ANYCRLF         = 2

## Request types for pattern_info()

@enum(INFO::Int32,
      INFO_ALLOPTIONS = 0,
      INFO_ARGOPTIONS,
      INFO_BACKREFMAX,
      INFO_BSR,
      INFO_CAPTURECOUNT,
      INFO_FIRSTCODEUNIT,
      INFO_FIRSTCODETYPE,
      INFO_FIRSTBITMAP,
      INFO_HASCRORLF,
      INFO_JCHANGED,
      INFO_JITSIZE,
      INFO_LASTCODEUNIT,
      INFO_LASTCODETYPE,
      INFO_MATCHEMPTY,
      INFO_MATCHLIMIT,
      INFO_MAXLOOKBEHIND,
      INFO_MINLENGTH,
      INFO_NAMECOUNT,
      INFO_NAMEENTRYSIZE,
      INFO_NAMETABLE,
      INFO_NEWLINE,
      INFO_DEPTHLIMIT,
      INFO_SIZE,
      INFO_HASBACKSLASHC,
      INFO_FRAMESIZE,
      INFO_HEAPLIMIT,
      INFO_EXTRAOPTIONS)

## Request types for config()

@enum(CONFIG::Int32,
      CONFIG_BSR = 0,
      CONFIG_JIT,
      CONFIG_JITTARGET,
      CONFIG_LINKSIZE,
      CONFIG_MATCHLIMIT,
      CONFIG_NEWLINE,
      CONFIG_PARENSLIMIT,
      CONFIG_DEPTHLIMIT,
      CONFIG_STACKRECURSE,  # Obsolete
      CONFIG_UNICODE,
      CONFIG_UNICODE_VERSION,
      CONFIG_VERSION,
      CONFIG_HEAPLIMIT,
      CONFIG_NEVER_BACKSLASH_C,
      CONFIG_COMPILED_WIDTHS)


# supported options for different use cases

const NL_MASK =
    NEWLINE_ANY | NEWLINE_ANYCRLF | NEWLINE_CR | NEWLINE_CRLF | NEWLINE_LF

const COMMON_MASK = ANCHORED | ENDANCHORED | NO_UTF_CHECK

const COMPILE_MASK =
    (COMMON_MASK
     | ALLOW_EMPTY_CLASS
     | ALT_BSUX
     | AUTO_CALLOUT
     | CASELESS
     | DOLLAR_ENDONLY
     | DOTALL
     | DUPNAMES
     | EXTENDED
     | FIRSTLINE
     | MATCH_UNSET_BACKREF
     | MULTILINE
     | NEVER_UCP
     | NEVER_UTF
     | NO_AUTO_CAPTURE
     | NO_AUTO_POSSESS
     | NO_DOTSTAR_ANCHOR
     | NO_START_OPTIMIZE
     | UCP
     | UNGREEDY
     | UTF
     | NEVER_BACKSLASH_C
     | ALT_CIRCUMFLEX
     | ALT_VERBNAMES
     | USE_OFFSET_LIMIT
     | EXTENDED_MORE
     | LITERAL
     )

const MATCH_MASK =
    (COMMON_MASK
     | NOTBOL
     | NOTEOL
     | NOTEMPTY
     | NOTEMPTY_ATSTART
     | PARTIAL_HARD
     | PARTIAL_SOFT
     )
