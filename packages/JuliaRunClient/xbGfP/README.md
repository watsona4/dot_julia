# JuliaRunClient

A client library to invoke with JuliaRun HTTP APIs.

# APIs

## The API Context

All JuliaRun APIs require a context to operate.  A JuliaRun client context consists of:
- URL of the JuliaRun remote server
- an authentication token
- namespace to operate in

It can be created simply as:

`ctx = Context()`

Default values of all parameters are set to match those inside a JuliaRun cluster.
- connects to a service endpoint at "juliarunremote-svc.juliarun"
- reads the namespace from the default secret
- presents the namespace service token (also read from the default secret) for authentication

Pass appropriate values for each when calling from outside the cluster.

Apart from the context, some APIs also need a job to work with. A job in JuliaRunClient is an instance of one of the [Job types](JobTypes.md) created by passing the job name. The other required and optional parameters of a job type are needed only need to be passed to the job creation API.

## APIs

### `getSystemStatus(ctx)`

Verifies if JuliaRun is running and is connected to a compute cluster.
Returns:
- boolean: true/false indicating success/failure

### `listJobs(ctx)`
List all submitted jobs.

Returns:
- dictionary: of the form `{"jobname": { "type": "JuliaBatch" }...}`

### `getAllJobInfo(ctx)`
List all submitted jobs.

Returns:
- dictionary: of the form `{"jobname": { "type": "JuliaBatch", "status": [], "scale": [], "endpoint": [] }...}`

### `self()`
Returns the current Job.

### `getJobStatus(ctx, job)`
Fetch current status of a Job.

Parameters:
- job: A JRunClientJob of appropriate type

Returns tuple/array with:
- boolean: whether the job completed
- integer: for a parallel job, number of workers that completed successfully
- integer: for a parallel job, number of workers started
- boolean: whether the job has been created (vs. scheduled)
- boolean: whether this is a notebook (legacy, likely to be removed in future)

### `getJobScale(ctx, job)`
Get the current scale of a job.

Parameters:
- job: A JRunClientJob of appropriate type

Returns tuple/array with:
- integer: number of workers running
- integer: number of workers requested

### `initParallel()`
Initialize the current job to accept parallel workers.

Returns a reference to the Julia cluster manager instance.

### `setJobScale(ctx, job, parallelism)`
Request to scale the job up or down to the level of parallelism requested.

Parameters:
- job: A JRunClientJob of appropriate type
- parallelism: number of workers to scale to

Returns:
- boolean: true/false indicating success/failure

### `waitForWorkers(min_workers)`
Wait for a certain number of workers to join.

### `getJobEndpoint(ctx, job)`
Get the endpoint exposed by the job/service.

Parameters:
- job: A JRunClientJob of appropriate type

Returns tuple/array of endpoints as URLs or IP and ports

### `deleteJob(ctx, job; force=false)`
Removes the job entry from the queue.

Parameters:
- job: A JRunClientJob of appropriate type
- force: whether to remove an incomplete job (optional, default: false)

Returns:
- boolean: true/false indicating success/failure

### `tailJob(ctx, job; stream, count)`
Tail logs from the job.

Parameters:
- job: A JRunClientJob of appropriate type
- stream: the stream to read from ("stdout"/"stdin"), all streams are read if not specified.
- count: number of log entries to return (50 by default)

Returns a string of log entries separated by new line.

### `submitJob(ctx, job; kwargs...)`
Submit a job definition to execute on the cluster.

Parameters:
- job: A JRunClientJob of appropriate type
- job specific parameters, with names as documented for the JobType constructor

Returns nothing.
