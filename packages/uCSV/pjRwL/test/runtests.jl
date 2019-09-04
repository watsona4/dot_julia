using Test
using uCSV
using Dates
using HTTP
using CodecZlib
using RDatasets
using CategoricalArrays

files = joinpath(dirname(dirname(pathof(uCSV))), "test", "data")
GDS = GzipDecompressorStream
const ≅ = isequal

@testset "Float64 Matrix" begin
    s =
    """
    1.0,1.0,1.0
    2.0,2.0,2.0
    3.0,3.0,3.0
    """
    data, header = uCSV.read(IOBuffer(s))
    @test data ==  Any[[1.0, 2.0, 3.0],
                       [1.0, 2.0, 3.0],
                       [1.0, 2.0, 3.0]]
    @test header == Vector{String}()
end

@testset "uCSV.tomatrix" begin
    s =
    """
    1.0,1.0,1.0
    2.0,2.0,2.0
    3.0,3.0,3.0
    """;
    @test uCSV.tomatrix(uCSV.read(IOBuffer(s))) ==
        [1.0 1.0 1.0;
         2.0 2.0 2.0;
         3.0 3.0 3.0]
end

@testset "uCSV.tovector" begin
    s =
    """
    1.0,1.0,1.0
    2.0,2.0,2.0
    3.0,3.0,3.0
    """;
    @test uCSV.tovector(uCSV.read(IOBuffer(s))) ==
        [1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0]
end

@testset "DataFrame" begin
    s =
    """
    header
    data
    """
    @test DataFrame(uCSV.read(IOBuffer(s), header=1)) == DataFrame([["data"]], [:header])
    @test DataFrame(uCSV.read(IOBuffer(s), header=1, skiprows=1:1)) == DataFrame([[]], [:header])
    @test DataFrame(uCSV.read(IOBuffer(s), skiprows=1:1)) == DataFrame([["data"]], [:x1])
    @test DataFrame(uCSV.read(IOBuffer(s), skiprows=1:2)) == DataFrame()
end

@testset "Mixed Type Matrix" begin
    s =
    """
    1,1.0,a
    2,2.0,b
    3,3.0,c
    """
    data, header = uCSV.read(IOBuffer(s))
    @test data == Any[[1, 2, 3],
                      [1.0, 2.0, 3.0],
                      ["a", "b", "c"]]
    @test header == Vector{String}()
end

@testset "Header" begin
    s =
    """
    c1,c2,c3
    1,1.0,a
    2,2.0,b
    3,3.0,c
    """
    data, header = uCSV.read(IOBuffer(s))
    @test data == Any[["c1", "1", "2", "3"],
                      ["c2", "1.0", "2.0", "3.0"],
                      ["c3", "a", "b", "c"]]
    @test header == Vector{String}()


    data, header = uCSV.read(IOBuffer(s), header = 1)
    @test data == Any[[1, 2, 3],
                      [1.0, 2.0, 3.0],
                      ["a", "b", "c"]]
    @test header == ["c1", "c2", "c3"]
end

@testset "checkfield & trimwhitespace" begin
    s =
    """
    19 97, 19 97 ,1997
    """
    data, header = uCSV.read(IOBuffer(s))
    @test data == Any[["19 97"],
                      [" 19 97 "],
                      [1997]]
    @test header == Vector{String}()

    data, header = uCSV.read(IOBuffer(s), trimwhitespace=true)
    @test data == Any[["19 97"],
                      ["19 97"],
                      [1997]]
    @test header == Vector{String}()

    s = "  s s\\  "
    @test uCSV.read(IOBuffer(s), escape='\\', trimwhitespace=true)[1][1][1] == "s s"
    @test uCSV.read(IOBuffer(s), escape='\\', trimwhitespace=false)[1][1][1] == "  s s  "
    @test uCSV.read(IOBuffer(s), trimwhitespace=true)[1][1][1] == "s s\\"
    @test uCSV.read(IOBuffer(s))[1][1][1] == s

    s =
    """
     " s s\\ " ,"other text"
    """
    @test uCSV.read(IOBuffer(s), quotes='"', escape='\\', trimwhitespace=true)[1][1][1] == " s s "
    @test uCSV.read(IOBuffer(s), quotes='"', escape='\\', trimwhitespace=false)[1][1][1] == "  s s  "

    s =
    """
    \\"ss\\"
    """
    @test uCSV.read(IOBuffer(s), quotes='"', escape='\\')[1][1][1] == "\"ss\""
    s =
    """
    text
    """
    @test uCSV.read(IOBuffer(s), escape='\\', trimwhitespace=true)[1][1][1] == "text"
end

@testset "errors" begin
    s =
    """
    1,2,3
    """
    e = @test_throws ArgumentError uCSV.read(IOBuffer(s), types=Dict("col2" => Float64))
    @test e.value.msg == "One of the following user-supplied arguments:\n  1. types\n  2. allowmissing\n  3. coltypes\n  4. colparsers\nwas provided with column names as Strings that cannot be mapped to column indices because column names have either not been provided or have not been parsed.\n"

    s =
    """
    c1,c2,c3
    1,2,3
    """
    e = @test_throws ArgumentError uCSV.read(IOBuffer(s), header=1, types=Dict("col2" => Float64))
    @test e.value.msg == "user-provided column name col2 does not match any parsed or user-provided column names.\n"

    s =
    """
    1,2,3
    ,,
    """
    e = @test_throws ErrorException uCSV.read(IOBuffer(s), encodings=Dict("" => missing))
    @test e.value.msg == "Error parsing field \"\" in row 2, column 1.\nUnable to push value missing to column of type $Int\nPossible fixes may include:\n  1. set `typedetectrows` to a value >= 2\n  2. manually specify the element-type of column 1 via the `types` argument\n  3. manually specify a parser for column 1 via the `parsers` argument\n  4. if the value is missing, setting the `allowmissing` argument\n"

    e = @test_throws ArgumentError uCSV.read(IOBuffer(s), header=["col1"])
    @test e.value.msg == "user-provided header [\"col1\"] has 1 columns, but 3 were detected the in dataset.\n"
end

@testset "Ford Fiesta (Ford examples from Wikipedia page)" begin
    s =
    """
    1997,Ford,E350
    """
    data, header = uCSV.read(IOBuffer(s))
    @test data == Any[[1997],
                      ["Ford"],
                      ["E350"]]
    @test header == Vector{String}()

    s =
    """
    1997,Ford,E350
    """
    data, header = uCSV.read(IOBuffer(s), header = 1)
    @test data == Any[]
    @test header == ["1997", "Ford", "E350"]

    s =
    """
    1997,Ford,E350\n
    """
    data, header = uCSV.read(IOBuffer(s))
    @test data == Any[[1997],
                      ["Ford"],
                      ["E350"]]
    @test header == Vector{String}()

    s =
    """
    "1997","Ford","E350"
    """
    data, header = uCSV.read(IOBuffer(s))
    @test data == Any[["\"1997\""],
                      ["\"Ford\""],
                      ["\"E350\""]]
    @test header == Vector{String}()

    s =
    """
    "1997","Ford","E350"
    """
    data, header = uCSV.read(IOBuffer(s), quotes='"')
    @test data == Any[["1997"],
                      ["Ford"],
                      ["E350"]]
    @test header == Vector{String}()

    s =
    """
    "19"97,"Fo"rd,E3"50"
    """
    data, header = uCSV.read(IOBuffer(s))
    @test data == Any[["\"19\"97"],
                      ["\"Fo\"rd"],
                      ["E3\"50\""]]
    @test header == Vector{String}()

    s =
    """
    \"\"\"1997\"\"\",\"Ford\",\"E350\"
    """
    data, header = uCSV.read(IOBuffer(s))
    @test data == Any[["\"\"\"1997\"\"\""],
                      ["\"Ford\""],
                      ["\"E350\""]]
    @test header == Vector{String}()

    data, header = uCSV.read(IOBuffer(s), quotes='"', escape='"')
    @test data == Any[["\"1997\""],
                      ["Ford"],
                      ["E350"]]
    @test header == Vector{String}()

    e = @test_throws ErrorException uCSV.read(IOBuffer(s), quotes='"')
    @test e.value.msg == "Unexpected field breakpoint detected in line 1.\nline:\n   \"\"\"1997\"\"\",\"Ford\",\"E350\"\nThis may be due to nested double quotes `\"\"` within quoted fields.\nIf so, please set `escape=\"` to resolve\n"

    e = @test_throws ErrorException uCSV.read(IOBuffer(s), header=1, quotes='"')
    @test e.value.msg == "Unexpected field breakpoint detected in header.\nline:\n   \"\"\"1997\"\"\",\"Ford\",\"E350\"\nThis may be due to nested double quotes `\"\"` within quoted fields.\nIf so, please set `escape=\"` to resolve\n"

    s =
    """
    1997\\,Ford\\,E350\\
    """

    e = @test_throws ErrorException uCSV.read(IOBuffer(s), escape='\\')
    @test e.value.msg == "Unexpected field breakpoint detected in line 1.\nline:\n   1997\\,Ford\\,E350\\\n"

    s =
    """
    field1,field2,field3
    \"\"\"1997\"\"\",\"Ford\",\"E350\"
    """

    e = @test_throws ErrorException uCSV.read(IOBuffer(s), quotes='"')
    @test e.value.msg == "Unexpected field breakpoint detected in line 2.\nline:\n   \"\"\"1997\"\"\",\"Ford\",\"E350\"\nThis may be due to nested double quotes `\"\"` within quoted fields.\nIf so, please set `escape=\"` to resolve\n"

    s =
    """
    1997,Ford,E350,"Super, luxurious truck"
    """
    data, header = uCSV.read(IOBuffer(s))
    @test data == Any[[1997],
                      ["Ford"],
                      ["E350"],
                      ["\"Super"],
                      [" luxurious truck\""]]
    @test header == Vector{String}()

    data, header = uCSV.read(IOBuffer(s), quotes='"')
    @test data == Any[[1997],
                      ["Ford"],
                      ["E350"],
                      ["Super, luxurious truck"]]
    @test header == Vector{String}()

    s =
    """
    1997,Ford,E350,"Super,, luxurious truck"
    """
    data, header = uCSV.read(IOBuffer(s), quotes='"')
    @test data == Any[[1997],
                      ["Ford"],
                      ["E350"],
                      ["Super,, luxurious truck"]]
    @test header == Vector{String}()

    s =
    """
    1997,Ford,E350,"Super,,, luxurious truck"
    """
    data, header = uCSV.read(IOBuffer(s), quotes='"')
    @test data == Any[[1997],
                      ["Ford"],
                      ["E350"],
                      ["Super,,, luxurious truck"]]
    @test header == Vector{String}()

    s =
    """
    1997,Ford,E350,Super\\, luxurious truck
    """
    data, header = uCSV.read(IOBuffer(s), escape='\\')
    @test data == Any[[1997],
                      ["Ford"],
                      ["E350"],
                      ["Super, luxurious truck"]]
    @test header == Vector{String}()

    s =
    """
    1997,Ford,E350,Super\\,\\, luxurious truck
    """
    data, header = uCSV.read(IOBuffer(s), escape='\\')
    @test data == Any[[1997],
                      ["Ford"],
                      ["E350"],
                      ["Super,, luxurious truck"]]
    @test header == Vector{String}()

    s =
    """
    1997,Ford,E350,Super\\,\\,\\, luxurious truck
    """
    data, header = uCSV.read(IOBuffer(s), escape='\\')
    @test data == Any[[1997],
                      ["Ford"],
                      ["E350"],
                      ["Super,,, luxurious truck"]]
    @test header == Vector{String}()


    s = "1997,Ford,E350,\"Super, \"\"luxurious\"\" truck\""
    data, header = uCSV.read(IOBuffer(s), quotes='"', escape='"')
    @test data == Any[[1997],
                      ["Ford"],
                      ["E350"],
                      ["Super, \"luxurious\" truck"]]
    @test header == Vector{String}()

    s =
    """
    1997,Ford,E350,"Super, \\\"luxurious\\\" truck"
    """
    data, header = uCSV.read(IOBuffer(s), quotes='"', escape='\\')
    @test data == Any[[1997],
                      ["Ford"],
                      ["E350"],
                      ["Super, \"luxurious\" truck"]]
    @test header == Vector{String}()

    s =
    """
    1997,Ford,E350,Super "luxurious" truck
    """
    data, header = uCSV.read(IOBuffer(s))
    @test data == Any[[1997],
                      ["Ford"],
                      ["E350"],
                      ["Super \"luxurious\" truck"]]
    @test header == Vector{String}()

    s =
    """
    19,97;Ford;E350;Super "luxurious" truck
    """
    data, header = uCSV.read(IOBuffer(s), delim=';', colparsers=Dict(1 => x -> parse(Float64, replace(x, ',' => '.'))))
    @test data == Any[[19.97],
                      ["Ford"],
                      ["E350"],
                      ["Super \"luxurious\" truck"]]
    @test header == Vector{String}()

    data, header = uCSV.read(IOBuffer(s),
                             delim=';',
                             types=Dict(1 => Float64),
                             typeparsers=Dict(Float64 => x -> parse(Float64, replace(x, ',' => '.'))))
    @test data == Any[[19.97],
                      ["Ford"],
                      ["E350"],
                      ["Super \"luxurious\" truck"]]
    @test header == Vector{String}()


    s = "1997,Ford,E350,\"Go get one now\nthey are going fast\""
    data, header = uCSV.read(IOBuffer(s), quotes='"')
    @test data == Any[[1997],
                      ["Ford"],
                      ["E350"],
                      ["Go get one now\nthey are going fast"]]
    @test header == Vector{String}()

    s = "1997,Ford,E350,\"Go get one now\n\nthey are going fast\""
    data, header = uCSV.read(IOBuffer(s), quotes='"')
    @test data == Any[[1997],
                      ["Ford"],
                      ["E350"],
                      ["Go get one now\n\nthey are going fast"]]
    @test header == Vector{String}()

    s =
    """
    1997,Ford,E350,"Go get one now\\nthey are going fast"
    """
    data, header = uCSV.read(IOBuffer(s), quotes='"')
    @test data == Any[[1997],
                      ["Ford"],
                      ["E350"],
                      ["Go get one now\\nthey are going fast"]]
    @test header == Vector{String}()

    s =
    """
    1997, Ford, E350
    """
    data, header = uCSV.read(IOBuffer(s))
    @test data == Any[[1997],
                      [" Ford"],
                      [" E350"]]
    @test header == Vector{String}()

    data, header = uCSV.read(IOBuffer(s), trimwhitespace=true)
    @test data == Any[[1997],
                      ["Ford"],
                      ["E350"]]
    @test header == Vector{String}()

    s =
    """
    1997, "Ford" ,E350
    """
    data, header = uCSV.read(IOBuffer(s))
    @test data == Any[[1997],
                      [" \"Ford\" "],
                      ["E350"]]
    @test header ==  Vector{String}()

    data, header = uCSV.read(IOBuffer(s), trimwhitespace=true)
    @test data == Any[[1997],
                      ["\"Ford\""],
                      ["E350"]]
    @test header ==  Vector{String}()

    data, header = uCSV.read(IOBuffer(s), quotes='"')
    @test data == Any[[1997],
                      ["Ford"],
                      ["E350"]]
    @test header ==  Vector{String}()

    data, header = uCSV.read(IOBuffer(s), quotes='"', trimwhitespace=true)
    @test data == Any[[1997],
                      ["Ford"],
                      ["E350"]]
    @test header ==  Vector{String}()


    s =
    """
    1997,Ford,E350," Super luxurious truck "
    """
    data, header = uCSV.read(IOBuffer(s))
    @test data == Any[[1997],
                      ["Ford"],
                      ["E350"],
                      ["\" Super luxurious truck \""]]
    @test header ==  Vector{String}()

    data, header = uCSV.read(IOBuffer(s), quotes='"')
    @test data == Any[[1997],
                      ["Ford"],
                      ["E350"],
                      [" Super luxurious truck "]]
    @test header ==  Vector{String}()

    data, header = uCSV.read(IOBuffer(s), quotes='"', trimwhitespace=true)
    @test data == Any[[1997],
                      ["Ford"],
                      ["E350"],
                      ["Super luxurious truck"]]
    @test header ==  Vector{String}()
