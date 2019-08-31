using Test
using BracedErrors
import BracedErrors: ±

@testset "bracederror" begin
	@testset "dec = 2" begin
		@test bracederror(123.456, 0.12345) == "123.46(13)"
		@test bracederror(123.456, 0.0012345) == "123.4560(13)"
		@test bracederror(123.456, 0.00012345) == "123.45600(13)"
	end

	@testset "negative" begin
		@test bracederror(-123.456, 0.12345) == "-123.46(13)"
		@test bracederror(-123.456, 0.0012345) == "-123.4560(13)"
		@test bracederror(-123.456, 340.00012345) == "-123(350)"
	end

	@testset "dec = 3" begin
		@test bracederror(123.456, 0.12345; dec=3) == "123.456(124)"
		@test bracederror(123.456, 0.0012345; dec=3) == "123.45600(124)"
		@test bracederror(123.456, 0.00012345; dec=3) == "123.456000(124)"
	end

	@testset "error bigger than value" begin
		@test bracederror(123.456, 123.45) == "123(130)"
		@test bracederror(123.456, 123456) == "123(130000)"
		@test bracederror(123e8, 123456e8) == "12300000000(13000000000000)"

		@test bracederror(123.456, 123.45; dec = 4) == "123.5(1235)"
		@test bracederror(123.456, 123456; dec = 4) == "123.5(1235000)"
		@test bracederror(123e8, 123456e8; dec = 4) == "12300000000(12350000000000)"
	end

	@testset "two errors" begin
		@testset "small errors" begin
	@test bracederror(123.456, 0.12345, 0.567) == "123.46(13)(57)"
	@test bracederror(123.456, 0.0012345, 78.9) == "123.4560(13)(790000)"
	@test bracederror(123.456, 12, 0.00356) == "123.4560(120000)(36)"
		end

		@testset "big errors" begin
	@test bracederror(123.456, 1234, 0.567) == "123.46(130000)(57)"
	@test bracederror(123.456, 7778, 345) == "123(7800)(350)"
	@test bracederror(1e-3, 12, 0.356) == "0.0010(120000)(3600)"
		end
	end

	@testset "at edge" begin
	@test bracederror(10.0, 1.0) == "10.0(10)"
	@test bracederror(10.0, 0.999) == "10.0(10)"
	@test bracederror(10.0, 0.999, 1.0) == "10.0(10)(10)"
	@test bracederror(10.0, 0.999, 0.344) == "10.00(100)(35)"
	end

	@testset "with e notation" begin
	@test bracederror(234.567e68, 34.6e68) == "23456700000000000000000000000000000000000000000000000000000000000000000(3500000000000000000000000000000000000000000000000000000000000000000000)"
	end

	@testset "styles" begin
		@test bracederror(123.456, 0.345; bracket = :s) == "123.46[35]"
		@test bracederror(123.456, 0.345; bracket = :q, delim = ",") == "123,46{35}"
		@test bracederror(123.456, 0.345; bracket = :a) == "123.46<35>"
		@test bracederror(123.456, 0.345; suff = "_\\inf") == "123.46(35)_\\inf"
	end

	@testset "± infix operator" begin
		@test 0.234 ± 0.00056 == "0.23400(56)"
		@test 0.234 ± (0.00056, 0.45) == "0.23400(56)(45000)"
		@test ±(0.234, 0.00056, 0.45; bracket =(:r, :s)) == "0.23400(56)[45000]"
	end
end
