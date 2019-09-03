#Tools to help get a feel for Tr0
module Tr0Tools

#==Aliases
===============================================================================#
const DataWord = UInt32


#==Constants
===============================================================================#
const WRITEBLOCK_SYNCWORD = DataWord(0x4)


#==Main Types
===============================================================================#
struct BlockHeader
	_type::DataWord
	_size::DataWord
end


#==Helper Functions
===============================================================================#
function corruptword_exception(io::IO, w::DataWord, expected::DataWord)
	pos = position(io) - sizeof(DataWord)
	pos = hex(pos)
	w = hex(w)
	expected = hex(expected)
	return "Corrupt word @ 0x$pos: 0x$w, 0x$expected"
end

function readsyncword(io::IO)
	w = read(io, DataWord)
	if w != WRITEBLOCK_SYNCWORD
		throw(corruptword_exception(io, w, WRITEBLOCK_SYNCWORD))
	end
end

#Data read:
function _dread(io::IO, ::Type{BlockHeader})
	readsyncword(io)
	_type = read(io, DataWord)
	readsyncword(io)
	_size = read(io, DataWord)
	return BlockHeader(_type, _size)
end

function _show(io::IO, hdr::BlockHeader, pos::Int)
	print(io, "Block: 0x", hex(WRITEBLOCK_SYNCWORD))
	print(io, " 0x", hex(hdr._type))
	print(io, " 0x", hex(WRITEBLOCK_SYNCWORD))
	print(io, " 0x", hex(hdr._size))
	print(io, " (start 0x", hex(pos), ")")
	println(io)
end

#==Main functions
===============================================================================#
function dumpsegments(io::IO, filepath::String)
	r = open(filepath)
	blockcount = 0
	totalsize = 0

	while !eof(r)
		pos = position(r)
		hdr = _dread(r, BlockHeader)
			_show(io, hdr, pos)
			blockcount += 1
			totalsize += hdr._size

		seek(r, position(r)+hdr._size)
		blksize = read(r, DataWord)
		if blksize != hdr._size
			throw(corruptword_exception(r, blksize, hdr._size))
		end
	end

	close(r)
	println(io, "Blocks read: $blockcount, total size: $totalsize.")
end

dumpsegments(filepath::String) = dumpsegments(STDOUT, filepath)

end #module
