using BulkSMS: BulkSMSClient, send
using BulkSMS: multiple, shorten

include("config.jl")

client = BulkSMSClient(CONFIG["MSISDN"], CONFIG["USERNAME"], CONFIG["PASSWORD"])
message = "My first message"
# response = send(client, message, msisdn="+336........")

@info "Send '$message'"
response = send(client, message)  # use client MSISDN by default

# Action when long message can be set using:
# response = send(client, message, action_when_long=shorten)  # shorten long message
# response = send(client, message, action_when_long=multiple)  # multiple messages

@info "response: $response"
