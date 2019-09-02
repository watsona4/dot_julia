# execute tests inside the cluster as a JuliaParBatch job
using JuliaRunClient
using Base.Test

const SUCCESS_INDICATOR = joinpath(ENV["JRUN_DIR"], "success.txt")

isfile(SUCCESS_INDICATOR) && rm(SUCCESS_INDICATOR)
ctx = Context()

# let's see if we can connect to the cluster
@test @result getSystemStatus(ctx)

# get status of self job
myself = self()
mystatus = @result getJobStatus(ctx, myself)
@test mystatus["created"]
@test !mystatus["succeeded"]

myscale = @result getJobScale(ctx, myself)
@test myscale[1] == myscale[2] == 0

initParallel()
sleep(10)
# scale up to 2 workers
@test @result setJobScale(ctx, myself, 2)
waitForWorkers(2)
@test length(workers()) == 2

@test @result setJobScale(ctx, myself, 0)
while true
    w = workers()
    (length(w) == 1) && (w[1] == 1) && break
    sleep(5)
end
touch(SUCCESS_INDICATOR)
chmod(SUCCESS_INDICATOR, 0o777)
