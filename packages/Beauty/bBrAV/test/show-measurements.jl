using Unitful
using Unitful: @u_str
@testset "Measurements, Unitful" begin
    using Measurements
    @testset "ASCII" begin
        @test showoutput("text/plain", (25±5)u"°C") == "25(5) °C"
        # To Do: Consider rewritting tests in this more succint format
        @test showoutput("text/plain", ((1.5±1.2)*1.0e8u"m")) ==
            "1.5(1.2)*10^8 m"
        v, s = (big"80.99999999999999999999999999999999999999999999999999999999999999999998600940694", "81.00")
        @test showoutput("text/plain", (v±0)u"mm") == string(s," mm")
    end
    @testset "HTML" begin
        @test showoutput("text/html", ((100.2±0.5)u"m")) ==
            "100.2(5)&nbsp;m"
        @test showoutput("text/html", ((100.2±0.5)u"l/s")) ==
            "100.2(5)&nbsp;l s<sup>-1</sup>"
        @test showoutput(
            "text/html",
            ((8.1±2.9)*1e-11u"mbar*l/s/cm^2")
        ) == string(
            "8(3)&middot;10<sup>-11</sup>&nbsp;",
            "mbar l cm<sup>-2</sup> s<sup>-1</sup>"
        )
    end
    @testset "unicode via :$opt" for opt in [
        # separate options that can be used to turn on unicode output
        :unicode => true, # sadly non-standard
        #:color => true # show assumes all color terminals accept
                        # unicode (problem: this actually does produce
                        # color output which we don't test for)
    ]
        # To Do: Consider rewritting tests in this more succint format
        @test showoutput("text/plain", ((100.2±0.5)u"m"), opt) ==
            "100.2(5) m"
        @test showoutput("text/plain", ((-100.2±0.5)u"m"), opt) == "-100.2(5) m"
        @test showoutput("text/plain", ((100.2±1.2)u"m"), opt) == "100.2(1.2) m"
        @test showoutput("text/plain", ((100±1)u"m"), opt) == "100.0(1.0) m"
        @test showoutput("text/plain", ((100.2±80)u"m"), opt) == "100(80) m"
        @test showoutput("text/plain", ((99.8±80)u"m"), opt) == "100(80) m"
        @test showoutput("text/plain", ((1000.2±80)u"m"), opt) == "1000(80) m"
        @test showoutput("text/plain", ((9000.2±120)u"m"), opt) == "9000(120) m"
        @test showoutput("text/plain", ((10.23±0.1)u"m"), opt) == "10.23(10) m"
        @test showoutput("text/plain", ((10.23±0.2)u"m"), opt) == "10.2(2) m"
        @test showoutput("text/plain", ((102.2±1.0)u"m"), opt) == "102.2(1.0) m"
        @test showoutput("text/plain", ((100.2±0.2)u"m"), opt) == "100.2(2) m"
        @test showoutput("text/plain", ((100.2±0.1)u"m"), opt) == "100.2 m"
        @test showoutput("text/plain", ((100.2±0.5)*1e6u"m"), opt) == "1.002(5)·10⁸ m"
        @test showoutput("text/plain", ((100.2±0.49)*1e-10u"m"), opt) == "10.02(5) nm"
        @test showoutput("text/plain", ((100.2±0.49)*1e-19u"m"), opt) == "1.002(5)·10⁻¹⁷ m"
    end
end
