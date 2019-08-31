using VegaLite
using Test

@testset "MimeWrapper" begin

p = @vlplot(:point)

mp = VegaLite.MimeWrapper{MIME"image/png"}(p)

@test showable("application/vnd.vegalite.v3+json", mp) == false
@test showable("image/png", mp) == true

end
