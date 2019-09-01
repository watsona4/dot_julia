using Distributed, Logging, EnhancedLogging
addprocs(1)

global_logger(EnhancedConsoleLogger())
@everywhere begin
    using Logging, EnhancedLogging
    global_logger(WorkerLogger(global_logger()))
end

@everywhere function test_logging()
    @debug "hello world"
    @logmsg ProgressLevel "status report" progress=0.32 _overwrite=true
    @logmsg ProgressLevel "status report" _overwrite=true
    @logmsg ProgressLevel "this is a really really long status report that goes on forever" progress=0.32 _overwrite=true _showlocation=true
    @info "everything seems to be fine..."
    @info "everything seems to be fine...\nand its fine on this line...\nand this line...\nand also this line" asdf=2
    @warn "ummm this doesn't look good"
    @warn "ummm this doesn't look good" asdf="areallyreallyreallyreallyreallyreallylongstring"
    @error "bad stuff"

    for i in 0:0.001:1
        @logmsg ProgressLevel "hello" progress=i _overwrite=true
        sleep(0.001)
    end
end

with_logger(test_logging, EnhancedConsoleLogger())


remotecall_fetch(test_logging, 2)
