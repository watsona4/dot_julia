__precompile__(true)
"""
Support for Character Sets, Encodings, and Character Set Encodings

Copyright 2017-2018 Gandalf Software, Inc., Scott P. Jones
Licensed under MIT License, see LICENSE.md
"""
module CharSetEncodings

using ModuleInterfaceTools

@api extend! StrAPI

# Define symbols used for characters, codesets, codepoints

const cse_info =
    ((:Binary,   UInt8),		# really, no character set at all, not text
     (:Text1,    UInt8),        	# Unknown character set, 1 byte
     (:ASCII,    UInt8),		# (7-bit subset of Unicode)
     (:Latin,    UInt8),		# ISO-8859-1 (8-bit subset of Unicode)
     (:_Latin,   UInt8),		# Latin subset of Unicode (0-0xff)
     (:UTF8,     UInt8,  :UTF32),	# Validated UTF-8
     (:RawUTF8,  UInt8,  :UniPlus),	# Unvalidated UTF-8
     (:Text2,    UInt16),		# Unknown character set, 2 byte
     (:UCS2,     UInt16),		# BMP (16-bit subset of Unicode)
     (:_UCS2,    UInt16),		# UCS-2 Subset of Unicode (0-0xd7ff, 0xe000-0xffff)
     (:UTF16,    UInt16, :UTF32),	# Validated UTF-16
     (:RawUTF16, UInt16, :UniPlus),	# Unvalidated UTF-16
     (:Text4,    UInt32),		# Unknown character set, 4 byte
     (:UTF32,    UInt32),		# corresponding to codepoints (0-0xd7ff, 0xe000-0x10fff)
     (:_UTF32,   UInt32))		# Full validated UTF-32

@api develop cse_info

include("charsets.jl")
include("encodings.jl")
include("cses.jl")
include("traits.jl")

@api freeze

end # module CharSetEncodings
