using Test
using Dates: now
using ExtensibleScheduler
using ExtensibleScheduler: Job, get_job_id, JobConfig

@testset "Job" begin

    function return_args(id)
        "Returned from return_args $id"
    end

    id1 = get_job_id()
    action1 = Action(return_args, 1)
    @test run(action1) == "Returned from return_args 1"
    trigger1 = Trigger(DateTime(2010, 1, 1))
    name1 = "Textual description of job1"
    priority1 = 0
    dt_created1 = now()
    dt_updated1 = dt_created1
    dt_next_fire1 = DateTime(0)
    n_triggered1 = 0
    config1 = JobConfig()
    job1 = Job(id1, action1, trigger1, name1, priority1, dt_created1, dt_updated1, dt_next_fire1, n_triggered1, config1)

end