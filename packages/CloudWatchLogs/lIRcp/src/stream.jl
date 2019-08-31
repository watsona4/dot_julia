const RETRYABLE_CODES = (
    "IncompleteSignature",
    "ThrottlingException",
    "RequestExpired",
)

function aws_retry_cond(s, e)
    if e isa AWSException && (500 <= e.cause.status <= 504 || e.code in RETRYABLE_CODES)
        debug(LOGGER, "CloudWatchLogs operation encountered $(e.code); retrying")
        return (s, true)
    elseif e isa MbedException
        debug(LOGGER, "CloudWatchLogs operation encountered $e; retrying")
        return (s, true)
    end

    return (s, false)
end

aws_retry(f) = retry(f, delays=GENERIC_AWS_DELAYS, check=aws_retry_cond)()

struct CloudWatchLogStream
    config::AWSConfig
    log_group_name::String
    log_stream_name::String
    token::Ref{Union{String, Nothing}}
end

"""
    CloudWatchLogStream(config::AWSConfig, log_group_name, log_stream_name)

Create a reference to a CloudWatch Log Stream on AWS with the log group name and log
stream name.
This constructor will automatically fetch the latest [sequence token](https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_PutLogEvents.html#CWL-PutLogEvents-request-sequenceToken)
for the stream.
"""
function CloudWatchLogStream(
    config::AWSConfig,
    log_group_name::AbstractString,
    log_stream_name::AbstractString,
)
    stream = CloudWatchLogStream(
        config,
        log_group_name,
        log_stream_name,
        Ref{Union{String, Nothing}}(),
    )
    update_sequence_token!(stream)
    return stream
end

"""
    create_group(config::AWSConfig) -> String
    create_group(config::AWSConfig, log_group_name) -> String

Create a CloudWatch Log Group.
If the log group name is not provided, one is generated using a UUID4.

Returns the log group name.
"""
function create_group(
    config::AWSConfig,
    # this probably won't collide, most callers should add identifying information though
    log_group_name::AbstractString="julia-$(uuid4())";
    tags::AbstractDict{<:AbstractString, <:AbstractString}=Dict{String, String}(),
)
    if isempty(tags)
        aws_retry() do
            logs(config, "CreateLogGroup"; logGroupName=log_group_name)
        end
    else
        tags = Dict{String, String}(tags)
        aws_retry() do
            logs(config, "CreateLogGroup"; logGroupName=log_group_name, tags=tags)
        end
    end
    return String(log_group_name)
end

"""
    delete_stream(config::AWSConfig, log_group_name)

Delete a CloudWatch Log Group.
"""
function delete_group(
    config::AWSConfig,
    log_group_name::AbstractString,
)
    aws_retry() do
        logs(config, "DeleteLogGroup"; logGroupName=log_group_name)
    end
    return nothing
end

"""
    create_stream(config::AWSConfig, log_group_name) -> String
    create_stream(config::AWSConfig, log_group_name, log_stream_name) -> String

Create a CloudWatch Log Stream under a given Log Group.
If the log stream name is not provided, one is generated using a UUID4.

Returns the log stream name.
"""
function create_stream(
    config::AWSConfig,
    log_group_name::AbstractString,
    # this probably won't collide, most callers should add identifying information though
    log_stream_name::AbstractString="julia-$(uuid4())",
)
    aws_retry() do
        logs(
            config,
            "CreateLogStream";
            logGroupName=log_group_name,
            logStreamName=log_stream_name,
        )
    end
    return String(log_stream_name)
end

"""
    delete_stream(config::AWSConfig, log_group_name, log_stream_name)

Delete a CloudWatch Log Stream from a given Log Group.
"""
function delete_stream(
    config::AWSConfig,
    log_group_name::AbstractString,
    log_stream_name::AbstractString,
)
    aws_retry() do
        logs(
            config,
            "DeleteLogStream";
            logGroupName=log_group_name,
            logStreamName=log_stream_name,
        )
    end
    return nothing
end

"""
    sequence_token(config::AWSConfig, log_group_name, log_stream_name) -> Union{String, Nothing}

Return the current sequence token for the stream.
"""
sequence_token(stream::CloudWatchLogStream) = stream.token[]

function new_sequence_token(stream::CloudWatchLogStream)
    return new_sequence_token(stream.config, stream.log_group_name, stream.log_stream_name)
end

describe_log_streams(config; kwargs...) = logs(config, "DescribeLogStreams"; kwargs...)

"""
    new_sequence_token(stream::CloudWatchLogStream) -> Union{String, Nothing}
    new_sequence_token(config::AWSConfig, log_group_name, log_stream_name) -> Union{String, Nothing}

Fetch the current sequence token for the stream from AWS.

Returns `nothing` if the stream does not have a sequence token yet (e.g., if no events have
been logged).
"""
function new_sequence_token(
    config::AWSConfig,
    log_group::AbstractString,
    log_stream::AbstractString,
)::Union{String, Nothing}
    response = aws_retry() do
        @mock describe_log_streams(
            config;
            logGroupName=log_group,
            logStreamNamePrefix=log_stream,
            orderBy="LogStreamName",  # orderBy and limit will ensure we get just the one
            limit=1,                  # matching result
        )
    end

    streams = response["logStreams"]

    if isempty(streams) || streams[1]["logStreamName"] != log_stream
        msg = isempty(streams) ? nothing : "Did you mean $(streams[1]["logStreamName"])?"
        error(LOGGER, StreamNotFoundException(log_stream, log_group, msg))
    end

    return get(streams[1], "uploadSequenceToken") do
        debug(LOGGER) do
            string(
                "Log group '$log_group' stream '$log_stream' has no sequence token yet. ",
                "Using null as a default. ",
            )
        end

        return nothing
    end
