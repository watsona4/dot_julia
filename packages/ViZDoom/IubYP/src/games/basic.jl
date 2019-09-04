const basic_config = (
    doom_scenario_path = get_scenario_path("deadly_corridor.wad"),
    doom_map = "map01",
    screen_resolution = RES_640X480,
    screen_format = RGB24,
    depth_buffer_enabled = true,
    labels_buffer_enabled = true,
    automap_buffer_enabled = true,
    render_hud = false,
    render_minimal_hud = false,
    render_crosshair = false,
    render_weapon = true,
    render_decals = false,
    render_particles = false,
    render_effects_sprites = false,
    render_messages = false,
    render_corpses = false,
    render_screen_flashes = true,
    episode_timeout = 200,
    episode_start_time = 10,
    window_visible = true,
    sound_enabled = true,
    living_reward = -1,
    mode = PLAYER,
    
    available_game_variable = AMMO2,
    available_buttons = [MOVE_LEFT, MOVE_RIGHT, ATTACK]
)



function basic_game(;kw...)
    config = merge(basic_config, kw)
    @debug config
    game = DoomGame()
    set_game(game; config...)
end