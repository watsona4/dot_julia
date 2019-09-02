module PhilipsHue

using JSON, HTTP, Colors

export  PhilipsHueBridge,
        getIP,
        getbridgeinfo,
        getbridgeconfig,
        isinitialized,
        getlights,
        getlight,
        getlightnumbers,
        setlight,
        setlights,
        randomcolors,
        testlights,
        register,
        initialize

mutable struct PhilipsHueBridge
    ip::AbstractString
    username:: AbstractString
    function PhilipsHueBridge(ip, username = "")
        fields = split(ip,'.')
        if length(fields) != 4
            throw(ArgumentError("IP address must have exactly four components."))
        end
        for f in fields
            fint = parse(Int, f)
            if fint < 0 || fint > 255
                throw(ArgumentError("IP address components must be between 0 and 255."))
            end
        end
        new(ip, username)
    end
end

"""
Initialize a bridge for the first time, supplying a devicetype (app name).
Registering this script with the bridge may require you to run to the bridge
and press the button.

The returned username is stored in the bridge.username. This is needed for
future use, so you should remember it.

Returns true or false.

For example:

    B = PhilipsHueBridge("192.168.1.2")
    initialize(bridge::PhilipsHueBridge; devicetype="juliascript#user1")
    testlights(B)

    # B.username is something like "2e4bdae26d734a73aeec4c21d4fd6"

then in a future Julia session you can do:

    B = PhilipsHueBridge("192.168.1.2", "2e4bdae26d734a73aeec4c21d4fd6")
    testlights(B)

"""
function initialize(bridge::PhilipsHueBridge; devicetype="juliascript#user1")
    println("initialize(): Trying to get the IP address of the Philips bridge.")
    ipaddress = "192.168.1.2"
    try
        ipaddress = getIP()
    catch e
        println("error was $e")
        return false
    end
    bridge.ip = ipaddress
    println("initialize(): Found bridge at $(bridge.ip).")
    println("initialize(): Trying to register $devicetype with the bridge at $(bridge.ip)...")
    username = register(bridge.ip, devicetype=devicetype)
    if ! isempty(username)
        println("initialize(): Registration successful")
        # save username in bridge
        bridge.username = username
        println("your username is $username")
        return true
    else
        @warn("initialize(): Registration failed")
        return false
    end
end

"""
    isinitialized(bridge::PhilipsHueBridge)

Return true if the bridge has been initialized, and there is a connection to the portal.
"""
function isinitialized(bridge::PhilipsHueBridge)
    result = false
    try
        if getbridgeconfig(bridge)["portalconnection"] == "connected"
            result = true
        else
            result = false
        end
    catch e
        println("Bridge isn't initialized: error was $e")
        result = false
    end
    return result
end
"""
    getIP()

Read the bridge's IP settings from the [meethue.com]("https://www.meethue.com/api/nupnp") website.
"""
function getIP()
    response = HTTP.request("GET", "https://www.meethue.com/api/nupnp")
    # this url sometimes redirect, we should follow...
    if response.status == 302
        println("trying curl instead, in case of redirects")
        bridgeinfo = JSON.parse(read(`curl -sL http://www.meethue.com/api/nupnp`, String))
    else
        bridgeinfo = JSON.parse(String(response.body))
    end
    return bridgeinfo[1]["internalipaddress"]
end

"""
    B = PhilipsHueBridge("192.168.1.90", "username")
    getbridgeconfig(B)

Read the current bridge configuration. For example:
"""
getbridgeconfig(bridge::PhilipsHueBridge) = getbridgeinfo(bridge, "config")

"""
    getbridgeinfo(bridge[, category::String])

Get some information from the bridge. Category can be one of:

- "lights" resource which contains all the light resources
- "groups" resource which contains all the groups
- "config" resource which contains all the configuration items
- "schedules" which contains all the schedules
- "scenes" which contains all the scenes
- "sensors" which contains all the sensors
- "rules" which contains all the rules

Default is "config".
"""
function getbridgeinfo(bridge::PhilipsHueBridge, category::String="config")
    categories = ["lights", "groups", "config", "schedules", "scenes", "sensors", "rules"]
    if category in categories
        response = HTTP.request("GET", "http://$(bridge.ip)/api/$(bridge.username)/$category")
        return JSON.parse(String(response.body))
    else
        error("category must be one of $categories")
    end
