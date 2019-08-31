# setup abbreviations for units
m = Unitful.m
V = Unitful.V
A = Unitful.A
W = Unitful.W

"""Helper for tests: Capture the output of show(io, mime, x)."""
function showoutput(
    mime::String,
    x::Unitful.AbstractQuantity,
    options...
)
    buffer = IOBuffer()
    io = IOContext(buffer, options...)
    #show(io, mime, x)
    Beauty._show(io, mime, x) # transitional
    return String(take!(buffer))
end
showoutput(x::Unitful.AbstractQuantity, options...) =
    showoutput("text/plain", x, options...)

# actual tests
@testset "Unit $u" for u in [m, V, A, W]
    @test showoutput(1u, :unicode => false) == "1 $u"
    @test showoutput(1u//100, :unicode => false) == "10 m$u"
    @test showoutput(1u//1_000_000, :unicode => false) == "1 μ$u"
    @test showoutput(1u*100_000, :unicode => false) == "100 k$u"
end
