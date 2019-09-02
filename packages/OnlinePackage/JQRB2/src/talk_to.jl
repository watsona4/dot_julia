json_parse(r::HTTP.Response) = r.body |> String |> JSON.parse

function http_error(response)
    status_number = response.status
    status_text = response.statustext
    result_string = response.body |> String
    error("$status_number $status_text: $result_string")
end

ask(f, remote, url, body = "") =
    f(string(base_url(remote), url), headers = headers(remote), body = body)

function talk_to(f, remote, url, body = "")
    response = ask(f, remote, url, body)
    status_number = response.status
    if status_number >= 300
        http_error(response)
    end
    response
end

user_repo(r::Remote) = "$(r.username)/$(r.repo_name)"