end

@testset "City Latitude-Longitude" begin
    s =
    """
    Los Angeles,34°03′N,118°15′W
    """
    data, header = uCSV.read(IOBuffer(s))
    @test data == Any[["Los Angeles"],
                      ["34°03′N"],
                      ["118°15′W"]]
    @test header == Vector{String}()

    s =
    """
    New York City,40°42′46″N,74°00′21″W
    """
    data, header = uCSV.read(IOBuffer(s))
    @test data == Any[["New York City"],
                      ["40°42′46″N"],
                      ["74°00′21″W"]]
    @test header == Vector{String}()

    s =
    """
    Paris,48°51′24″N,2°21′03″E
    """
    data, header = uCSV.read(IOBuffer(s))
    @test data == Any[["Paris"],
                      ["48°51′24″N"],
                      ["2°21′03″E"]]
    @test header == Vector{String}()
end

@testset "Unicode and String Delimiters" begin
    s =
    """
    x≤y≤z
    """
    data, header = uCSV.read(IOBuffer(s), delim='≤')
    @test data == Any[["x"],
                      ["y"],
                      ["z"]]
    @test header == Vector{String}()

    s =
    """
    x≤≥y≤≥z
    """
    data, header = uCSV.read(IOBuffer(s), delim="≤≥")
    @test data == Any[["x"],
                      ["y"],
                      ["z"]]
    @test header == Vector{String}()
end

@testset "Dates and Datetimes" begin
    s =
    """
    2013-01-01
    """
    data, header = uCSV.read(IOBuffer(s), types=Date)
    @test data == Any[[Date("2013-01-01")]]
    @test header == Vector{String}()

    s =
    """
    2013-01-01T00:00:00
    """
    data, header = uCSV.read(IOBuffer(s), types=DateTime)
    @test data == Any[[DateTime("2013-01-01T00:00:00")]]
    @test header == Vector{String}()
end


@testset "Missings" begin
    encodings = Dict("" => missing, "\"\"" => missing, "NULL" => missing, "NA" => missing)
    s =
    """
    1,hey,1
    2,you,2
    3,,3
    4,"",4
    5,NULL,5
    6,NA,6
    """
    data, header = uCSV.read(IOBuffer(s), encodings=encodings, typedetectrows=3)
    @test data ≅ Any[[1, 2, 3, 4, 5, 6],
                     ["hey", "you", missing, missing, missing, missing],
                     [1, 2, 3, 4, 5, 6]]
    @test header == Vector{String}()

    data, header = uCSV.read(IOBuffer(s), encodings=encodings, allowmissing=true)
    @test data ≅ Any[[1, 2, 3, 4, 5, 6],
                     ["hey", "you", missing, missing, missing, missing],
                     [1, 2, 3, 4, 5, 6]]
    @test header == Vector{String}()

    data, header = uCSV.read(IOBuffer(s), encodings=encodings, allowmissing=Dict(2 => true))
    @test data ≅ Any[[1, 2, 3, 4, 5, 6],
                     ["hey", "you", missing, missing, missing, missing],
                     [1, 2, 3, 4, 5, 6]]
    @test header == Vector{String}()

    data, header = uCSV.read(IOBuffer(s), encodings=encodings, allowmissing=[false, true, false])
    @test data ≅ Any[[1, 2, 3, 4, 5, 6],
                     ["hey", "you", missing, missing, missing, missing],
                     [1, 2, 3, 4, 5, 6]]
    @test header == Vector{String}()

    e = @test_throws ArgumentError uCSV.read(IOBuffer(s), encodings=encodings, allowmissing=[false, true])
    @test e.value.msg == "One of the following user-supplied arguments:\n  1. types\n  2. allowmissing\n  3. coltypes\n  4. colparsers\nwas provided as a vector and the length of this vector (2) != the number of detected columns (3).\n"
end

# consider re-enabling
# @testset "skipcols" begin
#     s =
#     """
#     1.0,1.0,1.0
#     2.0,2.0,2.0
#     3.0,3.0,3.0
#     """
#     data, header = uCSV.read(IOBuffer(s), skipcols=1)
#     @test data == Any[[1.0, 2.0, 3.0],
#                       [1.0, 2.0, 3.0]]
#     @test header == Vector{String}()
#
#     data, header = uCSV.read(IOBuffer(s), skipcols=[1,2])
#     @test data == Any[[1.0, 2.0, 3.0]]
#     @test header == Vector{String}()
#
#     data, header = uCSV.read(IOBuffer(s), skipcols=1:2)
#     @test data == Any[[1.0, 2.0, 3.0]]
#     @test header == Vector{String}()
#
#     data, header = uCSV.read(IOBuffer(s), skipcols=[true, true, false])
#     @test data == Any[[1.0, 2.0, 3.0]]
#     @test header == Vector{String}()
#
#     data, header = uCSV.read(IOBuffer(s), skipcols=Dict(1 => true, 2 => true, 3 => false))
#     @test data == Any[[1.0, 2.0, 3.0]]
#     @test header == Vector{String}()
#
#     data, header = uCSV.read(IOBuffer(s), skipcols=Dict(1 => true, 2 => true))
#     @test data == Any[[1.0, 2.0, 3.0]]
#     @test header == Vector{String}()
#
#     data, header = uCSV.read(IOBuffer(s), header=["c1", "c2", "c3"], skipcols="c1")
#     @test data == Any[[1.0, 2.0, 3.0],
#                       [1.0, 2.0, 3.0]]
#     @test header == ["c2", "c3"]
#
#     data, header = uCSV.read(IOBuffer(s), header=["c1", "c2", "c3"], skipcols=Dict("c1" => true, "c2" => true))
#     @test data == Any[[1.0, 2.0, 3.0]]
#     @test header == ["c3"]
#
#     data, header = uCSV.read(IOBuffer(s), header=["c1", "c2", "c3"], skipcols=["c1", "c2"])
#     @test data == Any[[1.0, 2.0, 3.0]]
#     @test header == ["c3"]
# end

@testset "Read from URL" begin
    html = "https://raw.github.com/vincentarelbundock/Rdatasets/master/csv/datasets/USPersonalExpenditure.csv"
    data, header = uCSV.read(IOBuffer(HTTP.get(html).body), quotes='"', header=1)
    @test data == Any[["Food and Tobacco", "Household Operation", "Medical and Health", "Personal Care", "Private Education"],
                      [22.2, 10.5, 3.53, 1.04, 0.341],
                      [44.5, 15.5, 5.76, 1.98, 0.974],
                      [59.6, 29.0, 9.71, 2.45, 1.8],
                      [73.2, 36.5, 14.0, 3.4, 2.6],
                      [86.8, 46.2, 21.1, 5.4, 3.64]]
    @test header == String["", "1940", "1945", "1950", "1955", "1960"]
end

@testset "Comments and Skipped Lines" begin
    s =
    """
    # i am a comment
    data
    """
    data, header = uCSV.read(IOBuffer(s), comment='#')
    @test data == Any[["data"]]
    @test header == Vector{String}()

    s =
    """
    # i am a comment
    I'm the header
    """
    data, header = uCSV.read(IOBuffer(s), header=2)
    @test data == Any[]
    @test header == ["I'm the header"]

    data, header = uCSV.read(IOBuffer(s), comment='#', header=1)
    @test data == Any[]
    @test header == ["I'm the header"]

    s =
    """
    # i am a comment
    I'm the header
    skipped data
    included data
    """
    data, header = uCSV.read(IOBuffer(s), comment='#', header=1, skiprows=1:1)
    @test data == Any[["included data"]]
    @test header == ["I'm the header"]

    s =
    """
    # i am a comment
    I'm the header
    skipped data 1
    included data 1
    included data 2
    skipped data 3
    skipped data 4
    included data 3
    included data 4
    """
    data, header = uCSV.read(IOBuffer(s), comment='#', header=1, skiprows=[1,4,5])
    @test data == Any[["included data 1",
                       "included data 2",
                       "included data 3",
                       "included data 4"]]
    @test header == ["I'm the header"]
end

@testset "CategoricalVectors" begin
    s =
    """
    a,b,c
    a,b,c
    a,b,c
    a,b,c
    """
    data, header = uCSV.read(IOBuffer(s), coltypes=CategoricalVector)
    @test data == Any[CategoricalVector(["a", "a", "a", "a"]),
                      CategoricalVector(["b", "b", "b", "b"]),
                      CategoricalVector(["c", "c", "c", "c"])]
    @test header == Vector{String}()

    data, header = uCSV.read(IOBuffer(s), coltypes=fill(CategoricalVector, 3))
    @test data == Any[CategoricalVector(["a", "a", "a", "a"]),
                      CategoricalVector(["b", "b", "b", "b"]),
                      CategoricalVector(["c", "c", "c", "c"])]
    @test header == Vector{String}()

    data, header = uCSV.read(IOBuffer(s), coltypes=Dict(i => CategoricalVector for i in 1:3))
    @test data == Any[CategoricalVector(["a", "a", "a", "a"]),
                      CategoricalVector(["b", "b", "b", "b"]),
                      CategoricalVector(["c", "c", "c", "c"])]
    @test header == Vector{String}()

    data, header = uCSV.read(IOBuffer(s), header=1, coltypes=Dict(s => CategoricalVector for s in ["a", "b", "c"]))
    @test data == Any[CategoricalVector(["a", "a", "a"]),
                      CategoricalVector(["b", "b", "b"]),
                      CategoricalVector(["c", "c", "c"])]
    @test header == ["a", "b", "c"]
end

@testset "Manually Declaring eltypes" begin
        s =
        """
        1
        2
        3
        """
        data, header = uCSV.read(IOBuffer(s), types=Int32)
        @test data ==  Any[Int32[1, 2, 3]]
        @test eltype(data[1]) == Int32
        @test header == Vector{String}()
end

@testset "Malformed Rows" begin
    s = "col1,col2,\"col3\n\""
    data, header = uCSV.read(IOBuffer(s), quotes='"')
    @test data == Any[["col1"],
                      ["col2"],
                      ["col3\n"]]
    @test header == Vector{String}()

    data, header = uCSV.read(IOBuffer(s), quotes='"', header=1)
    @test data == Any[]
    @test header == ["col1", "col2", "col3\n"]

    s = "col1,col2,\"col3\n\"\ncol1,col2,\"col3\n\"\ncol1,col2,\"col3\n\""
    data, header = uCSV.read(IOBuffer(s), quotes='"')
    @test data == Any[["col1", "col1", "col1"],
                      ["col2", "col2", "col2"],
                      ["col3\n", "col3\n", "col3\n"]]
    @test header == Vector{String}()

    s = "col1,col2,\"col3\n\"\ncol1,col2,\"col3\n\"\ncol1,col2,\"col3\n\""
    data, header = uCSV.read(IOBuffer(s), quotes='"', typedetectrows=2)
    @test data == Any[["col1", "col1", "col1"],
                      ["col2", "col2", "col2"],
                      ["col3\n", "col3\n", "col3\n"]]
    @test header == Vector{String}()

    s = "col1,col2,\"col3\n\"\ncol1,col2,\"col3\n\"\ncol1,col2,\"col3\n\""
    data, header = uCSV.read(IOBuffer(s), quotes='"', typedetectrows=3)
    @test data == Any[["col1", "col1", "col1"],
                      ["col2", "col2", "col2"],
                      ["col3\n", "col3\n", "col3\n"]]
    @test header == Vector{String}()

    s =
    """
    A;B;C
    1,1,10
    2,0,16
    """
    e = @test_throws ErrorException uCSV.read(IOBuffer(s))
    @test e.value.msg == "Parsed 3 fields on row 2. Expected 1.\nline:\n1,1,10\nPossible fixes may include:\n  1. including 2 in the `skiprows` argument\n  2. setting `skipmalformed=true`\n  3. if this line is a comment, setting the `comment` argument\n  4. if fields are quoted, setting the `quotes` argument\n  5. if special characters are escaped, setting the `escape` argument\n  6. fixing the malformed line in the source or file before invoking `uCSV.read`\n"

    e = @test_throws ErrorException uCSV.read(IOBuffer(s), header = 1)
    @test e.value.msg == "parsed header [\"A;B;C\"] has 1 columns, but 3 were detected the in dataset.\n"

    s =
    """
    A,B,C
    1,1,10
    6,1
    """
    e = @test_throws ErrorException uCSV.read(IOBuffer(s))
    @test e.value.msg == "Parsed 2 fields on row 3. Expected 3.\nline:\n6,1\nPossible fixes may include:\n  1. including 3 in the `skiprows` argument\n  2. setting `skipmalformed=true`\n  3. if this line is a comment, setting the `comment` argument\n  4. if fields are quoted, setting the `quotes` argument\n  5. if special characters are escaped, setting the `escape` argument\n  6. fixing the malformed line in the source or file before invoking `uCSV.read`\n"

    s =
    """
    A,B,C
    1,1,10
    6,1
    """
    e = @test_throws ErrorException uCSV.read(IOBuffer(s), typedetectrows=3)
    @test e.value.msg == "Parsed 2 fields on row 3. Expected 3.\nline:\n6,1\nPossible fixes may include:\n  1. including 3 in the `skiprows` argument\n  2. setting `skipmalformed=true`\n  3. if this line is a comment, setting the `comment` argument\n  4. if fields are quoted, setting the `quotes` argument\n  5. if special characters are escaped, setting the `escape` argument\n  6. fixing the malformed line in the source or file before invoking `uCSV.read`\n"

    uCSV.read(IOBuffer(s), typedetectrows=3, skipmalformed=true)
