struct TravisToken end

base_url(t::TravisToken) = "https://api.travis-ci.org"
headers(t::TravisToken) = Dict(
    "Accept" => "application/vnd.travis-ci.2+json",
    "User-Agent" => "Travis/1.6.8")

function get_travis_token(github_token)
    @info "getting travis token"
    json_parse(talk_to(HTTP.post, TravisToken(),
        "/auth/github",
        Dict("github_token" => github_token)
    ))["access_token"]
end
