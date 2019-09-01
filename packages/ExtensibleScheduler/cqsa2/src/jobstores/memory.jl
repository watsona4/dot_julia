using DataStructures: OrderedDict, PriorityQueue
import DataStructures: peek, dequeue!

import Base: length, isempty, push!


"""
    MemoryJobStore()

`MemoryJobStore` implements `AbstractJobStore`.

This is a data structure which is responsible of
storing into memory jobs that should be executed later.
"""
struct MemoryJobStore <: AbstractJobStore
    d::OrderedDict
    q::PriorityQueue

    MemoryJobStore() = new(
        OrderedDict{String,Job}(),
        PriorityQueue{String, Priority}(Base.Order.Reverse)
    )
end

"""
    length(jobstore)

Return the number of jobs stored into jobstore.

A given job can be executed several times 
(periodical jobs for example).
"""
length(jobstore::MemoryJobStore) = length(jobstore.d)

"""
    isempty(jobstore)

Returns `true` when there isn't any job in `jobstore`.
"""
isempty(jobstore::MemoryJobStore) = length(jobstore) == 0
function push!(jobstore::MemoryJobStore, job::Job)
    if hasjob(jobstore, job.id)
        error("Can't add a job with same job_id")
    else
        schedule(jobstore, job, true)
    end
end

"""
    schedule(jobstore, job, first_time)

Schedule a job according its `Priority`.
"""
function schedule(jobstore::MemoryJobStore, job::Job, first_time::Bool)
    now_ = job.dt_updated
    # Calculate the next fire time if there is none defined
    if !hasnextfire(job) || !first_time
        job.dt_next_fire = get_next_dt_fire(job.trigger, DateTime(0), now_)
    end
    jobstore.d[job.id] = job
    priority = Priority(job.dt_next_fire, job.priority)
    jobstore.q[job.id] = priority
    println("[+] $now_ Schedule job $(job.id)")
    dump(job)
    println()
end


"""
    job = peek(jobstore)

Return the next `job` from a `jobstore` without removing it from this `jobstore`.
"""
function peek(jobstore::MemoryJobStore)
    job_id, priority = peek(jobstore.q)
    job = jobstore.d[job_id]
    job
end

"""
    job = dequeue!(jobstore)

Remove and return the next `job` from a `jobstore`.
"""
function dequeue!(jobstore::MemoryJobStore)
    job_id = dequeue!(jobstore.q)
    jobstore.d[job_id]
end

"""
    hasjob(jobstore, job_id)

Return `true` if a job with identifier `job_id` 
is stored into `jobstore`.
"""
function hasjob(jobstore::MemoryJobStore, job_id::String)
    job_id in keys(jobstore.d)
end

"""
    get_job_id(jobstore)

Returns a job identifier (a `job_id`).

Parameter `jobstore` is passed to ensure that 
no other job stored in `jobstore` have same `job_id`.
"""
function get_job_id(jobstore::MemoryJobStore)
    job_id = ""
    while job_id == "" || hasjob(jobstore, job_id)
        job_id = get_job_id()
    end
    job_id
end

"""
    update(jobstore, job, now_)

Update `jobstore` for a given `job`.
Schedule when a `job` should be fire or delete it from `jobstore`
if it shouldn't be fired again.
"""
function update(jobstore::MemoryJobStore, job::Job, now_)
    job.dt_updated = now_
    itr_size = IteratorSize(job.trigger)
    if itr_size == HasLength()
        remaining = length(job.trigger) - job.n_triggered
        if remaining > 0
            schedule(jobstore, job, false)
        elseif remaining == 0
            delete!(jobstore.d, job.id)
        else
            error("remaining should be positive or no")
        end
    elseif itr_size == IsInfinite()
        schedule(jobstore, job, false)
    else
        error("undefined iterator size $itr_size")
    end
end