end

@testset "Booleans" begin
    s =
    """
    true
    """
    data, header = uCSV.read(IOBuffer(s), types=Bool)
    @test data == Any[[true]]
    @test header == Vector{String}()
end

@testset "Read Iris" begin
    df = DataFrame(uCSV.read(GzipDecompressorStream(open(joinpath(files, "iris.csv.gz"))), header=1))
    @test first(df, 1) == DataFrame(Id = 1,
                                    SepalLengthCm = 5.1,
                                    SepalWidthCm = 3.5,
                                    PetalLengthCm = 1.4,
                                    PetalWidthCm = 0.2,
                                    Species = "Iris-setosa")
end


if Sys.WORD_SIZE == 64 && !Sys.iswindows()
    @testset "Write Iris" begin
        df = DataFrame(uCSV.read(GzipDecompressorStream(open(joinpath(files, "iris.csv.gz"))), header=1))
        outpath = joinpath(dirname(files), "temp.txt")
        uCSV.write(outpath, header = string.(names(df)), data = DataFrames.columns(df))
        @test hash(read(open(outpath), String)) == 0x2f6e8bca9d9f43ed

        uCSV.write(outpath, df)
        @test hash(read(open(outpath), String)) == 0x2f6e8bca9d9f43ed

        uCSV.write(open(outpath, "w"), header = string.(names(df)), data = DataFrames.columns(df))
        @test hash(read(open(outpath), String)) == 0x2f6e8bca9d9f43ed

        e = @test_throws ArgumentError uCSV.write(open(outpath), header = string.(names(df)), data = DataFrames.columns(df))
        @test e.value.msg == "Provided IO is not writable\n"

        uCSV.write(outpath, header = string.(names(df)), data = DataFrames.columns(df), quotes='"')
        @test hash(read(open(outpath), String)) == 0x01eced86ce7925c3

        uCSV.write(outpath, header = string.(names(df)), data = DataFrames.columns(df), quotes='"', quotetypes=Any)
        @test hash(read(open(outpath), String)) == 0x5548866b058bb193

        uCSV.write(outpath, header = string.(names(df)), data = DataFrames.columns(df), quotes='"', delim="≤≥")
        @test hash(read(open(outpath), String)) == 0x2cd049ba9cf45178

        uCSV.write(outpath, header = string.(names(df)))
        @test hash(read(open(outpath), String)) == 0x28eea4238d3c772f

        uCSV.write(outpath, data = DataFrames.columns(df))
        @test hash(read(open(outpath), String)) == 0x92a0c4b8ee59a667

        e = @test_throws ArgumentError uCSV.write(outpath)
        @test e.value.msg == "no header or data provided"

        e = @test_throws AssertionError uCSV.write(outpath, header = string.(names(df))[1:2], data = DataFrames.columns(df))
        @test e.value.msg == "length(header) == length(data)"

        uCSV.write(outpath, df, quotes='"', quotetypes=Real)
        @test hash(read(open(outpath), String)) == 0xd6276abc14f24a7a

        df[6] = convert(Vector{Union{String, Missing}}, df[6]);
        df[6][2:3] .= missing;
        uCSV.write(outpath, df, quotes='"')
        @test hash(read(open(outpath), String)) == 0x76b9d2c96afcb277

        df[6] = missings(size(df, 1));
        uCSV.write(outpath, df, quotes='"')
        @test hash(read(open(outpath), String)) == 0xd9a646014e50fb75

        rm(outpath)
    end

    @testset "Writing and reading specific types to and from disk" begin
        # Create data and write to disk
        data = DataFrame(dt=[Date(2018,10,8)])
        outpath = joinpath(dirname(files), "test.tsv")
        uCSV.write(outpath, data; header=String.(names(data)), delim='\t')

        # Read data from disk
        data2 = DataFrame(uCSV.read(outpath; delim='\t', header=1, types=Dict("dt" => Date)))
        @test eltype(data2[:dt]) == Date  # False. Should be true.
        rm(outpath)
    end
end

@testset "2010_BSA_Carrier_PUF.csv.gz" begin
    f = joinpath(files, "2010_BSA_Carrier_PUF.csv.gz")
    e = @test_throws ErrorException uCSV.read(GDS(open(f)), header=1)
    @test e.value.msg == "Error parsing field \"A0425\" in row 2, column 4.\nUnable to parse field \"A0425\" as type $Int\nPossible fixes may include:\n  1. set `typedetectrows` to a value >= 2\n  2. manually specify the element-type of column 4 via the `types` argument\n  3. manually specify a parser for column 4 via the `parsers` argument\n  4. if the intended value is missing or another special encoding, setting the `encodings` argument appropriately.\n"
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, typedetectrows=2))
    @test names(df) == [:BENE_SEX_IDENT_CD, :BENE_AGE_CAT_CD, :CAR_LINE_ICD9_DGNS_CD, :CAR_LINE_HCPCS_CD, :CAR_LINE_BETOS_CD, :CAR_LINE_SRVC_CNT, :CAR_LINE_PRVDR_TYPE_CD, :CAR_LINE_CMS_TYPE_SRVC_CD, :CAR_LINE_PLACE_OF_SRVC_CD, :CAR_HCPS_PMT_AMT, :CAR_LINE_CNT]
    @test size(df) == (2801660, 11)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, Int, String, String, String, Int, Int, String, Int, Int, Int]]
end

@testset "AIRSIGMET.csv.gz" begin
    f = joinpath(files, "AIRSIGMET.csv.gz")
    e = @test_throws ErrorException DataFrame(uCSV.read(GDS(open(f))))
    @test e.value.msg == "Parsed 12 fields on row 6. Expected 1.\nline:\nraw_text,valid_time_from,valid_time_to,lon:lat points,min_ft_msl,max_ft_msl,movement_dir_degrees,movement_speed_kt,hazard,severity,airsigmet_type,\nPossible fixes may include:\n  1. including 6 in the `skiprows` argument\n  2. setting `skipmalformed=true`\n  3. if this line is a comment, setting the `comment` argument\n  4. if fields are quoted, setting the `quotes` argument\n  5. if special characters are escaped, setting the `escape` argument\n  6. fixing the malformed line in the source or file before invoking `uCSV.read`\n"
    data, header = uCSV.read(GDS(open(f)), skipmalformed=true, header=1)
    @test data == Any[["No warnings", "285 ms", "data source=airsigmets", "1 results"]]
    @test header == ["No errors"]
    df = DataFrame(uCSV.read(GDS(open(f)), header=6))
    @test names(df) == [:raw_text, :valid_time_from, :valid_time_to, Symbol("lon:lat points"), :min_ft_msl, :max_ft_msl, :movement_dir_degrees, :movement_speed_kt, :hazard, :severity, :airsigmet_type, Symbol("")]
    @test size(df) == (1, 12)
    @test typeof.(DataFrames.columns(df)) ==  [Vector{T} for T in
                                   [String, String, String, String, Int, Int, String, String, String, String, String, String]]
end

@testset "Ex3_human_rat_cirrhosis_signature_for_NTP.txt.gz" begin
    f = joinpath(files, "Ex3_human_rat_cirrhosis_signature_for_NTP.txt.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, delim='\t'))
    @test names(df) == [Symbol("Human.Symbol"), :DESCRIPTION, :cirrhosis1_normal2, Symbol("tstat.high.in.cirrhosis")]
    @test size(df) == (1246, 4)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String, Int, Float64]]
end

@testset "Ex4_multi_tissues_signature_for_NTP.txt.gz" begin
    f = joinpath(files, "Ex4_multi_tissues_signature_for_NTP.txt.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, delim='\t'))
    @test names(df) == [:NAME, :DESCRIPTION, :Br1_Pr2_Lu3_Co4]
    @test size(df) == (1603, 3)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String, Int]]
end

@testset "FL_insurance_sample.csv.gz" begin
    f = joinpath(files, "FL_insurance_sample.csv.gz")
    e = @test_throws ErrorException uCSV.read(GDS(open(f)), header=1)
    @test e.value.msg == "Error parsing field \"1322376.3\" in row 2, column 4.\nUnable to parse field \"1322376.3\" as type $Int\nPossible fixes may include:\n  1. set `typedetectrows` to a value >= 2\n  2. manually specify the element-type of column 4 via the `types` argument\n  3. manually specify a parser for column 4 via the `parsers` argument\n  4. if the intended value is missing or another special encoding, setting the `encodings` argument appropriately.\n"
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, typedetectrows=2439))
    @test names(df) == [:policyID, :statecode, :county, :eq_site_limit, :hu_site_limit, :fl_site_limit, :fr_site_limit, :tiv_2011, :tiv_2012, :eq_site_deductible, :hu_site_deductible, :fl_site_deductible, :fr_site_deductible, :point_latitude, :point_longitude, :line, :construction, :point_granularity]
    @test size(df) == (36634, 18)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, String, String, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Int, Float64, Float64, String, String, Int]]
end

@testset "Fielding.csv.gz" begin
    f = joinpath(files, "Fielding.csv.gz")
    e = @test_throws ErrorException uCSV.read(GDS(open(f)), header=1)
    @test e.value.msg == "Error parsing field \"\" in row 3460, column 11.\nUnable to parse field \"\" as type $Int\nPossible fixes may include:\n  1. set `typedetectrows` to a value >= 3460\n  2. manually specify the element-type of column 11 via the `types` argument\n  3. manually specify a parser for column 11 via the `parsers` argument\n  4. if the intended value is missing or another special encoding, setting the `encodings` argument appropriately.\n"
    e = @test_throws ArgumentError uCSV.read(GDS(open(f)), header=1, allowmissing=Dict(11 => true))
    @test e.value.msg == "Columns allowing missing values have been requested but the user has not specified any strings to interpret as missing values via the `encodings` argument.\n"
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, types=Dict(8 => Int, 9 => Int, 14 => Int, 15 => Int, 16 => Int, 17 => Int, 18 => Int), encodings=Dict("" => missing), allowmissing=Dict(10 => true, 11 => true, 12 => true, 13 => true)))
    @test names(df) == [:playerID, :yearID, :stint, :teamID, :lgID, :POS, :G, :GS, :InnOuts, :PO, :A, :E, :DP, :PB, :WP, :SB, :CS, :ZR]
    @test size(df) == (167938, 18)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Int, Int, String, String, String, Int, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}]]
end

@testset "Gaz_zcta_national.txt.gz" begin
    f = joinpath(files, "Gaz_zcta_national.txt.gz")
    # manually specify Int64 to pass tests on windows32 bit
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, delim='\t', trimwhitespace=true, types=Dict(i => Int64 for i in 1:5)))
    @test names(df) == [:GEOID, :POP10, :HU10, :ALAND, :AWATER, :ALAND_SQMI, :AWATER_SQMI, :INTPTLAT, :INTPTLONG]
    @test size(df) == (33120, 9)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int64, Int64, Int64, Int64, Int64, Float64, Float64, Float64, Float64]]
end

@testset "Homo_sapiens.GRCh38.90.chr.gtf.gz" begin
    f = joinpath(files, "Homo_sapiens.GRCh38.90.chr.gtf.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), delim='\t', comment="#!", types=Dict(1 => String)))
    @test names(df) == [:x1, :x2, :x3, :x4, :x5, :x6, :x7, :x8, :x9]
    @test size(df) == (2612129, 9)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String, String, Int, Int, String, String, String, String]]
end

@testset "Homo_sapiens.GRCh38.90.gff3.gz" begin
    f = joinpath(files, "Homo_sapiens.GRCh38.90.gff3.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), delim='\t', comment='#', types=Dict(1 => Symbol)))
    @test names(df) == [:x1, :x2, :x3, :x4, :x5, :x6, :x7, :x8, :x9]
    @test size(df) == (2636880, 9)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Symbol, String, String, Int, Int, String, String, String, String]]
end

@testset "Homo_sapiens_clinically_associated.vcf.gz" begin
    f = joinpath(files, "Homo_sapiens_clinically_associated.vcf.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), delim='\t', comment="##", types=Dict(1 => Symbol), header=1))
    @test names(df) == [Symbol("#CHROM"), :POS, :ID, :REF, :ALT, :QUAL, :FILTER, :INFO]
    @test size(df) == (66600, 8)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Symbol, Int, String, String, String, String, String, String]]
end

@testset "METARs.csv.gz" begin
    f = joinpath(files, "METARs.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=6), makeunique=true)
    @test names(df) == [:raw_text, :station_id, :observation_time, :latitude, :longitude, :temp_c, :dewpoint_c, :wind_dir_degrees, :wind_speed_kt, :wind_gust_kt, :visibility_statute_mi, :altim_in_hg, :sea_level_pressure_mb, :corrected, :auto, :auto_station, :maintenance_indicator_on, :no_signal, :lightning_sensor_off, :freezing_rain_sensor_off, :present_weather_sensor_off, :wx_string, :sky_cover, :cloud_base_ft_agl, :sky_cover_1, :cloud_base_ft_agl_1, :sky_cover_2, :cloud_base_ft_agl_2, :sky_cover_3, :cloud_base_ft_agl_3, :flight_category, :three_hr_pressure_tendency_mb, :maxT_c, :minT_c, :maxT24hr_c, :minT24hr_c, :precip_in, :pcp3hr_in, :pcp6hr_in, :pcp24hr_in, :snow_in, :vert_vis_ft, :metar_type, :elevation_m]
    @test size(df) == (2, 44)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String, String, Float64, Float64, Float64, Float64, Int, Int, String, Float64, Float64, Float64, String, String, String, String, String, String, String, String, String, String, Int, String, Int, String, Int, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, Float64]]
end

