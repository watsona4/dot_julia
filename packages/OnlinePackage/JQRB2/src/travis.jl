mutable struct Travis <: Remote
    repo_name::String
    username::String
    token::String
    user_code::Int
    repo_code::Int
end

Travis(repo_name) =
    Travis(repo_name, settings("username"), settings("travis_token"), 0, 0)

base_url(t::Travis) = "https://api.travis-ci.org"

headers(t::Travis) = Dict(
    "Travis-API-Version" => "3",
    "Content-Type" => "application/json",
    "Authorization" => "token $(t.token)",
    "User-Agent" => user_agent)

function user(t::Travis)
    @info "getting travis user"
    talk_to(HTTP.get, t, "/user") |> json_parse
end

function sync(t::Travis)
    @info "syncing travis"
    talk_to(HTTP.post, t, "/user/$(t.user_code)/sync")
end

function repos(t::Travis)
    @info "getting travis repos"
    talk_to(HTTP.get, t, "/repos") |> json_parse
end

function repo(t::Travis)
    @info "getting travis repo"
    talk_to(HTTP.get, t, "/repo/$(t.username)%2F$(t.repo_name)") |> json_parse
end

function activate(t::Travis)
    @info "creating travis"
    talk_to(HTTP.post, t, "/repo/$(t.repo_code)/activate")
end

function get_keys(t::Travis)
    @info "getting travis keys"
    talk_to(HTTP.get, t, "/repo/$(t.repo_code)/env_vars") |> json_parse
end

function delete_key(t::Travis, key_id)
    @info "deleting travis key"
    talk_to(HTTP.delete, t, "/repo/$(t.repo_code)/env_var/$key_id")
end

function delete_keys(t::Travis, name)
    foreach(
        travis_key ->
            if travis_key["name"] == name
                delete_key(t, travis_key["id"])
            end,
        get_keys(t)["env_vars"]
    )
end

function add_key(t::Travis, name, value; public = false)
    @info "creating travis key"
    talk_to(HTTP.post, t, "/repo/$(t.repo_code)/env_vars", json(Dict(
        "env_var.name" => name,
        "env_var.value" => value,
        "env_var.public" => public
    )))
end

function exists(t::Travis)
    any(repos(t)["repositories"]) do repo
        repo["slug"] == user_repo(t)
    end
end

function user!(t::Travis)
    t.user_code = user(t)["id"]
end

function repo!(t::Travis)
    t.repo_code = repo(t)["id"]
end
