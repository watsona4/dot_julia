# io.jl

module IOTest

using Test
using QDates

@testset "string/show representation of QDate" begin
    qdt = QDates.QDate(2018, 11, 27)
    @test string(qdt) == sprint(show, qdt) == "旧2018年11月27日"
    qdtl = QDates.QDate(2017, 5, true, 1)
    @test string(qdtl) == sprint(show, qdtl) == "旧2017年閏05月01日"
end

end