@testset "Most-Recent-Cohorts-Scorecard-Elements.csv.gz" begin
    f = joinpath(files, "Most-Recent-Cohorts-Scorecard-Elements.csv.gz")
    @test_logs (:warn, "Large values for `typedetectrows` will reduce performance. Consider manually declaring the types of columns using the `types` argument instead.\n") uCSV.read(GDS(open(f)), header=1, encodings=Dict("NULL" => missing, "PrivacySuppressed" => missing), typedetectrows=7283, quotes='"', skiprows=2:typemax(Int))
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, encodings=Dict("NULL" => missing, "PrivacySuppressed" => missing), typedetectrows=200, quotes='"', allowmissing=true))
    @test names(df) == [Symbol("UNITID"), :OPEID, :OPEID6, :INSTNM, :CITY, :STABBR, :INSTURL, :NPCURL, :HCM2, :PREDDEG, :CONTROL, :LOCALE, :HBCU, :PBI, :ANNHI, :TRIBAL, :AANAPII, :HSI, :NANTI, :MENONLY, :WOMENONLY, :RELAFFIL, :SATVR25, :SATVR75, :SATMT25, :SATMT75, :SATWR25, :SATWR75, :SATVRMID, :SATMTMID, :SATWRMID, :ACTCM25, :ACTCM75, :ACTEN25, :ACTEN75, :ACTMT25, :ACTMT75, :ACTWR25, :ACTWR75, :ACTCMMID, :ACTENMID, :ACTMTMID, :ACTWRMID, :SAT_AVG, :SAT_AVG_ALL, :PCIP01, :PCIP03, :PCIP04, :PCIP05, :PCIP09, :PCIP10, :PCIP11, :PCIP12, :PCIP13, :PCIP14, :PCIP15, :PCIP16, :PCIP19, :PCIP22, :PCIP23, :PCIP24, :PCIP25, :PCIP26, :PCIP27, :PCIP29, :PCIP30, :PCIP31, :PCIP38, :PCIP39, :PCIP40, :PCIP41, :PCIP42, :PCIP43, :PCIP44, :PCIP45, :PCIP46, :PCIP47, :PCIP48, :PCIP49, :PCIP50, :PCIP51, :PCIP52, :PCIP54, :DISTANCEONLY, :UGDS, :UGDS_WHITE, :UGDS_BLACK, :UGDS_HISP, :UGDS_ASIAN, :UGDS_AIAN, :UGDS_NHPI, :UGDS_2MOR, :UGDS_NRA, :UGDS_UNKN, :PPTUG_EF, :CURROPER, :NPT4_PUB, :NPT4_PRIV, :NPT41_PUB, :NPT42_PUB, :NPT43_PUB, :NPT44_PUB, :NPT45_PUB, :NPT41_PRIV, :NPT42_PRIV, :NPT43_PRIV, :NPT44_PRIV, :NPT45_PRIV, :PCTPELL, :RET_FT4, :RET_FTL4, :RET_PT4, :RET_PTL4, :PCTFLOAN, :UG25ABV, :MD_EARN_WNE_P10, :GT_25K_P6, :GRAD_DEBT_MDN_SUPP, :GRAD_DEBT_MDN10YR_SUPP, :RPY_3YR_RT_SUPP, :C150_L4_POOLED_SUPP, :C150_4_POOLED_SUPP]
    @test size(df) == (7703, 122)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Int, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}]]
end

@testset "OP_DTL_OWNRSHP_PGYR2016_P06302017.csv.gz" begin
    f = joinpath(files, "OP_DTL_OWNRSHP_PGYR2016_P06302017.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, quotes='"', encodings=Dict("" => missing), allowmissing=true, typedetectrows=10, types=Dict(14 => Int)))
    @test names(df) == [:Change_Type, :Physician_Profile_ID, :Physician_First_Name, :Physician_Middle_Name, :Physician_Last_Name, :Physician_Name_Suffix, :Recipient_Primary_Business_Street_Address_Line1, :Recipient_Primary_Business_Street_Address_Line2, :Recipient_City, :Recipient_State, :Recipient_Zip_Code, :Recipient_Country, :Recipient_Province, :Recipient_Postal_Code, :Physician_Primary_Type, :Physician_Specialty, :Record_ID, :Program_Year, :Total_Amount_Invested_USDollars, :Value_of_Interest, :Terms_of_Interest, :Submitting_Applicable_Manufacturer_or_Applicable_GPO_Name, :Applicable_Manufacturer_or_Applicable_GPO_Making_Payment_ID, :Applicable_Manufacturer_or_Applicable_GPO_Making_Payment_Name, :Applicable_Manufacturer_or_Applicable_GPO_Making_Payment_State, :Applicable_Manufacturer_or_Applicable_GPO_Making_Payment_Country, :Dispute_Status_for_Publication, :Interest_Held_by_Physician_or_an_Immediate_Family_Member, :Payment_Publication_Date]
    @test size(df) == (3640, 29)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Missing, Union{Int, Missing}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}]]
end

@testset "PIREPs.csv.gz" begin
    f = joinpath(files, "PIREPs.csv.gz")
    # TODO read receipt_time & observation_time as datetimes
    df = DataFrame(uCSV.read(GDS(open(f)), header=6, encodings=Dict("" => missing), typedetectrows=1000), makeunique=true)
    @test names(df) == [:receipt_time, :observation_time, :mid_point_assumed, :no_time_stamp, :flt_lvl_range, :above_ground_level_indicated, :no_flt_lvl, :bad_location, :aircraft_ref, :latitude, :longitude, :altitude_ft_msl, :sky_cover, :cloud_base_ft_msl, :cloud_top_ft_msl, :sky_cover_1, :cloud_base_ft_msl_1, :cloud_top_ft_msl_1, :turbulence_type, :turbulence_intensity, :turbulence_base_ft_msl, :turbulence_top_ft_msl, :turbulence_freq, :turbulence_type_1, :turbulence_intensity_1, :turbulence_base_ft_msl_1, :turbulence_top_ft_msl_1, :turbulence_freq_1, :icing_type, :icing_intensity, :icing_base_ft_msl, :icing_top_ft_msl, :icing_type_1, :icing_intensity_1, :icing_base_ft_msl_1, :icing_top_ft_msl_1, :visibility_statute_mi, :wx_string, :temp_c, :wind_dir_degrees, :wind_speed_kt, :vert_gust_kt, :report_type, :raw_text]
    @test size(df) == (1000, 44)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String, Union{Missing, String}, Missing, Union{Missing, String}, Missing, Union{Missing, String}, Union{Missing, String}, String, Float64, Float64, Int, Union{Missing, String}, Union{Int, Missing}, Union{Int, Missing}, Union{Missing, String}, Union{Int, Missing}, Union{Int, Missing}, Union{Missing, String}, Union{Missing, String}, Union{Int, Missing}, Missing, Union{Missing, String}, Missing, Missing, Missing, Missing, Missing, Union{Missing, String}, Union{Missing, String}, Missing, Missing, Missing, Union{Missing, String}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Missing, String}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Missing, String, String]]
end

@testset "STATIONINFO.csv.gz" begin
    f = joinpath(files, "STATIONINFO.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=6, trimwhitespace=true, encodings=Dict("" => missing), typedetectrows=3, skipmalformed=true))
    df = DataFrame(uCSV.read(GDS(open(f)), header=6, trimwhitespace=true, encodings=Dict("" => missing), types=Dict(2 => Union{Int, Missing}), skipmalformed=true))
    @test names(df) == [:station_id, :wmo_id, :latitude, :longitude, :elevation_m, :site, :state, :country, :site_type]
    @test size(df) == (813, 9)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Union{Int, Missing}, Float64, Float64, Float64, String, String, String, String]]
end

@testset "SacramentocrimeJanuary2006.csv.gz" begin
    f = joinpath(files, "SacramentocrimeJanuary2006.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, trimwhitespace=true))
    @test names(df) == [:cdatetime, :address, :district, :beat, :grid, :crimedescr, :ucr_ncic_code, :latitude, :longitude]
    @test size(df) == (7584, 9)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String, Int, String, Int, String, Int, Float64, Float64]]
end

@testset "Sacramentorealestatetransactions.csv.gz" begin
    f = joinpath(files, "Sacramentorealestatetransactions.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1))
    @test names(df) == [:street, :city, :zip, :state, :beds, :baths, :sq__ft, :type, :sale_date, :price, :latitude, :longitude]
    @test size(df) == (985, 12)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String, Int, String, Int, Int, Int, String, String, Int, Float64, Float64]]
end

@testset "SalesJan2009.csv.gz" begin
    f = joinpath(files, "SalesJan2009.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, trimwhitespace=true, quotes='"', colparsers=Dict(3 => x -> parse(Int, replace(x, ',' => "")))))
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, trimwhitespace=true, quotes='"', typeparsers=Dict(Int => x -> parse(Int, replace(x, ',' => "")))))
    @test names(df) == [:Transaction_date, :Product, :Price, :Payment_Type, :Name, :City, :State, :Country, :Account_Created, :Last_Login, :Latitude, :Longitude]
    @test size(df) == (998, 12)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String, Int, String, String, String, String, String, String, String, Float64, Float64]]
end

@testset "TechCrunchcontinentalUSA.csv.gz" begin
    f = joinpath(files, "TechCrunchcontinentalUSA.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, quotes='"', types=Dict(3 => Union{Int, Missing}, 4 => Union{String, Missing}, 5 => Union{String, Missing}), encodings=Dict("" => missing)))
    @test names(df) == [:permalink, :company, :numEmps, :category, :city, :state, :fundedDate, :raisedAmt, :raisedCurrency, :round]
    @test size(df) == (1460, 10)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String, Union{Int, Missing}, Union{Missing, String}, Union{Missing, String}, String, String, Int, String, String]]
end

@testset "WellIndex_20160811.csv.gz" begin
    f = joinpath(files, "WellIndex_20160811.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, quotes='"', escape='"', allowmissing = Dict(6 => true, 8 => true, 10 => true, 15 => true, 21 => true, 27 => true), encodings=Dict("" => missing), types=Dict(1 => Int64), typedetectrows=100))
    @test names(df) == [:APINo, :FileNo, :CurrentOperator, :CurrentWellName, :LeaseName, :LeaseNumber, :OriginalOperator, :OriginalWellName, :SpudDate, :TD, :CountyName, :Township, :Range, :Section, :QQ, :Footages, :FieldName, :ProducedPools, :OilWaterGasCums, :IPTDateOilWaterGas, :Wellbore, :Latitude, :Longitude, :WellType, :WellStatus, :CTB, :WellStatusDate]
    @test size(df) == (33445, 27)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int64, Int, String, String, String, Union{Missing, String}, String, Union{Missing, String}, Union{Missing, String}, Union{Int, Missing}, String, String, String, Int, Union{Missing, String}, Union{Missing, String}, String, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Float64, Missing}, Union{Float64, Missing}, String, String, Union{Int, Missing}, Union{Missing, String}]]
end

@testset "baseball.csv.gz" begin
    f = joinpath(files, "baseball.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, typedetectrows=35, encodings=Dict("" => missing)), makeunique=true)
    @test names(df) == [:Rk, :Year, :Age, :Tm, :Lg, Symbol(""), :W, :L, Symbol("W-L%"), :G, :Finish, :Wpost, :Lpost, Symbol("W-L%post"), :_1]
    @test size(df) == (35, 15)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Int, Missing}, Union{Int, Missing}, Union{Float64, Missing}, Union{Int, Missing}, Union{Float64, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Float64, Missing}, Union{Missing, String}]]
end

@testset "battles.csv.gz" begin
    f = joinpath(files, "battles.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, quotes='"', escape='"', encodings=Dict("" => missing), typedetectrows=100))
    @test names(df) == [:name, :year, :battle_number, :attacker_king, :defender_king, :attacker_1, :attacker_2, :attacker_3, :attacker_4, :defender_1, :defender_2, :defender_3, :defender_4, :attacker_outcome, :battle_type, :major_death, :major_capture, :attacker_size, :defender_size, :attacker_commander, :defender_commander, :summer, :location, :region, :note]
    @test size(df) == (38, 25)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Int, Int, Union{Missing, String}, Union{Missing, String}, String, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Missing, Missing, Union{Missing, String}, Union{Missing, String}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Missing, String}, Union{Missing, String}, Union{Int, Missing}, Union{Missing, String}, String, Union{Missing, String}]]
end

@testset "BOM.txt.gz" begin
    f = joinpath(files, "BOM.txt.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, delim='\t'))
    @test names(df) == [:TimeStamp, :V1, :V2, :V3, :V4, :V5, :V6, :V7, :V8, :V9, :V10, :V11, :V12, :V13, :V14, :V15, :V16, :V17, :V18, :V19, :V20, :V21, :V22, :V23, :V24, :V25, :V26, :V27, :V28, :V29, :V30, :V31]
    @test size(df) == (4, 32)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String]]
    df = DataFrame(uCSV.read(GDS(open(f)), delim='\t'))
    @test names(df) == [:x1, :x2, :x3, :x4, :x5, :x6, :x7, :x8, :x9, :x10, :x11, :x12, :x13, :x14, :x15, :x16, :x17, :x18, :x19, :x20, :x21, :x22, :x23, :x24, :x25, :x26, :x27, :x28, :x29, :x30, :x31, :x32]
    @test size(df) == (5, 32)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String]]
end

@testset "character-deaths.csv.gz" begin
    f = joinpath(files, "character-deaths.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, quotes='"', encodings=Dict("" => missing), typedetectrows=100))
    @test names(df) == [:Name, :Allegiances, Symbol("Death Year"), Symbol("Book of Death"), Symbol("Death Chapter"), Symbol("Book Intro Chapter"), :Gender, :Nobility, :GoT, :CoK, :SoS, :FfC, :DwD]
    @test size(df) == (917, 13)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Int, Int, Int, Int, Int, Int, Int]]
end

@testset "character-predictions.csv.gz" begin
    f = joinpath(files, "character-predictions.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, quotes='"', encodings=Dict("" => missing), typedetectrows=100))
    @test names(df) == [Symbol("S.No"), :actual, :pred, :alive, :plod, :name, :title, :male, :culture, :dateOfBirth, :DateoFdeath, :mother, :father, :heir, :house, :spouse, :book1, :book2, :book3, :book4, :book5, :isAliveMother, :isAliveFather, :isAliveHeir, :isAliveSpouse, :isMarried, :isNoble, :age, :numDeadRelations, :boolDeadRelations, :isPopular, :popularity, :isAlive]
    @test size(df) == (1946, 33)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, Int, Int, Float64, Float64, String, Union{Missing, String}, Int, Union{Missing, String}, Union{Int, Missing}, Union{Int, Missing}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Int, Int, Int, Int, Int, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Int, Int, Union{Int, Missing}, Int, Int, Int, Float64, Int]]
