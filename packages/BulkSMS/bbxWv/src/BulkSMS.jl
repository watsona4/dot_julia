"""
A Julia package to send SMS (Short Message Service) using 
[BulkSMS API](http://www.bulksms.com/products/sms-api.htm) 
(more exactly [HTTP to SMS API](http://www.bulksms.com/products/api/http-to-sms.htm))
"""
module BulkSMS

    export BulkSMSClient, send, shorten, multiple

    using HTTP

    """
        ActionWhenLong

    Enumeration that defines how long message treated

    - `shorten`: if message is too long, it will be shorten.
    - `multiple`: if message is too long, several messages will be sent
    """
    @enum ActionWhenLong begin
        shorten = 1
        multiple = 2
    end

    _DEFAULT_BASE_URL = "http://bulksms.vsms.net:5567"
    _DEFAULT_MAX_MESSAGE_LEN = 160

    """
        BulkSMSClientException(s)

    BulkSMS client exception.
    """
    struct BulkSMSClientException <: Exception
        s::AbstractString
    end

    """
        BulkSMSResponse(response)

    BulkSMS response (from `response::Requests.Response`).
    """
    struct BulkSMSResponse
        status_code::Int
        status_string::AbstractString
        id::Int
        function BulkSMSResponse(response::HTTP.Messages.Response)
            s = String(response.body)
            statusCode, statusString, Id = split(s, "|")
            new(parse(Int64, statusCode), statusString, parse(Int64, Id))
        end
    end

    """
        BulkSMSClient(msisdn, username, password;
                base_url=_DEFAULT_BASE_URL,
                max_message_len=_DEFAULT_MAX_MESSAGE_LEN)
    
    Create a client that can connect to BulkSMS HTTP to SMS API.
    """
    struct BulkSMSClient
        msisdn::AbstractString
        username::AbstractString
        password::AbstractString

        base_url::AbstractString
        max_message_len::Int

        function BulkSMSClient(msisdn, username, password;
                base_url=_DEFAULT_BASE_URL,
                max_message_len=_DEFAULT_MAX_MESSAGE_LEN)
            new(msisdn, username, password, base_url, max_message_len)
        end
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
        _send(client, message_text, msisdn)

    Send a text message `message_text` using `client`.

    This is a "low level" function. You should probably use `send(...)` insted of `_send(...)`
    """
    function _send(client::BulkSMSClient, message_text::AbstractString, msisdn::AbstractString)
        endpoint = "/eapi/submission/send_sms/2/2.0"

        url = client.base_url * endpoint

        params = Dict(
            "username" => client.username,
            "password" => client.password,
            "message" => message_text,
            "msisdn" => msisdn
        )
        
        @debug "GET $url with query=$params"
        raw_response = HTTP.request("GET", url; query = params)
        @debug raw_response

        if raw_response.status != 200
            throw(BulkSMSClientException("HTTP status code != 200"))
        end

        response = BulkSMSResponse(raw_response)

        if response.status_code != 0
            throw(BulkSMSClientException("BulkSMS status code != 0"))
        end

        response
    end

    """
        send(client, message_text; msisdn=nothing, action_when_long::ActionWhenLong=shorten)

    Send a text message `message_text` to BulkSMS using HTTP to SMS API with BulkSMSClient `client`.
    """
    function send(client::BulkSMSClient, message_text::AbstractString; msisdn=nothing, action_when_long::ActionWhenLong=shorten)

        if msisdn === nothing
            msisdn = client.msisdn
        end

        response = nothing

        if action_when_long == shorten
            shorten_message_text = _crop(message_text, client.max_message_len)
            response = _send(client, shorten_message_text, msisdn)

        # elseif action_when_long == multiple

        else
            throw(BulkSMSClientException("action_when_long=$action_when_long is not a support action"))
        end

        response
    end

end # module
