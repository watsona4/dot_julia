__precompile__()
module CloudWatchLogs

using AWSCore: AWSConfig, AWSException
using AWSCore.Services: logs
using Dates
using MbedTLS: MbedException
using Memento
using Mocking
using TimeZones
using UUIDs

export CloudWatchLogStream, LogEvent, submit_log, submit_logs
export create_group, delete_group, create_stream, delete_stream
export CloudWatchLogHandler
export StreamNotFoundException, LogSubmissionException

const LOGGER = getlogger(@__MODULE__)

# Info on limits:
# https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/cloudwatch_limits_cwl.html

# 1 MB (maximum). This limit cannot be changed.
const MAX_BATCH_SIZE = 1048576

# 256 KB (maximum). This limit cannot be changed.
const MAX_EVENT_SIZE = 262144

# https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_PutLogEvents.html#CWL-PutLogEvents-request-logEvents
const MAX_BATCH_LENGTH = 10000

# 5 requests per second per log stream. This limit cannot be changed.
const PUTLOGEVENTS_RATE_LIMIT = 0.2
const PUTLOGEVENTS_DELAYS =
    ExponentialBackOff(n=10, first_delay=PUTLOGEVENTS_RATE_LIMIT, factor=1.1)

const GENERIC_AWS_DELAYS = ExponentialBackOff(n=10, first_delay=0.2, factor=2, jitter=0.2)

__init__() = Memento.register(LOGGER)

include("exceptions.jl")
include("event.jl")
include("stream.jl")
include("handler.jl")

end