end

"""
    getlightnumbers(bridge::PhilipsHueBridge)

Return the numbers of lights connected to the bridge.

Returns eg:

    [1, 3, 5, 6]
"""
function getlightnumbers(bridge::PhilipsHueBridge)
  return map(x -> parse(Int, x), collect(keys(getlights(bridge))))
end

"""
    getlights(bridge::PhilipsHueBridge)

Return the current settings of all lights connected to the bridge.
"""
function getlights(bridge::PhilipsHueBridge)
    response = HTTP.request("GET", "http://$(bridge.ip)/api/$(bridge.username)/lights")
    return JSON.parse(String(response.body))
end

"""
    getlight(bridge::PhilipsHueBridge, light=1)

Return the settings of the specified light. Note that if you have four lights,
they are not necessarily going to be numbered 1, 2, 3, 4.

Returns response.

"""
function getlight(bridge::PhilipsHueBridge, light)
    if ! in(light, getlightnumbers(bridge))
        return("no light with number $(light). Try using getlightnumbers().")
    end
    response = HTTP.request("GET", "http://$(bridge.ip)/api/$(bridge.username)/lights/$(string(light))")
    return JSON.parse(String(response.body))
end

"""
    setlight(B, 1, Dict("on" => true))
    setlight(B, 3, Dict("on" => false))
    setlight(B, 2, Dict("on" => true, "sat" => 123, "bri" => 243, "hue" => 123)

Set a light by passing a dictionary of settings.

eg Dict{Any,Any}("on" => true, "sat" => 123, "bri" => 123, "hue" => 123),
"hue" is from 0 to 65535, "sat" and "bri" are saturation and brightness from 1 to 254,
0 is red, yellow is 12750, green is 25500, blue is 46920, etc.

If keys are omitted, that aspect of the light won't be changed.

Keys are AbstractStrings, values can be numeric and will get converted to AbstractStrings
"""
function setlight(bridge::PhilipsHueBridge, light::Int, settings::Dict)
    if ! in(light, getlightnumbers(bridge))
        return("no light with number $(light). Try using getlightnumbers().")
    end
    state = AbstractString[]
    for (k, v) in settings
        push!(state, ("\"$k\": $(string(v))"))
    end
    state = "{" * join(state, ",") * "}"
    response = HTTP.request("PUT", "http://$(bridge.ip)/api/$(bridge.username)/lights/$(string(light))/state", body="$(state)")
    return JSON.parse(String(response.body))
end

"""
    setlight(bridge::PhilipsHueBridge, light::Int, col::ColorTypes.Colorant)
    setlight(B, 1, Colors.RGB(0.75, 0.25, 0.75))
    setlight(B, 1, colorant"Pink")

Set color of a light using Colors.jl style colors. (You might need `using Colors`.)
"""
function setlight(bridge::PhilipsHueBridge, light::Int, col::Color)
    if ! in(light, getlightnumbers(bridge))
        return("no light with number $(light). Try using getlightnumbers().")
    end
    c = convert(Colors.HSV, col)
    h, s, v = round(Int, (c.h / 360) * 65535), round(Int, c.s * 255), round(Int, c.v * 255)
    setlight(bridge, light, Dict("on" => true, "sat" => s, "bri" => v, "hue" => h))
end

