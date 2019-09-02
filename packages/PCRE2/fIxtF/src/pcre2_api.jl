#=
Function declarations for PCRE2 library API

Copyright 2018 Gandalf Software, Inc., Scott P. Jones, and contributors to pcre2.h
(based on pcre2.h (copyright University of Cambridge), see PCRE2_LICENSE)
Licensed under MIT License, see LICENSE.md
=#

struct _UCHAR end

## Type definitions for PCRE bindings

const UCharP          = Ptr{_UCHAR} # This is really Ptr{UInt8},Ptr{UInt16},Ptr{UInt32}
const StrP            = UCharP
const VoidP           = Ptr{Cvoid}
const GeneralContextP = Ptr{Cvoid}
const CompileContextP = Ptr{Cvoid}
const MatchContextP   = Ptr{Cvoid}
const ConvertContextP = Ptr{Cvoid}
const MatchDataP      = Ptr{Cvoid}
const CodeP           = Ptr{Cvoid}
const JitStackP       = Ptr{Cvoid}
const SizeP           = Ptr{Csize_t}
const SizeRef         = Ref{Csize_t}
const MatchOptions    = UInt32
const CompileOptions  = UInt32

const funclist =
(
 (:config, Cint, (CONFIG, VoidP)),


## Functions for manipulating contexts

# GENERAL CONTEXT FUNCTIONS
 (:general_context_copy,      GeneralContextP, (GeneralContextP,)),
 #(:general_context_create, GeneralContextP,
 #    (VoidP (*)(Csize_t, VoidP), Cvoid (*)(VoidP, VoidP), VoidP)),
 (:general_context_free,      Cvoid,           (GeneralContextP,)),

# COMPILE CONTEXT FUNCTIONS
 (:compile_context_copy,      CompileContextP, (CompileContextP,)),
 (:compile_context_create,    CompileContextP, (GeneralContextP,)),
 (:compile_context_free,      Cvoid,           (CompileContextP,)),
 (:set_bsr,                   Cint,            (CompileContextP, UInt32)),
 (:set_character_tables,      Cint,            (CompileContextP, Ptr{UInt8})),
 (:set_compile_extra_options, Cint,            (CompileContextP, UInt32)),
 (:set_max_pattern_length,    Cint,            (CompileContextP, Csize_t)),
 (:set_newline,               Cint,            (CompileContextP, UInt32)),
 (:set_parens_nest_limit,     Cint,            (CompileContextP, UInt32)),
 #(:set_compile_recursion_guard, Cint, (CompileContextP, Cint (*)(UInt32, VoidP), VoidP)

# MATCH CONTEXT FUNCTIONS
 (:match_context_copy,        MatchContextP,   (MatchContextP,)),
 (:match_context_create,      MatchContextP,   (GeneralContextP,)),
 (:match_context_free,        Cvoid,           (MatchContextP,)),
 #(:set_callout, Cint, (MatchContextP, Cint (*)(callout_block *, VoidP), VoidP)),
 (:set_depth_limit,           Cint,            (MatchContextP, UInt32)),
 (:set_heap_limit,            Cint,            (MatchContextP, UInt32)),
 (:set_match_limit,           Cint,            (MatchContextP, UInt32)),
 (:set_offset_limit,          Cint,            (MatchContextP, Csize_t)),
 (:set_recursion_limit,       Cint,            (MatchContextP, UInt32)),
 #(:set_recursion_memory_management, Cint,
 # (MatchContextP, VoidP (*)(Csize_t, VoidP), Cvoid (*)(VoidP, VoidP), VoidP)),

# CONVERT CONTEXT FUNCTIONS
 (:convert_context_copy,      ConvertContextP, (ConvertContextP,)),
 (:convert_context_create,    ConvertContextP, (GeneralContextP,)),
 (:convert_context_free,      Cvoid,           (ConvertContextP,)),
 (:set_glob_escape,           Cint,            (ConvertContextP, UInt32)),
 (:set_glob_separator,        Cint,            (ConvertContextP, UInt32)),


## Functions concerned with compiling a pattern to PCRE internal code

# COMPILE FUNCTIONS
 (:compile, CodeP, (StrP, Csize_t, CompileOptions, Ref{Cint}, SizeRef, CompileContextP)),
 (:code_free,                 Cvoid,           (CodeP,)),
 (:code_copy,                 CodeP,           (CodeP,)),
 (:code_copy_with_tables,     CodeP,           (CodeP,)),

## Functions that give information about a compiled pattern

# PATTERN INFO FUNCTIONS
 (:pattern_info,              Cint,            (CodeP, INFO, VoidP)),
#(:callout_enumerate, Cint, (CodeP, Cint (*)(callout_enumerate_block *, VoidP), VoidP)),


## Functions for running a match and inspecting the result.

# MATCH FUNCTIONS
 (:match_data_create,          MatchDataP,     (UInt32, GeneralContextP)),
 (:match_data_create_from_pattern, MatchDataP, (CodeP, GeneralContextP)),
 (:dfa_match,                  Cint,
  (CodeP, StrP, Csize_t, Csize_t, MatchOptions, MatchDataP, MatchContextP, Ptr{Cint}, Csize_t)),
 (:match,                      Cint,
  (CodeP, StrP, Csize_t, Csize_t, MatchOptions, MatchDataP, MatchContextP)),
 (:match_data_free,            Cvoid,          (MatchDataP,)),
 (:get_mark,                   StrP,           (MatchDataP,)),
 (:get_ovector_count,          UInt32,         (MatchDataP,)),
 (:get_ovector_pointer,        SizeP,          (MatchDataP,)),
 (:get_startchar,              Csize_t,        (MatchDataP,)),


## Convenience functions for handling matched substrings

# SUBSTRING FUNCTIONS
 (:substring_copy_byname,      Cint,           (MatchDataP, StrP, UCharP, SizeRef)),
 (:substring_copy_bynumber,    Cint,           (MatchDataP, UInt32, UCharP, SizeRef)),
 (:substring_free,             Cvoid,          (UCharP,)),
 (:substring_get_byname,       Cint,           (MatchDataP, StrP, Ref{UCharP}, SizeRef)),
 (:substring_get_bynumber,     Cint,           (MatchDataP, UInt32, Ref{UCharP}, SizeRef)),
 (:substring_length_byname,    Cint,           (MatchDataP, StrP, SizeRef)),
 (:substring_length_bynumber,  Cint,           (MatchDataP, UInt32, SizeRef)),
 (:substring_nametable_scan,   Cint,           (CodeP, StrP, Ptr{StrP}, Ptr{StrP})),
 (:substring_number_from_name, Cint,           (CodeP, StrP)),
 (:substring_list_free,        Cvoid,          (Ptr{StrP},)),
 (:substring_list_get,         Cint,           (MatchDataP, Ptr{Ptr{UCharP}}, Ptr{SizeP})),


## Functions for serializing / deserializing compiled patterns

# SERIALIZE FUNCTIONS
 (:serialize_encode,           Int32,
    (Ptr{CodeP}, Int32, Ptr{Ptr{UInt8}}, SizeP, GeneralContextP)),
 (:serialize_decode,           Int32,          (Ptr{CodeP}, Int32, Ptr{UInt8}, GeneralContextP)),
 (:serialize_get_number_of_codes, Int32,       (Ptr{UInt8},)),
 (:serialize_free,             Cvoid,          (Ptr{UInt8},)),


## Convenience function for match + substitute.

 (:substitute,                 Cint,
    (CodeP, StrP, Csize_t, Csize_t, MatchOptions, MatchDataP, MatchContextP,
     StrP, Csize_t, UCharP, SizeP)),


## Functions for converting pattern source strings

# CONVERT FUNCTIONS
 (:pattern_convert,            Cint, (StrP, Csize_t, UInt32, Ptr{UCharP}, SizeP, ConvertContextP)),
 (:converted_pattern_free,     Cvoid,          (UCharP,)),


## Functions for JIT processing

# JIT FUNCTIONS
 (:jit_compile,                Cint,           (CodeP, UInt32)),
 (:jit_match,                  Cint,
    (CodeP, StrP, Csize_t, Csize_t, UInt32, MatchDataP, MatchContextP)),
 (:jit_free_unused_memory,     Cvoid,          (GeneralContextP,)),
 (:jit_stack_create,           JitStackP,      (Csize_t, Csize_t, GeneralContextP)),
 (:jit_stack_assign,           Cvoid,          (MatchContextP, VoidP, VoidP)), # jit_callback
 (:jit_stack_free,             Cvoid,          (JitStackP,)),


## Other miscellaneous functions

 (:get_error_message,          Cint,           (Cint, UCharP, Csize_t)),
 (:maketables,                 Ptr{UInt8},     (GeneralContextP,))
)
