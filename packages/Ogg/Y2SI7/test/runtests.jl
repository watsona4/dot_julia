using Ogg
using Compat.Test

@testset "Ogg synthesis/analysis" begin
    # Let's start with building our own Ogg structure, writing it out to an IOBuf,
    # then loading it back in again and checking everything about it we can think of

    # We are going to build three streams, each with 10 packets
    num_packets = 10
    stream_ids = Cint[1, 2, 3]
    packets = Dict{Clong,Vector{Vector{UInt8}}}()
    granulepos = Dict{Int64,Vector{Int64}}()
    for serial in stream_ids
        # The packets are all of different size
        packets[serial] = Vector{UInt8}[UInt8.(mod.(collect(1:100*x), 256)) for x in 1:num_packets]

        # Each packet will have a monotonically increasing granulepos, except for
        # the first two packets which are our "header" packets with granulepos == 0
        granulepos[serial] = Int64[0, 0, [20*x for x in 1:(num_packets - 2)]...]
    end

    # Now we write these packets out to an IOBuffer
    ogg_file = IOBuffer()
    save(ogg_file, packets, granulepos)

    # Rewind to the beginning of this IOBuffer and load the packets back in
    seekstart(ogg_file)

    # This is the verbose way to load an Ogg file that leaves the decoder object
    # around for us to inspect; the load() function returns only `dec.packets`
    dec = OggDecoder()
    Ogg.decode_all_pages(dec, ogg_file)
    Ogg.decode_all_packets(dec, ogg_file)

    # # Are the serial numbers the same?
    @test sort(collect(keys(dec.packets))) == sort(stream_ids)

    # Are the number of packets the same?
    for serial in stream_ids
        @test length(dec.packets[serial]) == length(packets[serial])
    end

    # Are the contents of the packets the same?
    for serial in stream_ids
        for packet_idx in 1:length(dec.packets[serial])
            @test dec.packets[serial][packet_idx] == packets[serial][packet_idx]
        end
    end

    # Let's dig deeper; let's ensure that the first two pages had length equal to
    # our first two packets, proving that our header packets had their own pages:
    for serial in stream_ids
        @test dec.pages[serial][1].body_len == length(packets[serial][1])
        @test dec.pages[serial][2].body_len == length(packets[serial][2])
    end
end


# Next, let's load a known ogg stream and ensure that it's exactly as we expect
@testset "Known .ogg decoding" begin
    testdir = dirname(@__FILE__)
    ogg_packets = load(joinpath(testdir, "zero.ogg"))

    # There is only one stream, and we know its serial number
    @test collect(keys(ogg_packets)) == [1238561138]
    serial = first(keys(ogg_packets))

    # There are four packets, the first starts with \x7fFLAC
    @test length(ogg_packets[serial]) == 4
    @test String(copy(ogg_packets[serial][1][2:5])) == "FLAC"

    # The lengths of the packets are:
    @test [length(x) for x in ogg_packets[serial]] == [51, 55, 13, 0]
end
