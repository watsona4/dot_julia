#Pseudo-Random Bit Sequence Tests

@testset "PRBS Tests" begin #Scope for test data

_DEBUG = false

#Dumps contents of a bit sequence vector for debugging purposes:
function dbg_dumpseq(prefix, seq)
	if !_DEBUG; return; end
	print(prefix)
	for bit in seq
		if bit > 0
			print("1")
		else
			print("0")
		end
	end
	println()
end

@testset "Cyclical tests: MaxLFSR" begin
	for prbslen in 3:15 #Don't perform tests on higher-order patterns (too much time/memory)
		patlen = (2^prbslen) - 1
		genlen = patlen + prbslen #Full pattern length + "internal register length"
		regmask = (Int64(1)<<prbslen) -1 #Mask out "non-register" bits
		seed = rand(Int64) & regmask
		pattern = collect(sequence(MaxLFSR(prbslen), seed=seed, len=genlen, output=Int))

		#Make sure pattern repeats for at least as many bits as are in internal register:
		mismatch = pattern[(1:prbslen)] .!= pattern[patlen .+ (1:prbslen)]
		@test sum(convert(Vector{Int}, mismatch)) == 0

		#@show prbslen, pattern[1:prbslen], pattern[patlen .+ (1:prbslen)]
	end
end

@testset "Error detection: MaxLFSR" begin
	#TODO: Compare algorithm against known good pattern (if one can be found).
	prbslen = 15; seed = 11; len = 50
	pattern = collect(sequence(MaxLFSR(prbslen), seed=seed, len=len, output=Int))
	_errors = sequence_detecterrors(MaxLFSR(prbslen), pattern)

	dbg_dumpseq("_errors = ", _errors) #DEBUG
	@test sum(_errors) == 0

	#Test with error injected:
	pattern[prbslen+5] = 1 - pattern[prbslen+5] #Flip "bit"
	_errors = sequence_detecterrors(MaxLFSR(prbslen), pattern)

	dbg_dumpseq("_errors = ", _errors) #DEBUG
	@test sum(_errors) == 1 #Should have a single error
end


end #PRBS Tests

#Last line