"""
    setlights(B, Dict("on" => true))
    setlights(B, Dict("on" => false))
    setlights(B, Dict("on" => true, "sat" => 123, "bri" => 243, "hue" => 123)

Set all lights in a group by passing a dictionary of settings.

eg Dict{Any,Any}("on" => true, "sat" => 123, "bri" => 123, "hue" => 123),
"hue" is from 0 to 65535 (?), "sat" and "bri" are saturation and brightness from 1 to 254,
0 is red, yellow is 12750, green is 25500, blue is 46920, etc.

If keys are omitted, that aspect of the light won't be changed.

Keys are AbstractStrings, values can be numeric and will get converted to AbstractStrings
"""
function setlights(bridge::PhilipsHueBridge, settings::Dict)
    state = AbstractString[]
    for (k, v) in settings
        push!(state,("\"$k\": $(string(v))"))
    end
    state = "{" * join(state, ",") * "}"
    response = HTTP.request("PUT", "http://$(bridge.ip)/api/$(bridge.username)/groups/0/action", body="$(state)")
    return JSON.parse(String(response.body))
end

"""
    register(bridge_ip; devicetype="juliascript", blankusername="")

Register the devicetype and username with the bridge.

Quoth Philips: If the username is not provided, a random key will be
generated and returned in the response. Important! The
username will soon be deprecated in the bridge. It is
strongly recommended not to use this and use the randomly
generated bridge username.

So we'll return the randomly generated key, or "" on failure.
"""
function register(bridge_ip; devicetype="juliascript", blankusername="")
    response     = HTTP.request("POST", "http://$(bridge_ip)/api/", body="{\"devicetype\":\"$(devicetype)#$(blankusername)\"}")
    responsedata = JSON.parse(String(response.body))
    # responsedata is probably:
    # 1-element Array{Any,1}:
    # ["error"=>["type"=>101,"description"=>"link button not pressed","address"=>"/"]]
    if responsedata[1][first(keys(responsedata[1]))]["description"] == "link button not pressed"
        println("register(): Quick, you have ten seconds to press the button on the bridge!")
        sleep(10)
        response = HTTP.post("http://$(bridge_ip)/api/", body="{\"devicetype\":\"$(devicetype)#$(blankusername)\"}")
        responsedata = JSON.parse(String(response.body))
        if first(keys(responsedata[1])) == "success"
            println("register(): Successfully registered $devicetype with the bridge at $bridge_ip")
            # returns username which is randomly generated key
            username = responsedata[1]["success"]["username"]
            println("register(): username is $username")
            return username
        else
            warn("register(): Failed to register $devicetype#$blankusername with the bridge at $bridge_ip")
            return ""
        end
    end
end

"""
    testlights(bridge::PhilipsHueBridge, total=5)

Test all lights. Since not all Hue lights do color, not testing color here.
"""
function testlights(bridge::PhilipsHueBridge, total=5)
    setlights(bridge, Dict("on" => true, "hue" => 10000, "sat" => 0, "bri" => 254))
    for i in 1:total
        setlights(bridge, Dict("on" => false))
        sleep(1)
        setlights(bridge, Dict("on" => true))
        sleep(1)
    end
    for light in enumerate(getlights(bridge))
        setlight(bridge, light[1], Dict("on"=>false))
        sleep(1)
        setlight(bridge, light[1], Dict("on"=> true))
        sleep(1)
    end
    setlights(bridge, Dict("hue" => 10000, "sat" => 0, "bri" => 254))
end

"""
  randomcolors(bridge::PhilipsHueBridge, delay = 1, repetitions=10; showstatus=false)

Do a set of repetitions of random color settings for all lights.
"""
function randomcolors(bridge::PhilipsHueBridge, delay = 1, repetitions=10; showstatus=false)
    setlights(bridge, Dict("on" => true, "hue" => 10000, "sat" => 0, "bri" => 254))
    for r in 1:repetitions
        for light in enumerate(getlights(bridge))
            response = getlight(bridge, light[1])
            if length(response) != 2 # don't do this with white only bulbs
                setlight(bridge, light[1], Dict("on" => true, "sat" => rand(128:254), "hue" => rand(0:65200)))
            end
            sleep(delay)
        end
    end
    response = setlights(bridge, Dict("on" => true, "hue" => 10000, "sat" => 0, "bri" => 254))
end

end