end

"""
    update_sequence_token!(stream::CloudWatchLogStream) -> Union{String, Nothing}
    update_sequence_token!(stream::CloudWatchLogStream, token) -> Union{String, Nothing}

Fetch the current sequence token for the stream from AWS and store it.
Alternatively, set the token for the stream to `token`.

Returns the token.
"""
function update_sequence_token!(
    stream::CloudWatchLogStream,
    token::Union{String, Nothing}=new_sequence_token(stream),
)
    stream.token[] = token
end

function _put_log_events(stream::CloudWatchLogStream, events::AbstractVector{LogEvent})
    logs(
        stream.config,
        "PutLogEvents";
        logEvents=events,
        logGroupName=stream.log_group_name,
        logStreamName=stream.log_stream_name,
        sequenceToken=sequence_token(stream),
    )
end

"""
    submit_logs(stream::CloudWatchLogStream, events::AbstractVector{LogEvent}) -> Int

Submit a list of log events to AWS.

None of the log events can be more than 2 hours in the future, or older than 14 days or the
retention period of the log group.
If this occurs, those log messages will be rejected but the rest will succeed.

Submission of _all_ log events will fail if:

* the log events are more than 1 MiB of data
* the log events are not in chronological order by timestamp
* there are more than 10000 log events in `events`
* the log events span more than 24 hours

Returns the number of events successfully submitted.
"""
function submit_logs(stream::CloudWatchLogStream, events::AbstractVector{LogEvent})
    if length(events) > MAX_BATCH_LENGTH
        error(LOGGER, LogSubmissionException(
            "Log batch length exceeded 10000 events; submit fewer log events at once"
        ))
    end

    batch_size = sum(aws_size, events)

    if batch_size > MAX_BATCH_SIZE
        error(LOGGER, LogSubmissionException(
            "Log batch size exceeded 1 MiB; submit fewer log events at once"
        ))
    end

    if !issorted(events; by=timestamp)
        debug(LOGGER,
            "Log submission will be faster if log events are sorted by timestamp"
        )

        # a stable sort to avoid putting related messages out of order
        sort!(events; alg=MergeSort, by=timestamp)
    end

    min_timestamp, max_timestamp = extrema(timestamp(e) for e in events)
    if max_timestamp - min_timestamp > 24 * 3600 * 1000  # 24 hours in milliseconds
        error(LOGGER, LogSubmissionException(
            "Log events cannot span more than 24 hours; submit log events separately"
        ))
    end

    function retry_cond(s, e)
        if e isa AWSException
            if 500 <= e.cause.status <= 504 || e.code == "ThrottlingException"
                debug(LOGGER, "CloudWatchLogs PutLogEvents encountered $(e.code); retrying")
                return (s, true)
            elseif e.cause.status == 400 && e.code == "InvalidSequenceTokenException"
                debug(LOGGER) do
                    string(
                        "CloudWatchLogStream encountered InvalidSequenceTokenException. ",
                        "Are you logging to the same stream from multiple tasks?",
                    )
                end

                update_sequence_token!(stream)

                return (s, true)
            end
        elseif e isa MbedException
            debug(LOGGER, "CloudWatchLogs PutLogEvents encountered $e; retrying")
            return (s, true)
        end

        return (s, false)
    end

    f = retry(delays=PUTLOGEVENTS_DELAYS, check=retry_cond) do
        @mock _put_log_events(stream, events)
    end

    min_valid_event = 1
    max_valid_event = length(events)

    json_response = f()

    if haskey(json_response, "nextSequenceToken")
        update_sequence_token!(stream, json_response["nextSequenceToken"])
    end

    if haskey(json_response, "rejectedLogEventsInfo")
        rejected_info = json_response["rejectedLogEventsInfo"]

        if haskey(rejected_info, "expiredLogEventEndIndex")
            idx = Int(rejected_info["expiredLogEventEndIndex"]) + 1
            min_valid_event = max(min_valid_event, idx)

            warn(LOGGER) do
                string(
                    "Cannot log the following events, ",
                    "as they are older than the log retention policy allows: ",
                    events[1:idx-1],
                )
            end
        end

        if haskey(rejected_info, "tooOldLogEventEndIndex")
            idx = Int(rejected_info["tooOldLogEventEndIndex"]) + 1
            min_valid_event = max(min_valid_event, idx)

            warn(LOGGER) do
                string(
                    "Cannot log the following events, ",
                    "as they are more than 14 days old: ",
                    events[1:idx-1],
                )
            end
        end

        if haskey(rejected_info, "tooNewLogEventStartIndex")
            idx = Int(rejected_info["tooNewLogEventStartIndex"])
            max_valid_event = min(max_valid_event, idx)

            warn(LOGGER) do
                string(
                    "Cannot log the following events, ",
                    "as they are newer than 2 hours in the future: ",
                    events[idx+1:end],
                )
            end
        end
    end

    return length(min_valid_event:max_valid_event)
end

"""
    submit_log(stream::CloudWatchLogStream, event::LogEvent) -> Int

Call [`submit_logs`](@ref) with one event.
"""
submit_log(stream::CloudWatchLogStream, event::LogEvent) = submit_logs(stream, [event])
