using QueryTables
using Test

@testset "QueryTables" begin

dt1 = DataTable(a=[1,2,3], b=[4.,5.,6.], c=["John", "Sally", "Jim"])

@testset "Core" begin

@test length(dt1) == 3
@test dt1.a == [1,2,3]
@test dt1.b == [4.,5.,6.]
@test dt1.c == ["John", "Sally", "Jim"]
@test dt1[1] == (a=1, b=4., c="John")
@test dt1[2] == (a=2, b=5., c="Sally")
@test dt1[3] == (a=3, b=6., c="Jim")

@test collect(dt1) == [(a=1, b=4., c="John"), (a=2, b=5., c="Sally"), (a=3, b=6., c="Jim")]

dt2 = DataTable([(a=1, b=4., c="John"), (a=2, b=5., c="Sally"), (a=3, b=6., c="Jim")])

@test dt1 == dt2

end

@testset "show" begin

@test sprint(show, dt1) ==
    "3x3 DataTable\na │ b   │ c    \n──┼─────┼──────\n1 │ 4.0 │ John \n2 │ 5.0 │ Sally\n3 │ 6.0 │ Jim  "

@test sprint((stream,data)->show(stream, "text/plain", data), dt1) ==
    "3x3 DataTable\na │ b   │ c    \n──┼─────┼──────\n1 │ 4.0 │ John \n2 │ 5.0 │ Sally\n3 │ 6.0 │ Jim  "

@test sprint((stream,data)->show(stream, "text/html", data), dt1) ==
    "<table><thead><tr><th>a</th><th>b</th><th>c</th></tr></thead><tbody><tr><td>1</td><td>4.0</td><td>&quot;John&quot;</td></tr><tr><td>2</td><td>5.0</td><td>&quot;Sally&quot;</td></tr><tr><td>3</td><td>6.0</td><td>&quot;Jim&quot;</td></tr></tbody></table>"

@test sprint((stream,data)->show(stream, "application/vnd.dataresource+json", data), dt1) ==
    "{\"schema\":{\"fields\":[{\"name\":\"a\",\"type\":\"integer\"},{\"name\":\"b\",\"type\":\"number\"},{\"name\":\"c\",\"type\":\"string\"}]},\"data\":[{\"a\":1,\"b\":4.0,\"c\":\"John\"},{\"a\":2,\"b\":5.0,\"c\":\"Sally\"},{\"a\":3,\"b\":6.0,\"c\":\"Jim\"}]}"

@test showable("text/html", dt1) == true
@test showable("application/vnd.dataresource+json", dt1) == true

end

end
