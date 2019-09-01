using UUIDs


"""
`AbstractScheduler` is an abstract type for schedulers.

Schedulers are structs which are responsible of running 
`Action` at given instants (according a `Trigger`).

Several kind of schedulers can implement `AbstractScheduler`.

The most simple scheduler is `BlockingScheduler` which is monothread.
"""
abstract type AbstractScheduler end

include("background.jl")
include("blocking.jl")

"""
    get_scheduler_id()

Return a random identifier for a scheduler.
"""
function get_scheduler_id()
    string(UUIDs.uuid4())[1:13]
end