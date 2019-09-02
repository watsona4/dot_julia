# These types all shadow libogg datatypes, hence they are all immutable
struct OggSyncState
    # Pointer to buffered stream data
    data::Ptr{UInt8}
    # Current allocated size of the stream buffer held in *data
    storage::Cint
    # The number of valid bytes currently held in *data; functions as the buffer head pointer
    fill::Cint
    # The number of bytes at the head of *data that have already been returned as pages;
    # functions as the buffer tail pointer
    returned::Cint

    # Synchronization state flag; nonzero if sync has not yet been attained or has been lost
    unsynced::Cint
    # If synced, the number of bytes used by the synced page's header
    headerbytes::Cint
    # If synced, the number of bytes used by the synced page's body
    bodybytes::Cint

    # zero-constructor
    OggSyncState() = new(C_NULL, 0, 0, 0, 0, 0, 0)
end

function ogg_sync_destroy(sync::OggSyncState)
    ccall((:ogg_sync_destroy,libogg), Cint, (Ptr{OggSyncState},),sync)
end


struct OggPage
    # Pointer to the page header for this page
    header::Ptr{UInt8}
    # Length of the page header in bytes
    header_len::Clong
    # Pointer to the data for this page
    body::Ptr{UInt8}
    # Length of the body data in bytes
    body_len::Clong

    # zero-constructor
    OggPage() = new(C_NULL, 0, C_NULL, 0)
end

function read(page::OggPage)
    GC.@preserve page begin
        header_ptr = unsafe_wrap(Array, page.header, page.header_len)
        body_ptr = unsafe_wrap(Array, page.body, page.body_len)
        return vcat(header_ptr, body_ptr)
    end
end

function show(io::IO, x::OggPage)
    write(io, "OggPage ID: $(ogg_page_serialno(x)), length $(x.body_len) bytes")
end

# This const here so that we don't use ... syntax in new()
const oss_zero_header = tuple(zeros(UInt8, 282)...)
struct OggStreamState
    # Pointer to data from packet bodies
    body_data::Ptr{UInt8}
    # Storage allocated for bodies in bytes (filled or unfilled)
    body_storage::Clong
    # Amount of storage filled with stored packet bodies
    body_fill::Clong
    # Number of elements returned from storage
    body_returned::Clong

    # String of lacing values for the packet segments within the current page
    # Each value is a byte, indicating packet segment length
    lacing_vals::Ptr{Cint}
    # Pointer to the lacing values for the packet segments within the current page
    granule_vals::Int64
    # Total amount of storage (in bytes) allocated for storing lacing values
    lacing_storage::Clong
    # Fill marker for the current vs. total allocated storage of lacing values for the page
    lacing_fill::Clong
    # Lacing value for current packet segment
    lacing_packet::Clong
    # Number of lacing values returned from lacing_storage
    lacing_returned::Clong

    # Temporary storage for page header during encode process, while the header is being created
    header::NTuple{282,UInt8}
    # Fill marker for header storage allocation. Used during the header creation process
    header_fill::Cint

    # Marker set when the last packet of the logical bitstream has been buffered
    e_o_s::Cint
    # Marker set after we have written the first page in the logical bitstream
    b_o_s::Cint
    # Serial number of this logical bitstream
    serialno::Clong
    # Number of the current page within the stream
    pageno::Cint
    # Number of the current packet
    packetno::Int64
    # Exact position of decoding/encoding process
    granulepos::Int64

    # zero-constructor
    OggStreamState() = new(0,0,0,0,C_NULL,0,0,0,0,0,oss_zero_header,0,0,0,0,0,0,0)
end

function ogg_stream_destroy(stream::OggStreamState)
    ccall((:ogg_stream_destroy,libogg), Cint, (Ptr{OggStreamState},),stream)
end

struct OggPacket
    # Pointer to the packet's data. This is treated as an opaque type by the ogg layer
    packet::Ptr{UInt8}
    # Indicates the size of the packet data in bytes. Packets can be of arbitrary size
    bytes::Clong
    # Flag indicating whether this packet begins a logical bitstream
    # 1 indicates this is the first packet, 0 indicates any other position in the stream
    b_o_s::Clong
    # Flag indicating whether this packet ends a bitstream
    # 1 indicates the last packet, 0 indicates any other position in the stream
    e_o_s::Clong

    # A number indicating the position of this packet in the decoded data
    # This is the last sample, frame or other unit of information ('granule')
    # that can be completely decoded from this packet
    granulepos::Int64
    # Sequential number of this packet in the ogg bitstream
    packetno::Int64
end
# zero-constructor
OggPacket() = OggPacket(C_NULL, 0, 0, 0, 0, 0)

function show(io::IO, x::OggPacket)
    write(io,"OggPacket ID: $(x.packetno), length $(x.bytes) bytes")
end
