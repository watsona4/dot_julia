module IOLoggingTests

using IOLogging
using Logging
using Logging: Debug, Info, Warn, Error, BelowMinLevel, with_logger, min_enabled_level
using Test

function singleLineLogging()
    @debug "DEBUG"
    @info "INFO"
    @warn "WARN"
    @error "ERROR"
end

function multiLineLogging()
    @debug "debug_line_1\ndebug_line_2"
    @info "info_line_1\ninfo_line_2"
    @warn "warn_line_1\nwarn_line_2"
    @error "error_line_1\nerror_line_2"
end

function keywordLogging()
    deb = "debug"
    inf = "info"
    war = "warn"
    err = "error"

    @debug "DEBUG" deb
    @info "INFO" inf
    @warn "WARN" war
    @error "ERROR" err
end

function setupTestlog()
    if isfile("appFlush.log")
        rm("appFlush.log")
    end
    open("appFlush.log", "w") do file
        println(file, "testlog")
    end
end

@testset "IOLogging All Tests" begin
@testset "IOLogger" begin
    @testset "Assertions" begin
        @test_nowarn IOLogger()
        logger = IOLogger(Dict(BelowMinLevel => stdout))
        @test min_enabled_level(logger) === BelowMinLevel
    end
    @testset "Logging" begin
        buf = IOBuffer()
        log = IOLogger(Dict(Info => buf))
        @testset "Singleline No Debug" begin
            with_logger(singleLineLogging, log)
            res = String(take!(buf))
            @test !occursin(r"(DEBUG)|(Debug)", res)
            @test occursin(r"\[Info::[\d\-:T\.]*\][ a-zA-Z@\[\]\d\.\\\/:]* - INFO\n", res)
            @test occursin(r"\[Warn::[\d\-:T\.]*\][ a-zA-Z@\[\]\d\.\\\/:]* - WARN\n", res)
            @test occursin(r"\[Error::[\d\-:T\.]*\][ a-zA-Z@\[\]\d\.\\\/:]* - ERROR\n", res)
        end
        @testset "Multiline No Debug" begin
            with_logger(multiLineLogging, log)
            res = String(take!(buf))
            @test (!occursin(r"(DEBUG)|(Debug)", res) &&
                    !occursin(r"debug_line_1\n", res) &&
                    !occursin(r"debug_line_2\n", res))
            @test (occursin(r"\[Info::[\d\-:T\.]*\][ a-zA-Z@\[\]\d\.\\\/:]*\n", res) &&
                    occursin(r"info_line_1\n", res) &&
                    occursin(r"info_line_2\n", res))
            @test (occursin(r"\[Warn::[\d\-:T\.]*\][ a-zA-Z@\[\]\d\.\\\/:]*\n", res) &&
                    occursin(r"warn_line_1\n", res) &&
                    occursin(r"warn_line_2\n", res))
            @test (occursin(r"\[Error::[\d\-:T\.]*\][ a-zA-Z@\[\]\d\.\\\/:]*\n", res) &&
                    occursin(r"error_line_1\n", res) &&
                    occursin(r"error_line_2\n", res))
        end
        @testset "Keyword Logging No Debug" begin
            with_logger(keywordLogging, log)
            res = String(take!(buf))

            @test !occursin(r"deb = debug", res)
            @test occursin(r"inf = info", res)
            @test occursin(r"war = warn", res)
            @test occursin(r"err = err", res)
        end
        @testset "Logging between Levels No Debug" begin
            infLog = IOBuffer()
            errLog = IOBuffer()
            logger = IOLogger(Dict(Info => infLog, Error => errLog))
            with_logger(singleLineLogging, logger)

            infres = String(take!(infLog)) # should only contain messages from INFO and WARN
            @test  (!occursin(r"DEBUG", infres) &&
                     occursin(r"INFO", infres) &&
                     occursin(r"WARN", infres) &&
                    !occursin(r"ERROR", infres))

            errres = String(take!(errLog)) # should only contain messages from ERROR
            @test  (!occursin(r"DEBUG", errres) &&
                    !occursin(r"INFO", errres) &&
                    !occursin(r"WARN", errres) &&
                     occursin(r"ERROR", errres))
        end
        @testset "Message Limits" begin
            with_logger(log) do
                for _ in 1:20
                    @info "message_Limit_test" maxlog=10
                end
            end
            res = String(take!(buf))
            @test count(c -> c == '\n', res) == 10

            # This is a different log position with the same message
            with_logger(log) do
                for _ in 1:20
                    @info "message_Limit_test" maxlog=10
                end
            end
            res = String(take!(buf))
            @test count(c -> c == '\n', res) == 10
        end
    end
end

