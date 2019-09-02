# Get root logger.
# Nothing appears as we haven't set any config on any loggers.
root_logger = get_logger()
println(root_logger)

# This is also root logger.
println(get_logger(""))

# Set root config.
# It inserts a handler that outputs message to `STDERR`.
basic_config(MiniLogging.INFO, date_format="")

# It changes the root logger level.
get_logger("")
println(root_logger)

@warn(root_logger, "Hello", " world")

# Get a logger.
logger = get_logger("a.b")
println(logger)

# Since the level of `logger` is unset, it inherits its nearest ancestor's level.
# Its effective level is `INFO` (from `root_logger`) now.
@info(logger, "Hello", " world")

# Since `DEBUG < INFO`, no message is generated.
# Note the argument expressions are not evaluated in this case to increase performance.
@debug(logger, "Hello", " world", error("no error"))

# Explicitly set the level.
# The error is triggered.
logger.level = MiniLogging.DEBUG
try
    @debug(logger, "Hello", " world", error("has error"))
catch e
    println(e)
end

# Get a child logger.
logger2 = get_logger("a.b.c")
println(logger2)

# Its effective level now is `DEBUG` (from `logger`) now.
@debug(logger2, "Hello", " world")

# Add A New Level
MiniLogging.define_new_level(:trace, 25, :yellow)
@trace(logger, "Hello", " world")

