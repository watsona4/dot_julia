module EnhancedLogging

using Printf, Logging, Distributed
import Logging: handle_message, shouldlog, min_enabled_level, catch_exceptions, LogLevel

export ProgressLevel, EnhancedConsoleLogger, WorkerLogger

const ProgressLevel = LogLevel(-1)

include("EnhancedConsoleLogger.jl")
include("WorkerLogger.jl")

end # module
