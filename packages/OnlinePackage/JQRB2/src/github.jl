struct GitHub <: Remote
    repo_name::String
    username::String
    token::String
end

GitHub(repo_name) =
    GitHub(repo_name, settings("username"), settings("github_token"))

base_url(g::GitHub) = "https://api.github.com"
headers(g::GitHub) = Dict(
    "Authorization" => "token $(g.token)",
    "User-Agent" => user_agent
)

function repos(g::GitHub)
    @info "getting github repos"
    talk_to(HTTP.get, g, "/user/repos?per_page=100") |> json_parse
end

function create(g::GitHub)
    @info "creating github"
    talk_to(HTTP.post, g, "/user/repos", json(Dict(
        "name" => g.repo_name)))
end

function get_keys(g::GitHub)
    @info "getting github keys"
    talk_to(HTTP.get, g, "/repos/$(g.username)/$(g.repo_name)/keys") |> json_parse
end

function add_key(g::GitHub, name, value; read_only = false)
    @info "creating github key"
    talk_to(HTTP.post, g, "/repos/$(g.username)/$(g.repo_name)/keys", json(Dict(
        "title" => name,
        "key" => value,
        "read_only" => read_only
    )))
end

function delete_key(g::GitHub, key_id)
    @info "deleting github key"
    talk_to(HTTP.delete, g, "/repos/$(g.username)/$(g.repo_name)/keys/$key_id")
end

function delete_keys(g::GitHub, name)
    foreach(
        github_key ->
            if github_key["title"] == name
                delete_key(g, github_key["id"])
            end,
        get_keys(g)
    )
end

# TODO: check more than the first 100 repositories
function exists(g::GitHub)
    any(repos(g)) do repo
        repo["name"] == g.repo_name
    end
end

function delete(g::GitHub)
    @info "deleting github"
    talk_to(HTTP.delete, g, "/repos/$(g.username)/$(g.repo_name)")
end
