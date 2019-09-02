using PhilipsHue, Colors, Test

println("loaded PhilipsHue")

# for a proper test, supply the IP and username for an active bridge!

B = PhilipsHueBridge(
    "192.168.1.2",
    "50iUI23ZkGnvLN9SvC8xbU-kxJnZjcNd4RCPiELK")

if !isinitialized(B)
    @info "cursory tests passed, there being no bridge available"
else
    lightnumbers = getlightnumbers(B)

    @test isa(lightnumbers, Array{Int64, 1})

    firstlight = first(lightnumbers)
    @test isa(firstlight, Int64)

    println("Bridge config: \n\t"       , getbridgeconfig(B))
    println("Bridge IP: \n\t"           , getIP())
    println("Bridge initialized?: \n\t" , isinitialized(B))
    println("Light config: \n\t"        , getlights(B))
    println("Get light config: \n\t"    , getlight(B, firstlight))
    println("Get light config: \n\t"    , getlight(B, 4))

    println("Set first light on: \n\t"  , setlight(B, firstlight, Dict("on" => true)))
    println("Set first light off: \n\t" , setlight(B, firstlight, Dict("on" => false)))
    println("Set first light  \n\t"     , setlight(B, firstlight, Dict("on" => true, "sat" => 123, "bri" => 243, "hue" => 123)))

    # random change all lights
    for i in 1:3
        setlights(B, Dict("bri" => rand(0:255), "hue" => rand(1:65000), "sat" => rand(1:255)))
        sleep(0.1)
    end

    # for a random light, set RGB color

    # Thanks, @ScottPJones!
    for r in 0:0.25:1, g in 0:0.25:1, b in 0:0.25:1
        setlight(B, lightnumbers[rand(1:end)], Colors.RGB(r, g, b))
        sleep(.25)
    end

    setlights(B, Dict("bri" => 255))
end
