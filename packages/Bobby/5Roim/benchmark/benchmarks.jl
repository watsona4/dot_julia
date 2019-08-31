using BenchmarkTools
using Bobby

const SUITE = BenchmarkGroup()

SUITE["bitboard"] = BenchmarkGroup()
SUITE["bitboard"]["buildBoard"] = @benchmarkable Bobby.buildBoard()
SUITE["bitboard"]["buildLookUpTables"] = @benchmarkable Bobby.buildLookUpTables()

SUITE["moves"] = BenchmarkGroup()
b = Bobby.buildBoard()
l = Bobby.buildLookUpTables()
for f in (Bobby.getKingValid, Bobby.getNightsValid, Bobby.getBishopsValid,
	Bobby.getQueenValid, Bobby.getPawnsValid)
    SUITE["moves"][string(f)[7:end]] = @benchmarkable $(f)(b, l)
end
SUITE["moves"]["getRooksValid"] = @benchmarkable Bobby.getRooksValid(b)

SUITE["check"] = BenchmarkGroup()
SUITE["check"]["checkCheck"] = @benchmarkable Bobby.checkCheck(b)