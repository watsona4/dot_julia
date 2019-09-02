const settings_file = joinpath((@__FILE__) |> dirname |> dirname, "online_package.json")

export set_up
"""
    set_up(username, github_token; get_travis_token(github_token), ssh_keygen_file = "ssh-keygen")

set up `OnlinePackage`.

get a `github_token` [here](https://github.com/settings/tokens/new). make
sure to check the `"public_repo"` scope.

the default `ssh_keygen_file` assumes ssh-keygen is in your path. if not,
it often comes prepacked with git; check `PATH_TO_GIT/usr/bin/ssh-keygen"`.
"""
set_up(username, github_token; ssh_keygen_file = "ssh-keygen", travis_token = get_travis_token(github_token)) =
    open(settings_file, "w") do io
        JSON.print(io, Dict(
            "username" => username,
            "github_token" => github_token,
            "travis_token" => travis_token,
            "ssh_keygen_file" => ssh_keygen_file))
    end

function settings(name; settings_file = settings_file)
    if !ispath(settings_file)
        error("Cannot find settings. Please `set_up`")
    end
    dict = JSON.parsefile(settings_file)
    if !haskey(dict, name)
        error("Missing setting $name")
    end
    dict[name]
end
