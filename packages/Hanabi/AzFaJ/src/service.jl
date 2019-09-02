using HTTP
using UUIDs
using JSON
using ReinforcementLearningEnvironments
using Hanabi

const ROOMS = Dict()
const TASKS = Dict()

struct Player
    name::String
    ws_client::HTTP.WebSockets.WebSocket
end

struct PlayerExitError <: Exception
    name::String
end

struct Room
    roomid::String
    env::HanabiEnv
    players::Vector{Player}
    action::Channel{Base.RefValue{Hanabi.LibHanabi.PyHanabiMove}}
    Room(roomid, params) = new(
        roomid,
        HanabiEnv(;players=get(params, "players", 2)),
        Player[],
        Channel{Base.RefValue{Hanabi.LibHanabi.PyHanabiMove}}(1))
end

function serve(host="127.0.0.1", port=8081)
    @async HTTP.listen(host, UInt16(port)) do http
        uri = HTTP.URIs.URI(http.message.target)
        if uri.path == "/hello"
            write(http, "Hello!")
        elseif uri.path == "/rooms"
            params = HTTP.queryparams(uri)
            if haskey(params, "roomid")
                HTTP.WebSockets.upgrade(http) do ws
                    join_room(ws, params)
                end
            else
                write(http, JSON.json(Dict("roomid" => uuid4())))
            end
        else
            HTTP.setstatus(http, 404)
            write(http, "Unknown Path!")
        end
    end
end

function join_room(ws, params)
    roomid = params["roomid"]
    room = get!(ROOMS, roomid, Room(roomid, params))
    player = Player(get(params, "username", string(hash(ws))), ws)
    if add_player(room, player)
        while !eof(ws)
            info = String(readavailable(ws))
            action = parse_move(info)
            if !isnothing(action)
                if player.name == room.players[state_cur_player(room.env.state)+1].name
                    if state_end_of_game_status(room.env.state) == 0  # not finished yet
                        if move_is_legal(room.env.state, action)
                            put!(room.action, action)
                        else
                            tell(player, "Illegal action!")
                        end
                    else
                        tell(player, "Game already ends!")
                    end
                else
                    tell(player, "You are sending an action. But it's not your turn yet!")
                end
            elseif info != ""
                tell(room, info, player.name)
            end
        end
        haskey(TASKS, roomid) && Base.throwto(TASKS[roomid], PlayerExitError(player.name))
    else
        close(ws)
    end
end

function add_player(room, player)
    if length(room.players) < num_players(room.env.game)
        push!(room.players, player)
        tell(room, "A new player [$(player.name)] joined the game!")
        if length(room.players) == num_players(room.env.game)
            TASKS[room.roomid] = @async begin
                tell(room, "GAME STARTS!")
                try
                    start_room(room)
                catch e
                    if e isa PlayerExitError
                        tell(room, "$(e.name) exits the game. GAME ENDS!")
                    else
                        tell(room, "Unknown Exception caught! Exiting Game!")
                        @error e
                    end
                finally
                    delete!(ROOMS, room.roomid)
                    delete!(TASKS, room.roomid)
                    for player in room.players
                        close(player.ws_client)
                    end
                end
            end
        end
        true
    else
        tell(player, "The room you want to join is full!")
        false
    end
end

function tell(room::Room, info, sender="system")
    for p in room.players
        tell(p, info, sender)
    end
end

function tell(player::Player, info, sender="system")
    isopen(player.ws_client) && write(player.ws_client, JSON.json(Dict("msg"=>info, "sender"=>sender)))
end

function start_room(room)
    obs, reward, isdone, raw_obs = observe(room.env)
    while !isdone
        broadcast_state(room)
        current_player = room.players[state_cur_player(room.env.state)+1]
        tell(room, "Waiting for Player [$(current_player.name)]'s action!")
        action = take!(room.action)
        tell(room, "Player $(current_player.name) takes an action [$action]")
        interact!(room.env, action)
        obs, reward, isdone, raw_obs = observe(room.env)
    end
    broadcast_state(room)
    tell(room, "GAME ENDS! Final Score is [$(state_score(room.env.state))]!")
end

function broadcast_state(room)
    for (i, player) in enumerate(room.players)
        tell(player, string(observe(room.env, i-1).raw_obs), "game")
    end
end

function encode_info(info)
    sender, msg = info["sender"], info["msg"]
    if sender == "system"
        Base.text_colors[:red] * "\r[$sender]:$msg" * Base.text_colors[:default]
    elseif sender == "game"
        msg = replace(msg, "R" => Base.text_colors[:red] * "R" * Base.text_colors[:default])
        msg = replace(msg, "G" => Base.text_colors[:green] * "G" * Base.text_colors[:default])
        msg = replace(msg, "B" => Base.text_colors[:blue] * "B" * Base.text_colors[:default])
        msg = replace(msg, "Y" => Base.text_colors[:yellow] * "Y" * Base.text_colors[:default])
        msg = replace(msg, "W" => Base.text_colors[:white] * "W" * Base.text_colors[:default])
        "\r$msg"
    else
        color = Base.text_colors[Int(hash(sender) % 256 + 1)]
        color * "\r[$sender]:$msg" * Base.text_colors[:default]
    end
end

function play(host="127.0.0.1", port=8081, roomid=gethostname(), username=ENV["USER"])
    HTTP.WebSockets.open("ws://$host:$port/rooms?roomid=$roomid&username=$username") do ws
        t = @async while !eof(ws)
            info = JSON.parse(String(readavailable(ws)))
            println(encode_info(info))
            print("msg >")
        end
        try
            while true
                sleep(0.1)
                if istaskdone(t)
                    printstyled("\rConnection closed by remote server!\nExiting...\n"; color=1, bold=true)
                    break
                end
                input = chomp(readline())
                write(ws, input)
            end
        catch e
            if e isa InterruptException
                printstyled("\rExiting...";color=1)
            else
                throw(e)
            end
        end
    end
end
