# ViZDoom

[![Build Status](https://travis-ci.com/JuliaReinforcementLearning/ViZDoom.jl.svg?branch=master)](https://travis-ci.com/JuliaReinforcementLearning/ViZDoom.jl)

This package provides a wrapper around the [ViZDoom](https://github.com/mwydmuch/ViZDoom) and also some typical scenarios. Enjoy it!

## How to install

This package has only been tested on Ubuntu and Arch Linux with Julia 0.7/1.0 (and nightly). You need to install the necessary [dependencies](https://github.com/mwydmuch/ViZDoom/blob/master/doc/Building.md#-linux) first (or, you can also check the [packages](https://github.com/JuliaReinforcementLearning/RLEnvViZDoom.jl/blob/master/.travis.yml) in the `.travis.yml` file). Then just add this package as usual:

```
(v0.7) pkg> add ViZDoom
```

## How to use

Most of the functions' name are kept same with Python. So you'll find it pretty easy to port the Python example code into Julia. To easily access the state of a game, The following functions are added:

- `get_screen_buffer(game)`. `Array<UInt8, 1>` is returned with size of width * height * channels. (You need to reshape this array to show it).
- `get_depth_buffer(game)`.`Array<UInt8, 1>` is returned with size of width * height, which provides the depth info.
- `get_label_buffer(game)`.`Array<UInt8, 1>` is returned with size of width * height, which provides the label info.
- `get_automap_buffer(game)`.`Array<UInt8, 1>` is returned with size of width * height * channels, which provides the map info from the top view.


Beyond that, some helper functions are also provided:

- `get_scenario_path("basic.wad")` can be used to get the absolute path of `basic.wad` files.
- `set_game(game; kw...)`. It's really verbose to set the game line by line. This function comes to simplify the process. The name of the argument should be the same with the original method without the `set_` or `add_` prefix. For example, we can use `set(game; doom_map="map01, mode=PLAYER")` to replace the original methods like`ViZDoom.set_doom_map(game, "map01"); ViZDoom.set_mode(game, "PLAYER")`. You can checkout the detailed examples in the `src/games`folder. Following are some special arguments:
    - `available_buttons` The original method name is `add_available_button`. Here you can set `available_buttons=[MOVE_LEFT, MOVE_RIGHT, ATTACK]`.
- `basic_game(;kw...)`. A simple game with default config is returned. (More default configs are coming soon.)
