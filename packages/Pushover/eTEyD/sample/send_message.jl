using Pushover

include("config.jl")

client = PushoverClient(CONFIG["USER_KEY"], CONFIG["API_TOKEN"])
message = "My first message"
response = send(client, message, priority=1)
println("response: $response")
