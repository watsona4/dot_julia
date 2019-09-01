@debug("test Error system")

let x="1"
    @test nothing == Base.showerror(stderr, G.GeoException)
    @test nothing == Base.showerror(stderr, G.InValidDetectorDim)
    @test nothing == Base.showerror(stderr, G.NotImplementedError)
    @test nothing == Base.showerror(stderr, G.InValidGeometry)
    @test occursin("GeoException", sprint(showerror, G.GeoException))
    @test occursin("InValidDetectorDim", sprint(showerror, G.InValidDetectorDim))
    @test occursin("NotImplementedError", sprint(showerror, G.NotImplementedError))
    @test occursin("InValidGeometry", sprint(showerror, G.InValidGeometry))

    @test nothing == G.@validateDetector true
    @test nothing == G.@validateDetector true "massage"
    @test nothing == G.@validateDetector true "massage $x"
    @test nothing == G.@validateDetector true "massage1" * "massage2"
    @test nothing == G.@validateDetector true "massage1" "massage2"
    @test nothing == G.@validateDetector true 1
    @test nothing == G.@validateDetector true :x
    @test nothing == G.@validateDetector true :(a+b)

    @test_throws    G.InValidDetectorDim    G.@validateDetector false
    @test_throws    G.InValidDetectorDim    G.@validateDetector false "massage"
    @test_throws    G.InValidDetectorDim    G.@validateDetector false "massage $x"
    @test_throws    G.InValidDetectorDim    G.@validateDetector false "massage1" * "massage2"
    @test_throws    G.InValidDetectorDim    G.@validateDetector false "massage1" "massage2"
    @test_throws    G.InValidDetectorDim    G.@validateDetector false 1
    @test_throws    G.InValidDetectorDim    G.@validateDetector false :x
    @test_throws    G.InValidDetectorDim    G.@validateDetector false :(a+b)


    @test_throws    G.NotImplementedError   G.@notImplementedError
    @test_throws    G.NotImplementedError   G.@notImplementedError "massage"
    @test_throws    G.NotImplementedError   G.@notImplementedError "massage $x"
    @test_throws    G.NotImplementedError   G.@notImplementedError "massage1" "massage2"
    @test_throws    G.NotImplementedError   G.@notImplementedError "massage1" * "massage2"
    @test_throws    G.NotImplementedError   G.@notImplementedError  1
    @test_throws    G.NotImplementedError   G.@notImplementedError  :x
    @test_throws    G.NotImplementedError   G.@notImplementedError  :(a+b)


    @test_throws    G.InValidGeometry   G.@inValidGeometry
    @test_throws    G.InValidGeometry   G.@inValidGeometry "massage"
    @test_throws    G.InValidGeometry   G.@inValidGeometry "massage $x"
    @test_throws    G.InValidGeometry   G.@inValidGeometry "massage1" "massage2"
    @test_throws    G.InValidGeometry   G.@inValidGeometry "massage1" * "massage2"
    @test_throws    G.InValidGeometry   G.@inValidGeometry  1
    @test_throws    G.InValidGeometry   G.@inValidGeometry  :x
    @test_throws    G.InValidGeometry   G.@inValidGeometry  :(a+b)


    @test G.@to_string("massage")    == "massage"
    @test G.@to_string("")           ==  ""
    @test G.@to_string("5" * "l")    == "5l"

    @test G.@to_string(:(1+x))       ==  "1 + x"
    @test G.@to_string(:(1+$x)) ==  "1 + 1" || G.@to_string(:(1+$x)) ==  "1 + \"1\""
    
    @test G.@to_string(:x) ==  ":x" ||  G.@to_string(:x)  ==  "x"   # for Compt with Julia 0.6
    
    @test G.@to_string(true)         == "true"
    @test G.@to_string(1)            == "1"
    @test G.@to_string(1+2)          == "3"

    @test G.@to_string(+)            == "+"
end