end

@testset "comma_in_quotes.csv.gz" begin
    f = joinpath(files, "comma_in_quotes.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, quotes='"'))
    @test names(df) == [:first, :last, :address, :city, :zip]
    @test size(df) == (1, 5)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String, String, String, Int]]
end

@testset "complications-and-deaths-hospital.csv.gz" begin
    f = joinpath(files, "complications-and-deaths-hospital.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, quotes='"'))
    @test names(df) == [Symbol("Provider ID"), Symbol("Hospital Name"), :Address, :City, :State, Symbol("ZIP Code"), Symbol("County Name"), Symbol("Phone Number"), Symbol("Measure Name"), Symbol("Measure ID"), Symbol("Compared to National"), :Denominator, :Score, Symbol("Lower Estimate"), Symbol("Higher Estimate"), :Footnote, Symbol("Measure Start Date"), Symbol("Measure End Date")]
    @test size(df) == (81804, 18)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String, String]]
end

@testset "diabetes.csv.gz" begin
    f = joinpath(files, "diabetes.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1))
    @test names(df) == [:Pregnancies, :Glucose, :BloodPressure, :SkinThickness, :Insulin, :BMI, :DiabetesPedigreeFunction, :Age, :Outcome]
    @test size(df) == (768, 9)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, Int, Int, Int, Int, Float64, Float64, Int, Int]]
end

@testset "empty.csv" begin
    f = joinpath(files, "empty.csv")
    df = DataFrame(uCSV.read(f, header=1, typedetectrows=2, quotes='"', encodings=Dict("" => missing)))
    @test names(df) == [:a, :b, :c]
    @test size(df) == (2, 3)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, Union{Missing, String}, Union{Missing, String}]]
end

@testset "empty.csv.gz" begin
    f = joinpath(files, "empty.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, typedetectrows=2, quotes='"', encodings=Dict("" => missing)))
    @test names(df) == [:a, :b, :c]
    @test size(df) == (2, 3)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, Union{Missing, String}, Union{Missing, String}]]
end

@testset "empty_crlf.csv.gz" begin
    f = joinpath(files, "empty_crlf.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, typedetectrows=2, quotes='"', encodings=Dict("" => missing)))
    @test names(df) == [:a, :b, :c]
    @test size(df) == (2, 3)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, Union{Missing, String}, Union{Missing, String}]]
end

@testset "escaped_quotes.csv.gz" begin
    f = joinpath(files, "escaped_quotes.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, quotes='"', escape='"'))
    @test names(df) == [:a, :b]
    @test size(df) == (2, 2)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, String]]
end

@testset "final-cjr-quality-pr.csv.gz" begin
    f = joinpath(files, "final-cjr-quality-pr.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, quotes='"', encodings=Dict("N/A" => missing), typedetectrows=100))
    @test names(df) == [Symbol("HOSPITAL NAME"), Symbol("PROVIDER ID"), :MSA, Symbol("MSA TITLE"), Symbol("HCAHPS HLMR"), Symbol("HCAHPS START DATE"), Symbol("HCAHPS END DATE"), Symbol("HCAHPS FOOTNOTE"), Symbol("COMP-HIP-KNEE"), Symbol("COMP START DATE"), Symbol("COMP END DATE"), Symbol("COMP FOOTNOTE"), :PRO, Symbol("PRO START DATE"), Symbol("PRO END DATE"), Symbol("PRO FOOTNOTE ")]
    @test size(df) == (794, 16)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Int, Int, String, Union{Float64, Missing}, String, String, String, Union{Float64, Missing}, String, String, String, String, String, String, String]]
end

@testset "hospice-compare-casper-aspen-contacts.csv.gz" begin
    f = joinpath(files, "hospice-compare-casper-aspen-contacts.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, quotes='"', escape='"'))
    @test names(df) == [:Region, :State, :Contact, :Email, :Phone]
    @test size(df) == (64, 5)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String, String, String, String]]
end

@testset "hospice-compare-general-info.csv.gz" begin
    f = joinpath(files, "hospice-compare-general-info.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, quotes='"'))
    @test names(df) == [Symbol("CMS Certification Number (CCN)"), Symbol("Facility Name"), Symbol("Address Line 1"), Symbol("Address Line 2"), Symbol("Zip Code"), Symbol("County Name"), :PhoneNumber, Symbol("CMS Region"), Symbol("Ownership Type"), Symbol("Certification Date")]
    @test size(df) == (4489, 10)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String, String, String, String, String, String, String, String, String]]
end

@testset "hospice-compare-provider-data.csv.gz" begin
    f = joinpath(files, "hospice-compare-provider-data.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, quotes='"'))
    @test names(df) == [Symbol("CMS Certification Number (CCN)"), Symbol("Facility Name"), Symbol("Address Line 1"), Symbol("Address Line 2"), Symbol("Zip Code"), Symbol("County Name"), :PhoneNumber, Symbol("CMS Region"), Symbol("Measure Code"), Symbol("Measure Name"), :Score, :Footnote, Symbol("Start Date"), Symbol("End Date")]
    @test size(df) == (62846, 14)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String, String, String, String, String, String, String, String, String, String, String, String, String]]
end

@testset "indicators.csv.gz" begin
    f = joinpath(files, "indicators.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"'))
    @test names(df) == [:x1, :x2, :x3, :x4, :x5, :x6]
    @test size(df) == (2828229, 6)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String, String, String, Int, Float64]]
end

@testset "json.csv.gz" begin
    f = joinpath(files, "json.csv.gz")
    df = df = DataFrame(uCSV.read(GDS(open(f)), header=1, quotes='"', escape='"'))
    @test names(df) == [:key, :val]
    @test size(df) == (1, 2)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, String]]
end

@testset "latest.csv.gz" begin
    f = joinpath(files, "latest.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), encodings=Dict("\\N" => missing), typedetectrows=100))
    @test names(df) == [:x1, :x2, :x3, :x4, :x5, :x6, :x7, :x8, :x9, :x10, :x11, :x12, :x13, :x14, :x15, :x16, :x17, :x18, :x19, :x20, :x21, :x22, :x23, :x24, :x25]
    @test size(df) == (1000, 25)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String, Int, Int, String, Int, String, Int, String, String, Int, String, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Int, Missing}, Union{Float64, Missing}, Float64, Union{Float64, Missing}, Union{Float64, Missing}, Union{Int, Missing}, Float64, Union{Float64, Missing}, Union{Float64, Missing}]]
end

@testset "movie_metadata.csv.gz" begin
    f = joinpath(files, "movie_metadata.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, quotes='"', encodings=Dict("" => missing), typedetectrows=100, allowmissing=Dict(2 => true, 5 => true, 7 => true, 8 => true, 11 => true, 25 => true), types=Dict(9 => Int64, 23 => Int64)))
    @test names(df) == [:color, :director_name, :num_critic_for_reviews, :duration, :director_facebook_likes, :actor_3_facebook_likes, :actor_2_name, :actor_1_facebook_likes, :gross, :genres, :actor_1_name, :movie_title, :num_voted_users, :cast_total_facebook_likes, :actor_3_name, :facenumber_in_poster, :plot_keywords, :movie_imdb_link, :num_user_for_reviews, :language, :country, :content_rating, :budget, :title_year, :actor_2_facebook_likes, :imdb_score, :aspect_ratio, :movie_facebook_likes]
    @test size(df) == (5043, 28)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Union{Missing, String}, Union{Missing, String}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Missing, String}, Union{Int, Missing}, Union{Int64, Missing}, String, Union{Missing, String}, String, Int, Int, Union{Missing, String}, Union{Int, Missing}, Union{Missing, String}, String, Union{Int, Missing}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Int64, Missing}, Union{Int, Missing}, Union{Int, Missing}, Float64, Union{Float64, Missing}, Int]]
end

@testset "newlines.csv.gz" begin
    # TODO fix show in DataFrames, newline breaks printing
    f = joinpath(files, "newlines.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, quotes='"', typedetectrows=2))
    @test names(df) == [:a, :b, :c]
    @test size(df) == (3, 3)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Int, Int]]
end

@testset "newlines_crlf.csv.gz" begin
    f = joinpath(files, "newlines_crlf.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, quotes='"', typedetectrows=2))
    @test names(df) == [:a, :b, :c]
    @test size(df) == (3, 3)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Int, Int]]
end

@testset "0s-1s.csv.gz" begin
    f = joinpath(files, "0s-1s.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1))
    @test names(df) == [Symbol("0"), Symbol("1"), Symbol("2"), Symbol("3"), Symbol("4"), Symbol("5"), Symbol("6"), Symbol("7"), Symbol("8"), Symbol("9"), Symbol("10"), Symbol("11"), Symbol("12"), Symbol("13"), Symbol("14"), Symbol("15"), Symbol("16"), Symbol("17"), Symbol("18"), Symbol("19"), Symbol("20"), Symbol("21"), Symbol("22"), Symbol("23"), Symbol("24"), Symbol("25"), Symbol("26"), Symbol("27"), Symbol("28"), Symbol("29"), Symbol("30"), Symbol("31"), Symbol("32"), Symbol("33"), Symbol("34"), Symbol("35"), Symbol("36"), Symbol("37"), Symbol("38"), Symbol("39"), Symbol("40"), Symbol("41"), Symbol("42"), Symbol("43"), Symbol("44"), Symbol("45"), Symbol("46"), Symbol("47"), Symbol("48"), Symbol("49")]
    @test size(df) == (100000, 50)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int]]
end

@testset "payment-year-2017.csv.gz" begin
    f = joinpath(files, "payment-year-2017.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, quotes = '"', escape='"', encodings=Dict("" => missing, "-" => missing, "No Score" => missing, "N/A" => missing), typedetectrows=1000, allowmissing=true))
    @test names(df) == [Symbol("Facility Name"), Symbol("CMS Certification Number (CCN)"), Symbol("Alternate CCN 1"), Symbol("Address 1"), Symbol("Address 2"), :City, :State, Symbol("Zip Code"), :Network, Symbol("VAT Catheter Measure Score"), Symbol("VAT Catheter Achievement Measure Rate"), Symbol("Number of Patients Included in VAT Catheter Measure Score Achievement Period"), Symbol("VAT Catheter Achievement Period Numerator"), Symbol("VAT Catheter Achievement Period Denominator"), Symbol("VAT Catheter Improvement Measure Rate"), Symbol("VAT Catheter Improvement Period Numerator"), Symbol("VAT Catheter Improvement Period Denominator"), Symbol("VAT Catheter Measure Score Applied"), Symbol("VAT Fistula Measure Score"), Symbol("VAT Fistula Achievement Measure Rate"), Symbol("Number of Patients Included in VAT Fistula Measure Score Achievement Period"), Symbol("VAT Fistula Achievement Period Numerator"), Symbol("VAT Fistula Achievement Period Denominator"), Symbol("VAT Fistula Improvement Measure Rate"), Symbol("VAT Fistula Improvement Period Numerator"), Symbol("VAT Fistula Improvement Period Denominator"), Symbol("VAT Fistula Measure Score Applied"), Symbol("VAT Combined Measure Score"), Symbol("National Avg VAT Combined Measure Score"), Symbol("Kt/V Adult Hemodialysis Measure Score"), Symbol("Kt/V Adult Hemodialysis Achievement Measure Rate"), Symbol("Number of Patients Included in  Kt/V Adult Hemodialysis Measure Score Achievement Period"), Symbol("Kt/V Adult Hemodialysis Achievement Period Numerator"), Symbol("Kt/V Adult Hemodialysis Achievement Period Denominator"), Symbol("Kt/V Adult Hemodialysis Improvement Measure Rate"), Symbol("Kt/V Adult Hemodialysis Improvement Period Numerator"), Symbol("Kt/V Adult Hemodialysis Improvement Period Denominator"), Symbol("Kt/V Adult Hemodialysis Measure Score Applied"), Symbol("Kt/V Adult Peritoneal Dialysis Measure Score"), Symbol("Kt/V Adult Peritoneal Dialysis Achievement Measure Rate"), Symbol("Number of Patients Included in  Kt/V Adult Peritoneal Dialysis Measure Score Achievement Period"), Symbol("Kt/V Adult Peritoneal Dialysis Achievement Period Numerator"), Symbol("Kt/V Adult Peritoneal Dialysis Achievement Period Denominator"), Symbol("Kt/V Adult Peritoneal Dialysis Improvement Measure Rate"), Symbol("Kt/V Adult Peritoneal Dialysis Improvement Period Numerator"), Symbol("Kt/V Adult Peritoneal Dialysis Improvement Period Denominator"), Symbol("Kt/V Adult Peritoneal Dialysis Measure Score Applied"), Symbol("Kt/V Pediatric Hemodialysis Measure Score"), Symbol("Kt/V Pediatric Hemodialysis Achievement Measure Rate"), Symbol("Number of Patients Included in  Kt/V Pediatric Hemodialysis Measure Score Achievement Period"), Symbol("Kt/V Pediatric Hemodialysis Achievement Period Numerator"), Symbol("Kt/V Pediatric Hemodialysis Achievement Period Denominator"), Symbol("Kt/V Pediatric Hemodialysis Improvement Measure Rate"), Symbol("Kt/V Pediatric Hemodialysis Improvement Period Numerator"), Symbol("Kt/V Pediatric Hemodialysis Improvement Period Denominator"), Symbol("Kt/V Pediatric Hemodialysis Measure Score Applied"), Symbol("Kt/V Dialysis Adequacy Combined Measure Score"), Symbol("National Avg Kt/V Dialysis Adequacy Combined Measure Score"), Symbol("Hypercalcemia Measure Score"), Symbol("Hypercalcemia Achievement Measure Rate"), Symbol("Number of Patients Included in Hypercalcemia Measure Score Achievement Period"), Symbol("Hypercalcemia Achievement Period Numerator"), Symbol("Hypercalcemia Achievement Period Denominator"), Symbol("Hypercalcemia Improvement Measure Rate"), Symbol("Hypercalcemia Improvement Period Numerator"), Symbol("Hypercalcemia Improvement Period Denominator"), Symbol("Hypercalcemia Measure Score Applied"), Symbol("NHSN Measure Score"), Symbol("NHSN Achievement Measure Ratio"), Symbol("Number of Patients Included in NHSN Measure Score Achievement Period"), Symbol("NHSN Observed Achievement Period Numerator"), Symbol("NHSN Predicted Achievement Period Denominator"), Symbol("NHSN Improvement Measure Ratio"), Symbol("NHSN Observed Improvement Period Numerator"), Symbol("NHSN Predicted Improvement Period Denominator"), Symbol("NHSN Measure Score Applied"), Symbol("ICH CAHPS Admin Score"), Symbol("Mineral Metabolism Reporting Score"), Symbol("Anemia Management Reporting Score"), Symbol("SRR Measure Score"), Symbol("SRR Achievement Measure Ratio"), Symbol("SRR Index Discharges"), Symbol("SRR Achievement Period Numerator"), Symbol("SRR Achievement Period Denominator"), Symbol("SRR Improvement Measure Ratio"), Symbol("SRR Improvement Period Numerator"), Symbol("SRR Improvement Period Denominator"), Symbol("SRR Measure Score Applied"), Symbol("Total Performance Score"), Symbol("PY2017 Payment Reduction Percentage"), Symbol("CMS Certification Date"), Symbol("Ownership as of December 31, 2015"), Symbol("Date of Ownership Record Update")]
    @test size(df) == (6550, 93)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Union{Missing, String}, Union{Int, Missing}, Union{Int, Missing}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Missing, String}, Union{Missing, String}, Union{Int, Missing}, Union{Int, Missing}, Union{Missing, String}, Union{Int, Missing}, Union{Int, Missing}, Union{Missing, String}, Union{Int, Missing}, Union{Missing, String}, Union{Missing, String}, Union{Int, Missing}, Union{Int, Missing}, Union{Missing, String}, Union{Int, Missing}, Union{Int, Missing}, Union{Missing, String}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Missing, String}, Union{Missing, String}, Union{Int, Missing}, Union{Int, Missing}, Union{Missing, String}, Union{Int, Missing}, Union{Int, Missing}, Union{Missing, String}, Union{Int, Missing}, Union{Missing, String}, Union{Missing, String}, Union{Int, Missing}, Union{Int, Missing}, Union{Missing, String}, Union{Int, Missing}, Union{Int, Missing}, Union{Missing, String}, Union{Int, Missing}, Union{Missing, String}, Union{Missing, String}, Union{Int, Missing}, Union{Int, Missing}, Union{Missing, String}, Union{Int, Missing}, Union{Int, Missing}, Union{Missing, String}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Missing, String}, Union{Missing, String}, Union{Int, Missing}, Union{Int, Missing}, Union{Missing, String}, Union{Int, Missing}, Union{Int, Missing}, Union{Missing, String}, Union{Int, Missing}, Union{Missing, String}, Union{Missing, String}, Union{Int, Missing}, Union{Float64, Missing}, Union{Missing, String}, Union{Int, Missing}, Union{Float64, Missing}, Union{Missing, String}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Missing, String}, Union{Missing, String}, Union{Int, Missing}, Union{Float64, Missing}, Union{Missing, String}, Union{Int, Missing}, Union{Float64, Missing}, Union{Missing, String}, Union{Int, Missing}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}]]
