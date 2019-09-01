using Random

const SEED = 999
const NROWS = 128
const N_IDX_TESTS = 16

arrow_tempname = tempname()
push!(temps, arrow_tempname)

Random.seed!(SEED)

randdate() = Date(rand(0:4000), rand(1:12), rand(1:27))
randtime() = Dates.Time(rand(0:23), rand(0:59), rand(0:59))
randdatetime() = randdate() + randtime()

randstrings() = String[[randstring(rand(0:20)) for i ∈ 1:(NROWS-1)]; "a"]
function randstrings(::Missing)
    Union{String,Missing}[[rand(Bool) ? missing : randstring(rand(0:20)) for i ∈ 1:(NROWS-1)]; "a"]
end

convstring(str::AbstractString) = String(str)
convstring(::Missing) = missing

@testset "ArrowTests" begin

cols = [rand(Int32,NROWS),
    rand(Float64,NROWS),
    Date[randdate() for i ∈ 1:NROWS],
    DateTime[randdatetime() for i ∈ 1:NROWS],
    Dates.Time[randtime() for i ∈ 1:NROWS],
    Union{Int64,Missing}[rand(Bool) ? missing : rand(Int64) for i ∈ 1:NROWS],
    randstrings(),
    randstrings(missing),
    CategoricalArrays.categorical(randstrings()),
    CategoricalArrays.categorical(randstrings(missing))]

colnames = [:ints,:floats,:dates,:datetimes,:times,:missingints,:strings,
    :missingstrings,:catstrings,:catstringsmissing]

featherwrite(arrow_tempname, cols, colnames)

ndf = featherread(arrow_tempname)

@test ndf.names == colnames

@test typeof(ndf.columns[1]) == Arrow.Primitive{Int32}
@test typeof(ndf.columns[2]) == Arrow.Primitive{Float64}
@test typeof(ndf.columns[3]) == Arrow.Primitive{Arrow.Datestamp}
@test typeof(ndf.columns[4]) == Arrow.Primitive{Arrow.Timestamp{Dates.Millisecond}}
@test typeof(ndf.columns[5]) == Arrow.Primitive{Arrow.TimeOfDay{Dates.Nanosecond,Int64}}
@test typeof(ndf.columns[6]) == Arrow.NullablePrimitive{Int64}
@test typeof(ndf.columns[7]) == Arrow.List{String,Arrow.DefaultOffset,Arrow.Primitive{UInt8}}
@test typeof(ndf.columns[8]) == Arrow.NullableList{String,Arrow.DefaultOffset,Arrow.Primitive{UInt8}}
@test typeof(ndf.columns[9]) == Arrow.DictEncoding{String,Arrow.Primitive{Int32},
    Arrow.List{String,Arrow.DefaultOffset,Arrow.Primitive{UInt8}}}
@test typeof(ndf.columns[10]) ==
        Arrow.DictEncoding{Union{String,Missing},Arrow.NullablePrimitive{Int32},Arrow.List{String,Arrow.DefaultOffset,
        Arrow.Primitive{UInt8}}}

for j ∈ 1:N_IDX_TESTS
    i = rand(1:NROWS)
    @test cols[1][i] == ndf.columns[1][i]
    @test cols[2][i] == ndf.columns[2][i]
    @test cols[3][i] == convert(Date, ndf.columns[3][i])
    @test cols[4][i] == convert(DateTime, ndf.columns[4][i])
    @test cols[5][i] == convert(Dates.Time, ndf.columns[5][i])
    @test isequal(cols[6][i], ndf.columns[6][i])
    @test cols[7][i] == ndf.columns[7][i]
    @test isequal(cols[8][i], ndf.columns[8][i])
    @test cols[9][i] == String(ndf.columns[9][i])
    @test isequal(cols[10][i], convstring(ndf.columns[10][i]))
end
for j ∈ 1:N_IDX_TESTS
    a, b = extrema(rand(1:NROWS, 2))
    i = a:b
    @test cols[1][i] == ndf.columns[1][i]
    @test cols[2][i] == ndf.columns[2][i]
    @test cols[3][i] == convert.(Date, ndf.columns[3][i])
    @test cols[4][i] == convert.(DateTime, ndf.columns[4][i])
    @test cols[5][i] == convert.(Dates.Time, ndf.columns[5][i])
    @test isequal(cols[6][i], ndf.columns[6][i])
    @test cols[7][i] == ndf.columns[7][i]
    @test isequal(cols[8][i], ndf.columns[8][i])
    @test cols[9][i] == String.(ndf.columns[9][i])
    @test isequal(cols[10][i], convstring.(ndf.columns[10][i]))
end

end
