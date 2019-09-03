"""
A Julia package to send notifications using the [Pushover Notification Service](https://pushover.net/) 
as documented [here](https://pushover.net/api).
"""
module Pushover

    import Sockets: send
    export PushoverClient, send

    using HTTP
    using JSON


    _DEFAULT_TITLE = "default_title"
    _DEFAULT_PRIORITY = 0
    _DEFAULT_MAX_TITLE_LEN = 100
    _DEFAULT_MAX_MESSAGE_LEN = 512

    """
        PushoverException(response)

    Pushover exception
    """
    struct PushoverException <: Exception
        response::Dict
    end

    """
        PushoverClient(user_key, api_token; max_title_len=_DEFAULT_MAX_TITLE_LEN, max_message_len=_DEFAULT_MAX_MESSAGE_LEN)

    Create a client that can connect to Pushover Notification Service.

    - `user_key` and `api_token` are required.
    - `max_title_len` is optional and is set by default to `_DEFAULT_MAX_TITLE_LEN = 100`.
    - `max_message_len` is optional and is set by default to `_DEFAULT_MAX_MESSAGE_LEN = 512`
    """
    struct PushoverClient
        user_key::AbstractString
        api_token::AbstractString

        max_title_len::Int
        max_message_len::Int

        function PushoverClient(user_key, api_token;
                max_title_len=_DEFAULT_MAX_TITLE_LEN,
                max_message_len=_DEFAULT_MAX_MESSAGE_LEN)
            new(user_key, api_token, max_title_len, max_message_len)
        end
    end

    """
        _sanitize_priority(priority) -> sanitized_priority

    Sanitize `priority` (must be an integer in [-2;1] range).
    If `priority` is not in the correct range, `0` is returned.
    """
    function _sanitize_priority(priority)
        if !in(priority, [-2, -1, 0, 1])
            priority = 0
        end
        priority
    end

    """
        _crop(msg, max_len) -> cropped_msg

    Crop a `message` to `max_len`.
    """
    function _crop(msg, max_len)
        if max_len > 0 && length(msg) > max_len
            msg[1:max_len-3] * "..."
        else
            msg
        end
    end

    """
        send(client::PushoverClient, message; device=nothing, title=nothing, url=nothing, url_title=nothing, priority=nothing, timestamp=nothing, sound=nothing)

    Send a `message` to Pushover notification service using `client`.
    The following parameters are optional.
    - `device`
    - `title`
    - `url`
    - `url_title`
    - `priority`
    - `timestamp`
    - `sound`
    """
    function send(client::PushoverClient, message::AbstractString;
                device=nothing, title=nothing, url=nothing, url_title=nothing,
                priority=nothing, timestamp=nothing, sound=nothing)

        base_url = "https://api.pushover.net"
        endpoint = "/1/messages.json"
        url_query = base_url * endpoint

        message = _crop(message, client.max_message_len)

        # Required parameters
        params = Dict(
            "user" => client.user_key,
            "token" => client.api_token,
            "message" => message,
        )

        # Optional parameters
        if !(device === nothing)
            params["device"] = device
        end

        if !(title === nothing)
            params["title"] = _crop(title, client.max_title_len)
        end

        if !(url === nothing)
            params["url"] = url
        end

        if !(url_title === nothing)
            params["url_title"] = url_title
        end

        if !(priority === nothing)
            params["priority"] = string(_sanitize_priority(priority))
        end

        if !(timestamp === nothing)
            params["timestamp"] = timestamp
        end

        if !(sound === nothing)
            params["sound"] = sound
        end

        raw_response = HTTP.request("POST", url_query,
            ["Content-Type" => "application/json"],
            JSON.json(params))
        response = JSON.parse(String(raw_response.body))

        if response["status"] != 1
            exception = PushoverException(response)
            throw(exception)
        end

        response
    end

end # module