end

@testset "quotes_and_newlines.csv.gz" begin
    f = joinpath(files, "quotes_and_newlines.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', escape='"', header=1, typedetectrows=2))
    @test names(df) == [:a, :b]
    @test size(df) == (2, 2)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, String]]
end

@testset "simple.csv.gz" begin
    f = joinpath(files, "simple.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1))
    @test names(df) == [:a, :b, :c]
    @test size(df) == (1, 3)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, Int, Int]]
end

@testset "simple_crlf.csv.gz" begin
    f = joinpath(files, "simple_crlf.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1))
    @test names(df) == [:a, :b, :c]
    @test size(df) == (1, 3)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, Int, Int]]
end

@testset "species.txt.gz" begin
    f = joinpath(files, "species.txt.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), delim='\t', header=1, encodings=Dict("N" => false, "Y" => true), typedetectrows=100))
    @test names(df) == [Symbol("#name"), :species, :division, :taxonomy_id, :assembly, :assembly_accession, :genebuild, :variation, :pan_compara, :peptide_compara, :genome_alignments, :other_alignments, :core_db, :species_id]
    @test size(df) == (45078, 14)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String, String, Int, String, String, String, Bool, Bool, Bool, Bool, Bool, String, Int]]
end

@testset "stocks.csv.gz" begin
    f = joinpath(files, "stocks.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1))
    @test names(df) == [Symbol("Stock Name"), Symbol("Company Name")]
    @test size(df) == (30, 2)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String]]
end

@testset "student-por.csv.gz" begin
    f = joinpath(files, "student-por.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, encodings=Dict("yes" => true, "no" => false)))
    @test names(df) == [:school, :sex, :age, :address, :famsize, :Pstatus, :Medu, :Fedu, :Mjob, :Fjob, :reason, :guardian, :traveltime, :studytime, :failures, :schoolsup, :famsup, :paid, :activities, :nursery, :higher, :internet, :romantic, :famrel, :freetime, :goout, :Dalc, :Walc, :health, :absences, :G1, :G2, :G3]
    @test size(df) == (649, 33)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String, Int, String, String, String, Int, Int, String, String, String, String, Int, Int, Int, Bool, Bool, Bool, Bool, Bool, Bool, Bool, Bool, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int]]
end

@testset "test_2_footer_rows.csv.gz" begin
    f = joinpath(files, "test_2_footer_rows.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), comment='#', header=1))
    @test names(df) == [:col1, :col2, :col3]
    @test size(df) == (3, 3)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, Int, Int]]
end

@testset "test_basic.csv.gz" begin
    f = joinpath(files, "test_basic.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1))
    @test names(df) == [:col1, :col2, :col3]
    @test size(df) == (3, 3)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, Int, Int]]
end

@testset "test_basic_pipe.csv.gz" begin
    f = joinpath(files, "test_basic_pipe.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, delim='|'))
    @test names(df) == [:col1, :col2, :col3]
    @test size(df) == (3, 3)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, Int, Int]]
end

@testset "test_crlf_line_endings.csv.gz" begin
    f = joinpath(files, "test_crlf_line_endings.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1))
    @test names(df) == [:col1, :col2, :col3]
    @test size(df) == (3, 3)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, Int, Int]]
end

@testset "test_dates.csv.gz" begin
    f = joinpath(files, "test_dates.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, types=Date))
    @test names(df) == [:col1]
    @test size(df) == (3, 1)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Date]]

    function datetimeparser(x)
        if in('.', x)
            return DateTime(x, "y-m-d H:M:S.s")
        else
            return DateTime(x, "y-m-d H:M:S")
        end
    end
    f = joinpath(files, "test_datetimes.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, colparsers=(x -> datetimeparser(x))))
    @test names(df) == [:col1]
    @test size(df) == (3, 1)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [DateTime]]
end

@testset "test_empty_file.csv.gz" begin
    f = joinpath(files, "test_empty_file.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f))))
    @test names(df) == []
    @test size(df) == (0,0)
    @test typeof.(DataFrames.columns(df)) == []
end

@testset "test_empty_file_newlines.csv.gz" begin
    f = joinpath(files, "test_empty_file_newlines.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f))))
    @test names(df) == []
    @test size(df) == (0,0)
    @test typeof.(DataFrames.columns(df)) == []
end

@testset "test_excel_date_formats.csv.gz" begin
    f = joinpath(files, "test_excel_date_formats.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, colparsers=(x -> Date(x, "m/d/y"))))
    @test names(df) == [:col1]
    @test size(df) == (3, 1)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Date]]
end

@testset "test_float_in_int_column.csv.gz" begin
    f = joinpath(files, "test_float_in_int_column.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, typedetectrows=2))
    @test names(df) == [:col1, :col2, :col3]
    @test size(df) == (3,3)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, Float64, Int]]
end

@testset "test_floats.csv.gz" begin
    f = joinpath(files, "test_floats.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1))
    @test names(df) == [:col1, :col2, :col3]
    @test size(df) == (3,3)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Float64, Float64, Float64]]
end

@testset "test_header_on_row_4.csv.gz" begin
    f = joinpath(files, "test_header_on_row_4.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1))
    @test names(df) == [:col1, :col2, :col3]
    @test size(df) == (3,3)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, Int, Int]]
end

@testset "test_missing_value.csv.gz" begin
    f = joinpath(files, "test_missing_value.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, encodings=Dict("" => missing), typedetectrows=2))
    @test names(df) == [:col1, :col2, :col3]
    @test size(df) == (3,3)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Float64, Union{Float64, Missing}, Float64]]
end

@testset "test_missing_value_NULL.csv.gz" begin
    f = joinpath(files, "test_missing_value_NULL.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, encodings=Dict("NULL" => missing), typedetectrows=2))
    @test names(df) == [:col1, :col2, :col3]
    @test size(df) == (3,3)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Float64, Union{Float64, Missing}, Float64]]
end

@testset "test_mixed_date_formats.csv.gz" begin
    f = joinpath(files, "test_mixed_date_formats.csv.gz")
    function multidateparser(x)
        if in('/', x)
            return Date(x, "m/d/y")
        else
            return Date(x, "y-m-d")
        end
    end
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, colparsers=(x -> multidateparser(x))))
    @test names(df) == [:col1]
    @test size(df) == (5,1)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Date]]
end

@testset "test_newline_line_endings.csv.gz" begin
    f = joinpath(files, "test_newline_line_endings.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1))
    @test names(df) == [:col1, :col2, :col3]
    @test size(df) == (3,3)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, Int, Int]]
end

@testset "test_no_header.csv.gz" begin
    f = joinpath(files, "test_no_header.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f))))
    @test names(df) == [:x1, :x2, :x3]
    @test size(df) == (3,3)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Float64,Float64, Float64]]
end

@testset "test_one_row_of_data.csv.gz" begin
    f = joinpath(files, "test_one_row_of_data.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f))))
    @test names(df) == [:x1, :x2, :x3]
    @test size(df) == (1,3)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, Int, Int]]
end

@testset "test_quoted_delim_and_newline.csv.gz" begin
    f = joinpath(files, "test_quoted_delim_and_newline.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, quotes='"'))
    @test names(df) == [:col1, :col2]
    @test size(df) == (1,2)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String]]
end

@testset "test_quoted_numbers.csv.gz" begin
    f = joinpath(files, "test_quoted_numbers.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1, typedetectrows=2))
    @test names(df) == [:col1, :col2, :col3]
    @test size(df) == (3, 3)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String, Int]]
end

@testset "test_simple_quoted.csv.gz" begin
    f = joinpath(files, "test_simple_quoted.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, quotes='"'))
    @test names(df) == [:col1, :col2]
    @test size(df) == (1, 2)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String]]
end

@testset "test_single_column.csv.gz" begin
    f = joinpath(files, "test_single_column.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1))
    @test names(df) == [:col1]
    @test size(df) == (3,1)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int]]
end

@testset "test_tab_missing_empty.txt.gz" begin
    f = joinpath(files, "test_tab_missing_empty.txt.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), delim='\t', typedetectrows=3, encodings=Dict("" => missing)))
    @test names(df) == [:x1, :x2, :x3, :x4]
    @test size(df) == (3, 4)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Union{Missing, String}, String, String]]
end

@testset "test_tab_missing_string.txt.gz" begin
    f = joinpath(files, "test_tab_missing_string.txt.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), delim='\t', typedetectrows=3, encodings=Dict("NULL" => missing)))
    @test names(df) == [:x1, :x2, :x3, :x4]
    @test size(df) == (3, 4)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Union{Missing, String}, String, String]]
end

@testset "test_windows.csv.gz" begin
    f = joinpath(files, "test_windows.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1))
    @test names(df) == [:col1, :col2, :col3]
    @test size(df) == (3,3)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Float64, Float64, Float64]]
end

@testset "utf8.csv.gz" begin
    f = joinpath(files, "utf8.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, typedetectrows=2))
    @test names(df) == [:a, :b, :c]
    @test size(df) == (2, 3)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, Int, String]]
end

@testset "zika.csv.gz" begin
    f = joinpath(files, "zika.csv.gz")
    df = DataFrame(uCSV.read(GDS(open(f)), header=1, quotes='"'))
    @test names(df) == [:report_date, :location, :location_type, :data_field, :data_field_code, :time_period, :time_period_type, :value, :unit]
    @test size(df) == (107609, 9)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String, String, String, String, String, String, String, String]]
end

@testset "Performance_2017Q2.txt.gz" begin
    f = joinpath(files, "Performance_2017Q2.txt.gz")
    # manually declare Float64 for consistency across 32 & 64 bit CI testing
    df = DataFrame(uCSV.read(GDS(open(f)), delim='|', allowmissing=true, encodings=Dict("" => missing), types=Dict(1 => Float64, 5 => Float64, 6 => Float64, 7 => Float64, 8 => Float64, 10 => Float64, 11 => String, 13 => Float64, 14 => String, 27 => Float64, 29 => String)))
    @test names(df) == [:x1, :x2, :x3, :x4, :x5, :x6, :x7, :x8, :x9, :x10, :x11, :x12, :x13, :x14, :x15, :x16, :x17, :x18, :x19, :x20, :x21, :x22, :x23, :x24, :x25, :x26, :x27, :x28, :x29, :x30, :x31]
    @test size(df) == (4932157, 31)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Union{Missing, Float64}, Union{Missing, String}, Union{Missing, String}, Union{Missing, Float64}, Union{Missing, Float64}, Union{Missing, Float64}, Union{Missing,Float64}, Union{Missing, Float64}, Union{Missing, String}, Union{Missing, Float64}, Union{Missing, String}, Union{Missing, String}, Union{Missing, Float64}, Union{Missing, String}, Missing, Missing, Missing, Missing, Missing, Missing, Missing, Missing, Missing, Missing, Missing, Missing, Union{Missing, Float64}, Missing, Union{Missing, String}, Missing, Union{Missing, String}]]
end

@testset "RDatasets: COUNT/loomis" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/COUNT/loomis.csv.gz"
    df = DataFrame(uCSV.read(GDS(open(f)), header = 1, typedetectrows = 100, encodings=Dict("NA" => missing), quotes='"'))
    @test names(df) == [:AnVisits, :Gender, :Income, :Income1, :Income2, :Income3, :Income4, :Travel, :Travel1, :Travel2, :Travel3]
    @test size(df) == (410, 11)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  fill(Union{Int, Missing}, 11)]
end

@testset "RDatasets: COUNT/titanic" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/COUNT/titanic.csv.gz"
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Survived, :Age, :Sex, :Class]
    @test size(df) == (1316, 4)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  fill(Int, 4)]
end

