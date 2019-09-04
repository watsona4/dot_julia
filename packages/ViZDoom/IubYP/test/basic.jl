game = basic_game()

ViZDoom.init(game)

actions = [[1., 0., 0.], [0., 1., 0.], [0., 0., 1.]]
episodes = 1
sleep_time = 1.0 / ViZDoom.DEFAULT_TICRATE

for i in 1:episodes
    println("Episode #$i")
    ViZDoom.new_episode(game)

    while !ViZDoom.is_episode_finished(game)
        state = ViZDoom.get_screen_buffer(game)
        print(size(state))
        r = ViZDoom.make_action(game, rand(actions))
        println("Reward $r")
        sleep(sleep_time)
    end
end
