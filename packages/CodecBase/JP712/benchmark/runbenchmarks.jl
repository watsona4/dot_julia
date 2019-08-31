using CodecBase
using BenchmarkTools

# Make data.
data_bin = read(joinpath(@__DIR__, "data.bin"))
data16 = transcode(Base16Encoder(), data_bin)
data32 = transcode(Base32Encoder(), data_bin)
data64 = transcode(Base64Encoder(), data_bin)

# Define benchmarks.
suite = BenchmarkGroup()
suite["Base16"] = BenchmarkGroup()
suite["Base16"]["Encoder"] = @benchmarkable transcode(Base16Encoder(), data_bin)
suite["Base16"]["Decoder"] = @benchmarkable transcode(Base16Decoder(), data16)
suite["Base32"] = BenchmarkGroup()
suite["Base32"]["Encoder"] = @benchmarkable transcode(Base32Encoder(), data_bin)
suite["Base32"]["Decoder"] = @benchmarkable transcode(Base32Decoder(), data32)
suite["Base64"] = BenchmarkGroup()
suite["Base64"]["Encoder"] = @benchmarkable transcode(Base64Encoder(), data_bin)
suite["Base64"]["Decoder"] = @benchmarkable transcode(Base64Decoder(), data64)

# Run benchmarks and print the results.
tune!(suite)
results = run(suite, verbose=true, seconds=1)
for k1 in ["Base16", "Base32", "Base64"]
    for k2 in ["Encoder", "Decoder"]
        println("--- $(k1) $(k2) ---")
        show(STDOUT, MIME"text/plain"(), results[k1][k2])
        println()
        println()
    end
end
