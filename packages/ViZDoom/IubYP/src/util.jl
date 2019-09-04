const scenario_dir = joinpath(@__DIR__, "..", "deps", "usr", "ViZDoom-1.1.6", "scenarios")


function get_scenario_path(s::AbstractString)
    filedir = joinpath(scenario_dir, s)
    isfile(filedir) || throw("$s is not found in $filedir")
    filedir
end

const add_fields = Set([:available_buttons, :available_game_variable])

function set_game(game; kw...)
    for (k, v) in kw
        if k == :available_game_variable
            add_available_game_variable(game, v)
        elseif k == :available_buttons
            for b in v
                add_available_button(game, b)
            end
        else
            m = Symbol("set_$k")
            isdefined(ViZDoom, m) || throw("Unknown arg $k => $v")
            @eval $m($game, $v)
        end
    end
    game
end