@testset "FileLogger" begin
    mktempdir(@__DIR__) do dir
        defaultLog = "default.log"
        cd(dir) do
            @testset "Assertions" begin
                @test_nowarn FileLogger()
                file = "assertions.log"
                logger = FileLogger(Dict(BelowMinLevel => file))
                @test !isfile(file) # make sure the files don't exist until needed
                # FIXME: @test if the file exists after logging
                @test min_enabled_level(logger) === BelowMinLevel
            end
            @testset "Appending && Flushing" begin
                @testset "Regular Use" begin
                    log = FileLogger(Dict(Info => "appFlush.log"))
                    setupTestlog()
                    with_logger(log) do
                        @info "infolog"
                    end

                    lines = readlines("appFlush.log", keep = true)
                    @test lines[1] == "testlog\n"
                    @test occursin(r"\[Info::[\d\-:T\.]*\][ a-zA-Z@\[\]\d\.\\\/:]* - infolog\n", lines[2])
                end

                @testset "No Flush" begin
                    log = FileLogger(Dict(Info => "appFlush.log"), flush = false)
                    setupTestlog()
                    with_logger(log) do
                        @info "infolog"
                    end

                    lines = readlines("appFlush.log", keep = true)
                    @test length(lines) == 1
                    @test lines[1] == "testlog\n"
                end

                @testset "No Append" begin
                    log = FileLogger(Dict(Info => "appFlush.log"), append = false)
                    setupTestlog()
                    with_logger(log) do
                        @info "infolog"
                    end

                    lines = readlines("appFlush.log", keep = true)
                    @test length(lines) == 1
                    @test occursin(r"\[Info::[\d\-:T\.]*\][ a-zA-Z@\[\]\d\.\\\/:]* - infolog\n", lines[1])
                end
            end
            @testset "Logging" begin
                log = FileLogger()
                @testset "Singleline No Debug" begin
                    with_logger(singleLineLogging, log)
                    res = string(readlines(defaultLog, keep = true)...)

                    @test !occursin(r"(DEBUG)|(Debug)", res)
                    @test occursin(r"\[Info::[\d\-:T\.]*\][ a-zA-Z@\[\]\d\.\\\/:]* - INFO\n", res)
                    @test occursin(r"\[Warn::[\d\-:T\.]*\][ a-zA-Z@\[\]\d\.\\\/:]* - WARN\n", res)
                    @test occursin(r"\[Error::[\d\-:T\.]*\][ a-zA-Z@\[\]\d\.\\\/:]* - ERROR\n", res)
                end
                @testset "Multiline No Debug" begin
                    with_logger(multiLineLogging, log)
                    res = string(readlines(defaultLog, keep = true)...)

                    @test (!occursin(r"(DEBUG)|(Debug)", res) &&
                           !occursin(r"debug_line_1\n", res) &&
                           !occursin(r"debug_line_2\n", res))
                    @test (occursin(r"\[Info::[\d\-:T\.]*\][ a-zA-Z@\[\]\d\.\\\/:]*\n", res) &&
                           occursin(r"info_line_1\n", res) &&
                           occursin(r"info_line_2\n", res))
                    @test (occursin(r"\[Warn::[\d\-:T\.]*\][ a-zA-Z@\[\]\d\.\\\/:]*\n", res) &&
                           occursin(r"warn_line_1\n", res) &&
                           occursin(r"warn_line_2\n", res))
                    @test (occursin(r"\[Error::[\d\-:T\.]*\][ a-zA-Z@\[\]\d\.\\\/:]*\n", res) &&
                           occursin(r"error_line_1\n", res) &&
                           occursin(r"error_line_2\n", res))
                end
                @testset "Keyword Logging No Debug" begin
                    with_logger(keywordLogging, log)
                    res = string(readlines(defaultLog, keep = true)...)

                    @test !occursin(r"deb = debug", res)
                    @test occursin(r"inf = info", res)
                    @test occursin(r"war = warn", res)
                    @test occursin(r"err = err", res)
                end
                @testset "Logging between Levels No Debug" begin
                    infLog = "infLog"
                    errLog = "errLog"
                    logger = FileLogger(Dict(Info => infLog, Error => errLog))
                    with_logger(singleLineLogging, logger)
                    infres = string(readlines(infLog, keep = true)...)
                    errres = string(readlines(errLog, keep = true)...)

                    @test  (!occursin(r"DEBUG", infres) &&
                            occursin(r"INFO", infres) &&
                            occursin(r"WARN", infres) &&
                            !occursin(r"ERROR", infres))

                    @test  (!occursin(r"DEBUG", errres) &&
                            !occursin(r"INFO", errres) &&
                            !occursin(r"WARN", errres) &&
                            occursin(r"ERROR", errres))
                end

                @testset "Message Limits" begin
                    with_logger(log) do
                        for _ in 1:20
                            @info "message_Limit_test" maxlog=10
                        end
                    end
                    res = string(readlines(defaultLog, keep = true)...)
                    matches = collect(eachmatch(r"message_Limit_test", res))
                    @test length(matches) == 10

                    # This is a different log position with the same message
                    with_logger(log) do
                        for _ in 1:20
                            @info "message_Limit_test" maxlog=10
                        end
                    end
                    res = string(readlines(defaultLog, keep = true)...)
                    matches = collect(eachmatch(r"message_Limit_test", res))
                    @test length(matches) == 20
                end
            end
        end
    end
end
end

end