@testset "RDatasets: Ecdat/Clothing" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/Ecdat/Clothing.csv.gz" # quoted headers
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:TSales, :Sales, :Margin, :NOwn, :NFull, :NPart, :NAux, :HoursW, :HoursPW, :Inv1, :Inv2, :SSize, :Start]
    @test size(df) == (400, 13)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, Float64, Float64, Float64, Float64, Float64, Float64, Int, Float64, Float64, Float64, Int, Float64]]
end

@testset "RDatasets: Ecdat/Garch" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/Ecdat/Garch.csv.gz" # encode and transform days of week
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1, encodings=Dict("NA" => missing), typedetectrows=2))
    @test names(df) == [:Date, :Day, :DM, :DDM, :BP, :CD, :DY, :SF]
    @test size(df) == (1867, 8)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, String, Float64, Union{Float64, Missing}, Float64, Float64, Float64, Float64]]
end

@testset "RDatasets: Ecdat/Grunfeld" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/Ecdat/Grunfeld.csv.gz" # parse year
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Firm, :Year, :Inv, :Value, :Capital]
    @test size(df) == (200, 5)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, Int, Float64, Float64, Float64]]
end

@testset "RDatasets: Ecdat/Icecream" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/Ecdat/Icecream.csv.gz" # F -> C transform
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Cons, :Income, :Price, :Temp]
    @test size(df) == (30, 4)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Float64, Int, Float64, Int]]
end

@testset "RDatasets: Ecdat/MCAS" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/Ecdat/MCAS.csv.gz" # diverse data types
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1, encodings=Dict("NA" => missing), typedetectrows=34))
    @test names(df) == [:Code, :Municipa, :District, :RegDay, :SpecNeed, :Bilingua, :OccupDay, :TotDay, :SPC, :SpecEd, :LnchPct, :TCHRatio, :PerCap, :TOTSC4, :TOTSC8, :AvgSalary, :PctEl]
    @test size(df) == (220, 17)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, String, String, Int, Float64, Int, Int, Int, Union{Float64, Missing}, Float64, Float64, Float64, Float64, Int, Union{Int, Missing}, Union{Float64, Missing}, Float64]]
end

@testset "RDatasets: Ecdat/RetSchool" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/Ecdat/RetSchool.csv.gz" # NAs
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1, encodings=Dict("NA" => missing), typedetectrows=2))
    @test names(df) == [:Wage76, :Grade76, :Exp76, :Black, :South76, :SMSA76, :Region, :SMSA66, :MomDad14, :SinMom14, :NoDadEd, :NoMomEd, :DadEd, :MomEd, :FamEd, :Age76, :Col4]
    @test size(df) == (5225, 17)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Union{Float64, Missing}, Union{Int, Missing}, Union{Int, Missing}, Int, Union{Int, Missing}, Int, Int, Int, Int, Int, Int, Int, Float64, Float64, Int, Int, Int]]
end

@testset "RDatasets: Ecdat/TranspEq" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/Ecdat/TranspEq.csv.gz" # encode states as two letters
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:State, :VA, :Capital, :Labor, :NFirm]
    @test size(df) == (25, 5)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Float64, Float64, Float64, Int]]
end

@testset "RDatasets: Ecdat/incomeInequality" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/Ecdat/incomeInequality.csv.gz" # like it
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Year, :NumberThousands, :Quintile1, :Quintile2, :Median, :Quintile3, :Quintile4, :P95, :P90, :P95_1, :P99, :P99_5, :P99_9, :P99_99, :RealGDP_M, :GDPDeflator, :PopulationK, :RealGDPPerCap, :P95IRSVsCensus, :PersonsPerFamily, :RealGDPPerFamily, :MeanMedian]
    @test size(df) == (66, 22)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, Int, Int, Int, Float64, Int, Int, Int, Int, Int, Int, Int, Int, Int, Float64, Float64, Int, Float64, Float64, Float64, Float64, Float64]]
end

@testset "RDatasets: HSAUR/aspirin" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/HSAUR/aspirin.csv.gz" # ugly bibtex citations
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Study, :DP, :TP, :DA, :TA]
    @test size(df) == (7, 5)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Int, Int, Int, Int]]
end

@testset "RDatasets: HSAUR/birthdeathrates" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/HSAUR/birthdeathrates.csv.gz" # recode countries
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Country, :Birth, :Death]
    @test size(df) == (69, 3)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Float64, Float64]]
end

@testset "RDatasets: HSAUR/heptathlon" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/HSAUR/heptathlon.csv.gz" # transform countries, names
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Athlete, :Hurdles, :HighJump, :Shot, :Run200m, :LongJump, :Javelin, :Run800m, :Score]
    @test size(df) == (25, 9)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Int]]
end

@testset "RDatasets: HSAUR/meteo" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/HSAUR/meteo.csv.gz" # year range
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Year, :RainNovDec, :Temp, :RainJuly, :Radiation, :Yield]
    @test size(df) == (11, 6)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Float64, Float64, Float64, Int, Float64]]
end

@testset "RDatasets: HSAUR/pottery" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/HSAUR/pottery.csv.gz" # recode column names, transform to Kevlin
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Al2O3, :Fe2O3, :MgO, :CaO, :Na2O, :K2O, :TiO2, :MnO, :BaO]
    @test size(df) == (45, 9)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64]]
end

@testset "RDatasets: HSAUR/rearrests" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/HSAUR/rearrests.csv.gz" # convert to Freq Table
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:AdultCourt, :Rearrest, :NoRearrest]
    @test size(df) == (2, 3)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Int, Int]]
end

@testset "RDatasets: HSAUR/smoking" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/HSAUR/smoking.csv.gz" # encode ugly bibtex
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Study, :QT, :TT, :QC, :TC]
    @test size(df) == (26, 5)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Int, Int, Int, Int]]
end

@testset "RDatasets: HSAUR/voting" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/HSAUR/voting.csv.gz" # split into republican and democrat
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Representative, :HuntR, :SandmanR, :HowardD, :ThompsonD, :FreylinghuysenR, :ForsytheR, :WidnallR, :RoeD, :HeltoskiD, :RodinoD, :MinishD, :RinaldoR, :MarazitiR, :DanielsD, :PattenD]
    @test size(df) == (15, 16)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int]]
end

@testset "RDatasets: HistData/Jevons" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/HistData/Jevons.csv.gz" # multiple error encodings
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Actual, :Estimated, :Frequency, :Error]
    @test size(df) == (50, 4)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, Int, Int, Int]]
end

@testset "RDatasets: HistData/Minard.temp" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/HistData/Minard.temp.csv.gz" # strange date parsing
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Long, :Temp, :Days, :Date]
    @test size(df) == (9, 4)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Float64, Int, Int, String]]
end

@testset "RDatasets: HistData/Snow.pumps" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/HistData/Snow.pumps.csv.gz" # missing values
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1, typedetectrows=3, encodings=Dict("" => missing)))
    @test names(df) == [:Pump, :Label, :X, :Y]
    @test size(df) == (13, 4)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, Union{Missing, String}, Float64, Float64]]
end

@testset "RDatasets: HistData/Wheat.monarchs" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/HistData/Wheat.monarchs.csv.gz" # dates and roman numerals
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Name, :Start, :End, :Commonwealth]
    @test size(df) == (12, 4)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Int, Int, Int]]
end

@testset "RDatasets: KMsurv/baboon" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/KMsurv/baboon.csv.gz" # more dates
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Date, :Time, :Observed]
    @test size(df) == (152, 3)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Int, Int]]
end

@testset "RDatasets: KMsurv/bcdeter" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/KMsurv/bcdeter.csv.gz" # NA's after row detect
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1, typedetectrows=59, encodings=Dict("NA" => missing)))
    @test names(df) == [:Lower, :Upper, :Treat]
    @test size(df) == (95, 3)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, Union{Int, Missing}, Int]]
end

@testset "RDatasets: KMsurv/kidtran" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/KMsurv/kidtran.csv.gz" # boolean encodings and age groupings
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Obs, :Time, :Delta, :Gender, :Race, :Age]
    @test size(df) == (863, 6)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, Int, Int, Int, Int, Int]]
end

@testset "RDatasets: KMsurv/pneumon" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/KMsurv/pneumon.csv.gz" # lots of fun encodings
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:ChldAge, :Hospital, :MthAge, :Urban, :Alcohol, :Smoke, :Region, :Poverty, :BWeight, :Race, :Education, :NSibs, :WMonth, :SFMonth, :AgePn]
    @test size(df) == (3470, 15)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Float64, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int]]
end

@testset "RDatasets: MASS/Boston" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/MASS/Boston.csv.gz"
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Crim, :Zn, :Indus, :Chas, :NOx, :Rm, :Age, :Dis, :Rad, :Tax, :PTRatio, :Black, :LStat, :MedV]
    @test size(df) == (506, 14)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Float64, Float64, Float64, Int, Float64, Float64, Float64, Float64, Int, Int, Float64, Float64, Float64, Float64]]
end

@testset "RDatasets: MASS/beav1" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/MASS/beav1.csv.gz" # day time conversions
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Day, :Time, :Temp, :Activ]
    @test size(df) == (114, 4)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, Int, Float64, Int]]
end

@testset "RDatasets: MASS/beav2" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/MASS/beav2.csv.gz" # day time conversions
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Day, :Time, :Temp, :Activ]
    @test size(df) == (100, 4)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, Int, Float64, Int]]
end

@testset "RDatasets: MASS/caith" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/MASS/caith.csv.gz" # freqtable fun
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Color, :Fair, :Red, :Medium, :Dark, :Black]
    @test size(df) == (4, 6)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Int, Int, Int, Int, Int]]
end

@testset "RDatasets: MASS/cpus" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/MASS/cpus.csv.gz" # cpu names and convert memory
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Name, :CycT, :MMin, :MMax, :Cach, :ChMin, :ChMax, :Perf, :EstPerf]
    @test size(df) == (209, 9)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Int, Int, Int, Int, Int, Int, Int, Int]]
end

@testset "RDatasets: MASS/mammals" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/MASS/mammals.csv.gz" # animal name conversions
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Mammal, :Body, :Brain]
    @test size(df) == (62, 3)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Float64, Float64]]
end

@testset "RDatasets: MASS/newcomb" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/MASS/newcomb.csv.gz" # int parsing
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:x1]
    @test size(df) == (66, 1)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int]]
end

@testset "RDatasets: MASS/npr1" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/MASS/npr1.csv.gz" # make sure column one doesn't parse as int
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Sig, :X, :Y, :Perm, :Por]
    @test size(df) == (104, 5)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Float64, Float64, Int, Int]]
end

@testset "RDatasets: MASS/road" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/MASS/road.csv.gz" # state encodings
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:State, :Deaths, :Drivers, :PopDen, :Rural, :Temp, :Fuel]
    @test size(df) == (26, 7)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Int, Int, Float64, Float64, Int, Float64]]
end

@testset "RDatasets: MASS/waders" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/MASS/waders.csv.gz" # read letter as char
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Letter, :S1, :S2, :S3, :S4, :S5, :S6, :S7, :S8, :S9, :S10, :S11, :S12, :S13, :S14, :S15, :S16, :S17, :S18, :S19]
    @test size(df) == (15, 20)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int]]
end

@testset "RDatasets: Zelig/SupremeCourt" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/Zelig/SupremeCourt.csv.gz" # missing value bit array
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1, typedetectrows=23, encodings=Dict("NA" => missing)))
    @test names(df) == [:Rehnquist, :Stevens, :OConnor, :Scalia, :Kennedy, :Souter, :Thomas, :Ginsburg, :Breyer]
    @test size(df) == (43, 9)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, Union{Int, Missing}, Union{Int, Missing}, Int, Int, Int, Int, Int, Int]]
end

@testset "RDatasets: Zelig/approval" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/Zelig/approval.csv.gz" # month year
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Month, :Year, :Approve, :Disapprove, :Unsure, :SeptOct2001, :IraqWar, :AvgPrice]
    @test size(df) == (65, 8)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, Int, Float64, Float64, Float64, Int, Int, Float64]]
end

@testset "RDatasets: Zelig/immigration" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/Zelig/immigration.csv.gz" # lots of NAs
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1, typedetectrows=13, encodings=Dict("NA" => missing)))
    @test names(df) == [:IPIP, :Wage1992, :PrtyID, :Ideol, :Gender]
    @test size(df) == (2485, 5)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Union{Int, Missing}, Union{Float64, Missing}, Union{Int, Missing}, Union{Int, Missing}, Int]]
end

@testset "RDatasets: adehabitatLT/albatross" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/adehabitatLT/albatross.csv.gz" # fun dates and 0 in R2n followed by floats !!maybe drop!!
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1, typedetectrows=930, encodings=Dict("NA" => missing)))
    @test names(df) == [:X, :Y, :Date, :Dx, :Dy, :Dist, :Dt, :R2n, :AbsAngle, :RelAngle, :ID, :Burst]
    @test size(df) == (4400, 12)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Float64, Float64, String, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Int, Missing}, Float64, Union{Float64, Missing}, Union{Float64, Missing}, String, String]]
end

@testset "RDatasets: adehabitatLT/bear" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/adehabitatLT/bear.csv.gz" # same as above but even better
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1, encodings=Dict("NA" => missing), typedetectrows=1157))
    @test names(df) == [:X, :Y, :Date, :Dx, :Dy, :Dist, :Dt, :R2n, :AbsAngle, :RelAngle, :ID, :Burst]
    @test size(df) == (1157, 12)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Union{Int, Missing}, Union{Int, Missing}, String, Union{Int, Missing}, Union{Int, Missing}, Union{Float64, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, String, String]]
end

@testset "RDatasets: adehabitatLT/buffalo" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/adehabitatLT/buffalo.csv.gz" # again
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1, typedetectrows=1309, encodings=Dict("NA" => missing)))
    @test names(df) == [:X, :Y, :Date, :Dx, :Dy, :Dist, :Dt, :R2n, :AbsAngle, :RelAngle, :ID, :Burst, :Act]
    @test size(df) == (1309, 13)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, Int, String, Union{Int, Missing}, Union{Int, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Int, Union{Float64, Missing}, Union{Float64, Missing}, String, String, Union{Float64, Missing}]]
end

@testset "RDatasets: adehabitatLT/whale" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/adehabitatLT/whale.csv.gz" # ugly again
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1, encodings=Dict("NA" => missing), typedetectrows=181))
    @test names(df) == [:X, :Y, :Date, :Dx, :Dy, :Dist, :Dt, :R2n, :AbsAngle, :RelAngle, :ID, :Burst]
    @test size(df) == (181, 12)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Union{Float64, Missing}, Union{Float64, Missing}, String, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Int, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, String, String]]
end

