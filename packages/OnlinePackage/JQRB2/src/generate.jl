export put_online
"""
    put_online(repo_name)

put a repository online: create a github and travis repository (if they don't
already exist) and connect them with a key.
"""
function put_online(repo_name; github_time = 60, travis_time = 60)
    if !endswith(repo_name, ".jl")
        ArgumentError("repo_name $repo_name must end with .jl")
    end
    github = GitHub(repo_name)
    travis = Travis(repo_name)
    if exists(github)
        @info "github already exists"
    else
        create(github)
        @info "Waiting $github_time seconds for github creation"
        sleep(github_time)
    end

    if exists(travis)
        @info "travis already exists"
    else
        user!(travis)
        sync(travis)
        @info "Waiting $travis_time seconds for travis syncing"
        sleep(travis_time)
        if !exists(travis)
            error("travis doesn't exist, likely due to incomplete syncing")
        end
    end
    repo!(travis)
    activate(travis)

    public_key, private_key = make_keys()

    delete_keys(github, ".documenter")
    add_key(github, ".documenter", public_key)
    delete_keys(travis, "DOCUMENTER_KEY")
    add_key(travis, "DOCUMENTER_KEY", private_key)

    github, travis
end
