"""
    unix_timestamp_ms(dt::Union{DateTime, ZonedDateTime}) -> Int

Get a datetime's representation as a UNIX timestamp in milliseconds.
`DateTime`s with no time zone are assumed to be in UTC.
"""
function unix_timestamp_ms end

unix_timestamp_ms(zdt::ZonedDateTime) = floor(Int, TimeZones.zdt2unix(zdt) * 1000)
# assume UTC because you have to assume something
unix_timestamp_ms(dt::DateTime) = unix_timestamp_ms(ZonedDateTime(dt, tz"UTC"))

"""
    unix_timestamp_ms() -> Int

Get the current datetime's representation as a UNIX timestamp in milliseconds.
"""
unix_timestamp_ms() = unix_timestamp_ms(Dates.now(tz"UTC"))

"""
    LogEvent(message::AbstractString, datetime=Dates.now(tz"UTC"))
    LogEvent(message::AbstractString, timestamp)

Log event for submission to CloudWatch Logs.
"""
struct LogEvent
    message::String
    timestamp::Int

    function LogEvent(message::AbstractString, timestamp::Real)
        message = String(message)

        if isempty(message)
            throw(ArgumentError("Log Event message must be non-empty"))
        end

        if sizeof(message) > MAX_EVENT_SIZE - 26
            # Truncate message and throw a warning
            idx = MAX_EVENT_SIZE - 29
            # Truncated messages include a "..."
            message = string(message[1:idx], "...")
            warn(LOGGER, "CloudWatch Log Event message cannot be more than $MAX_EVENT_SIZE bytes")
        end

        if timestamp < 0
            throw(ArgumentError("Log Event timestamp must be non-negative"))
        end

        new(message, timestamp)
    end
end

function LogEvent(message::AbstractString, dt::Union{DateTime, ZonedDateTime})
    return LogEvent(message, unix_timestamp_ms(dt))
end

LogEvent(message::AbstractString) = LogEvent(message, Dates.now(tz"UTC"))

"""
    aws_size(event::LogEvent) -> Int

Returns the size of a log event as represented by AWS, used to calculate the log batch size.

See the Amazon CloudWatch Logs documentation for [`PutLogEvents`](https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_PutLogEvents.html#CWL-PutLogEvents-request-sequenceToken).
"""
aws_size(event::LogEvent) = sizeof(event.message) + 26

message(event::LogEvent) = event.message
timestamp(event::LogEvent) = event.timestamp