@testset "RDatasets: boot/acme" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/boot/acme.csv.gz" # month parse
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Month, :Market, :Acme]
    @test size(df) == (60, 3)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Float64, Float64]]
end

@testset "RDatasets: boot/coal" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/boot/coal.csv.gz" # what kind of date is this?
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Date]
    @test size(df) == (191, 1)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Float64]]
end

@testset "RDatasets: boot/neuro" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/boot/neuro.csv.gz" # lots of NAs
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1, encodings=Dict("NA" => missing), typedetectrows=469))
    @test names(df) == [:V1, :V2, :V3, :V4, :V5, :V6]
    @test size(df) == (469, 6)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Union{Float64, Missing}, Union{Float64, Missing}, Float64, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}]]
end

@testset "RDatasets: car/Anscombe" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/car/Anscombe.csv.gz" # state conversions
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:State, :Education, :Income, :Young, :Urban]
    @test size(df) == (51, 5)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Int, Int, Float64, Int]]
end

@testset "RDatasets: car/Depredations" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/car/Depredations.csv.gz" # convert lat long into something else
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Longitude, :Latitude, :Number, :Early, :Late]
    @test size(df) == (434, 5)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Float64, Float64, Int, Int, Int]]
end

@testset "RDatasets: car/Florida" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/car/Florida.csv.gz" # counties to lowercase & dots to spaces
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:District, :Gore, :Bush, :Buchanan, :Nader, :Browne, :Hagelin, :Harris, :McReynolds, :Moorehead, :Phillips, :Total]
    @test size(df) == (67, 12)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int]]
end

@testset "RDatasets: car/Freedman" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/car/Freedman.csv.gz" # dots to spaces
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1, encodings=Dict("NA" => missing), typedetectrows=3))
    @test names(df) == [:City, :Population, :NonWhite, :Density, :Crime]
    @test size(df) == (110, 5)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Union{Int, Missing}, Float64, Union{Int, Missing}, Int]]
end

@testset "RDatasets: cluster/animals" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/cluster/animals.csv.gz"
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1, encodings=Dict("NA" => missing), typedetectrows=13))
    @test names(df) == [:Animal, :War, :Fly, :Ver, :End, :Gro, :Hai]
    @test size(df) == (20, 7)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Int, Int, Int, Union{Int, Missing}, Union{Int, Missing}, Int]]
end

@testset "RDatasets: cluster/votes.repub" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/cluster/votes.repub.csv.gz" # headers to dates
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1, encodings=Dict("NA" => missing), typedetectrows=5))
    @test names(df) == [:State, :x1856, :x1860, :x1864, :x1868, :x1872, :x1876, :x1880, :x1884, :x1888, :x1892, :x1896, :x1900, :x1904, :x1908, :x1912, :x1916, :x1920, :x1924, :x1928, :x1932, :x1936, :x1940, :x1944, :x1948, :x1952, :x1956, :x1960, :x1964, :x1968, :x1972, :x1976]
    @test size(df) == (50, 32)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Float64, Float64, Float64, Float64, Float64]]
end

@testset "RDatasets: datasets/HairEyeColor" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/datasets/HairEyeColor.csv.gz" # categorical recode
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Hair, :Eye, :Sex, :Freq]
    @test size(df) == (32, 4)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String, String, Int]]
end

@testset "RDatasets: datasets/Titanic" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/datasets/Titanic.csv.gz" # categorical recode
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Class, :Sex, :Age, :Survived, :Freq]
    @test size(df) == (32, 5)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String, String, String, Int]]
end

@testset "RDatasets: datasets/attenu" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/datasets/attenu.csv.gz"
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Event, :Mag, :Station, :Dist, :Accel]
    @test size(df) == (182, 5)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, Float64, String, Float64, Float64]]
end

@testset "RDatasets: datasets/UCBAdmissions" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/datasets/UCBAdmissions.csv.gz" # categorical recode
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Admit, :Gender, :Dept, :Freq]
    @test size(df) == (24, 4)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String, String, Int]]
end

@testset "RDatasets: datasets/USJudgeRatings" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/datasets/USJudgeRatings.csv.gz" # judge name processing
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Judge, :Cont, :Intg, :Dmnr, :Dilg, :Cfmg, :Deci, :Prep, :Fami, :Oral, :Writ, :Phys, :Rten]
    @test size(df) == (43, 13)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64]]
end

@testset "RDatasets: datasets/VADeaths" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/datasets/VADeaths.csv.gz" # age range
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Age, :RuralMale, :RuralFemale, :UrbanMale, :UrbanFemale]
    @test size(df) == (5, 5)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Float64, Float64, Float64, Float64]]
end

@testset "RDatasets: datasets/mtcars" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/datasets/mtcars.csv.gz" # have to
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Model, :MPG, :Cyl, :Disp, :HP, :DRat, :WT, :QSec, :VS, :AM, :Gear, :Carb]
    @test size(df) == (32, 12)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Float64, Int, Float64, Int, Float64, Float64, Float64, Int, Int, Int, Int]]
end

@testset "RDatasets: datasets/randu" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/datasets/randu.csv.gz" # exponential parsing of numerics
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:X, :Y, :Z]
    @test size(df) == (400, 3)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Float64, Float64, Float64]]
end

@testset "RDatasets: gap/PD" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/gap/PD.csv.gz" # so ugly
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1, encodings=Dict("" => missing, "NA" => missing), typedetectrows=6))
    @test names(df) == [:Lab, :APOE, :RS10506151, :RS10784486, :RS1365763, :RS1388598, :RS1491938, :RS1491941, :M770, :Int4, :SNCA, :ABC, :Diag, :Sex, :Race, :Aon, :Comments, :PD, :APOE234, :APOE2, :APOE3, :APOE4]
    @test size(df) == (825, 22)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, String, Union{Missing, String}, String, Union{Missing, String}, Union{Int, Missing}, Union{Missing, String}, Int, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}]]
end

@testset "RDatasets: gap/lukas" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/gap/lukas.csv.gz" # MF sex recoding
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:ID, :Father, :Mother, :Sex]
    @test size(df) == (85, 4)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, Int, Int, String]]
end

@testset "RDatasets: gap/mao" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/gap/mao.csv.gz" # Int and Int/Int
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1, encodings=Dict("NA" => missing), typedetectrows=63))
    @test names(df) == [:ID, :Type, :Gender, :Age, :AAO, :AAD, :UPDRS, :MAOAI2, :AI2Code, :MAOBI2, :BI2Code, :GTBEX3, :BEX3Code, :MAOAVNTR, :VNTRCode, :VNTRCod2, :MAOA31, :MAO31COD, :MAO31CO2]
    @test size(df) == (340, 19)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Int, Int, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, String, String, String, String, String, String, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}, Union{Missing, String}]]
end

@testset "RDatasets: ggplot2/economics" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/ggplot2/economics.csv.gz" # more dates
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Date, :PCE, :Pop, :PSavert, :UEmpMed, :Unemploy]
    @test size(df) == (478, 6)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Float64, Int, Float64, Float64, Int]]
end

@testset "RDatasets: ggplot2/presidential" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/ggplot2/presidential.csv.gz" # more dates
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Name, :Start, :End, :Party]
    @test size(df) == (10, 4)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String, String, String]]
end

@testset "RDatasets: plyr/baseball" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/plyr/baseball.csv.gz" # lots of NAs
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1, encodings=Dict("NA" => missing), typedetectrows=953))
    @test names(df) == [:NumID, :ID, :Year, :Stint, :Team, :LG, :G, :AB, :R, :H, :X2B, :X3B, :HR, :RBI, :SB, :CS, :BB, :SO, :IBB, :HBP, :SH, :SF, :GIDP]
    @test size(df) == (21699, 23)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, String, Int, Int, String, Union{Missing, String}, Int, Int, Int, Int, Int, Int, Int, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Int, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}]]
end

@testset "RDatasets: pscl/ca2006" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/pscl/ca2006.csv.gz" # true false encodings
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1, encodings=Dict("NA" => missing), typedetectrows=42))
    @test names(df) == [:District, :D, :R, :Other, :IncParty, :IncName, :Open, :Contested, :Bush2004, :Kerry2004, :Other2004, :Bush2000, :Gore2000]
    @test size(df) == (53, 13)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, String, Union{Missing, String}, String, String, Int, Int, Int, Int, Int]]
end

@testset "RDatasets: pscl/presidentialElections" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/pscl/presidentialElections.csv.gz" # different true false
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:State, :DemVote, :Year, :South]
    @test size(df) == (1047, 4)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Float64, Int, String]]
end

@testset "RDatasets: pscl/UKHouseOfCommons" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/pscl/UKHouseOfCommons.csv.gz"
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Constituency, :County, :Y1, :Y2, :Y1Lag, :Y2Lag, :ConInc, :LabInc, :LibInc, :V1, :V2, :V3]
    @test size(df) == (521, 12)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String, Float64, Float64, Float64, Float64, Int, Int, Int, Float64, Float64, Float64]]
end

@testset "RDatasets: psych/Reise" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/psych/Reise.csv.gz" # make headers and first column the same
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Variable, :Phone, :Routine, :Illness, :Listen, :Explain, :Respect, :Time, :Courtesy, :Helpful, :Happy, :Referral, :Necessary, :Delay, :Problem, :Help, :Paperwork]
    @test size(df) == (16, 17)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64]]
end

@testset "RDatasets: psych/Schmid" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/psych/Schmid.csv.gz" # another freqtable
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Variable, :V1, :V2, :V3, :V4, :V5, :V6, :V7, :V8, :V9, :V10, :V11, :V12]
    @test size(df) == (12, 13)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64]]
end

@testset "RDatasets: psych/Thurstone" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/psych/Thurstone.csv.gz" # another freqtable with recodings
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Variable, :Sentences, :Vocabulary, :SentCompletion, :FirstLetters, :FourLetterWords, :Suffixes, :LetterSeries, :Pedigrees, :LetterGroup]
    @test size(df) == (9, 10)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64]]
end

@testset "RDatasets: psych/bfi" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/psych/bfi.csv.gz" # late NAs
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1, encodings=Dict("NA" => missing), typedetectrows=525))
    @test names(df) == [:Variable, :A1, :A2, :A3, :A4, :A5, :C1, :C2, :C3, :C4, :C5, :E1, :E2, :E3, :E4, :E5, :N1, :N2, :N3, :N4, :N5, :O1, :O2, :O3, :O4, :O5, :Gender, :Education, :Age]
    @test size(df) == (2800, 29)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Int, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Int, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Int, Union{Int, Missing}, Int]]
end

@testset "RDatasets: psych/neo" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/psych/neo.csv.gz" # freqtable recodings
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Variable, :N1, :N2, :N3, :N4, :N5, :N6, :E1, :E2, :E3, :E4, :E5, :E6, :O1, :O2, :O3, :O4, :O5, :O6, :A1, :A2, :A3, :A4, :A5, :A6, :C1, :C2, :C3, :C4, :C5, :C6]
    @test size(df) == (30, 31)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64]]
end

@testset "RDatasets: robustbase/Animals2" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/robustbase/Animals2.csv.gz" # unsure
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Animal, :Body, :Brain]
    @test size(df) == (65, 3)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Float64, Float64]]
end

@testset "RDatasets: robustbase/ambientNOxCH" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/robustbase/ambientNOxCH.csv.gz" # scattered NAs
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1, encodings=Dict("NA" => missing), typedetectrows=68))
    @test names(df) == [:Date, :AD, :BA, :EF, :LA, :LU, :RE, :RI, :SE, :SI, :ST, :SU, :SZ, :ZG]
    @test size(df) == (366, 14)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}, Union{Float64, Missing}]]
end

@testset "RDatasets: robustbase/condroz" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/robustbase/condroz.csv.gz" # fun pH conversion
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Ca, :pH]
    @test size(df) == (428, 2)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Float64, Float64]]
end

@testset "RDatasets: robustbase/education" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/robustbase/education.csv.gz" # state recodings
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:State, :Region, :X1, :X2, :X3, :Y]
    @test size(df) == (50, 6)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Int, Int, Int, Int, Int]]
end

@testset "RDatasets: sem/Tests" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/sem/Tests.csv.gz" # late NAs
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1, encodings=Dict("NA" => missing), typedetectrows=19))
    @test names(df) == [:X1, :X2, :X3, :Y1, :Y2, :Y3]
    @test size(df) == (32, 6)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}]]
end

@testset "RDatasets: survival/lung" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/survival/lung.csv.gz" # 1-2 status and late NAs
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1, encodings=Dict("NA" => missing), typedetectrows=206))
    @test names(df) == [:Inst, :Time, :Status, :Age, :Sex, :PhECOG, :PhKarno, :PatKarno, :MealCal, :WtLoss]
    @test size(df) == (228, 10)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [Union{Int, Missing}, Int, Int, Int, Int, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}, Union{Int, Missing}]]
end

@testset "RDatasets: vcd/Bundesliga" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/vcd/Bundesliga.csv.gz" # year column & date column!
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:HomeTeam, :AwayTeam, :HomeGoals, :AwayGoals, :Round, :Year, :Date]
    @test size(df) == (14018, 7)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String, Int, Int, Int, Int, String]]
end

@testset "RDatasets: vcd/Employment" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/vcd/Employment.csv.gz" # employment length
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:EmploymentStatus, :EmploymentLength, :LayoffCause, :Freq]
    @test size(df) == (24, 4)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String, String, Int]]
end

@testset "RDatasets: vcd/PreSex" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/vcd/PreSex.csv.gz" # encodings
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:MaritalStatus, :ExtramaritalSex, :PremaritalSex, :Gender, :Freq]
    @test size(df) == (16, 5)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String, String, String, Int]]
end

@testset "RDatasets: vcd/RepVict" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/vcd/RepVict.csv.gz" # FreqTable
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Crime, :Rape, :Assault, :Robbery, :Pickpocket, :PersonalLarcency, :Burglary, :HouseholdLarceny, :AutoTheft]
    @test size(df) == (8, 9)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, Int, Int, Int, Int, Int, Int, Int, Int]]
end

@testset "RDatasets: vcd/Lifeboats" begin
    f = "$(dirname(dirname(pathof(RDatasets))))/data/vcd/Lifeboats.csv.gz" # dates
    df = DataFrame(uCSV.read(GDS(open(f)), quotes='"', header=1))
    @test names(df) == [:Launch, :Side, :Boat, :Crew, :Men, :Women, :Total, :Cap]
    @test size(df) == (18, 8)
    @test typeof.(DataFrames.columns(df)) == [Vector{T} for T in
                                  [String, String, String, Int, Int, Int, Int, Int]]
end
