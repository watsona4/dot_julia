using Test
using Dates: now
using ExtensibleScheduler
using ExtensibleScheduler: MemoryJobStore, Job, get_job_id

@testset "JobStores" begin

    function return_args(id)
        "Returned from return_args $id"
    end

    @testset "MemoryJobStore" begin
        jobstore = MemoryJobStore()
        @test isempty(jobstore)

        action1 = Action(return_args, 1)
        @test run(action1) == "Returned from return_args 1"
        trigger1 = Trigger(DateTime(2010, 1, 1))
        id1 = get_job_id(jobstore)
        name1 = "Textual description of job1"
        priority1 = 0
        dt_created1 = now()
        dt_updated1 = dt_created1
        dt_next_fire1 = DateTime(0)
        n_triggered1 = 0
        config1 = JobConfig()
        job1 = Job(id1, action1, trigger1, name1, priority1, dt_created1, dt_updated1, dt_next_fire1, n_triggered1, config1)
        push!(jobstore, job1)
        @test length(jobstore) == 1
        
        action2 = Action(return_args, 2)
        @test run(action2) == "Returned from return_args 2"
        trigger2 = Trigger(DateTime(2010, 1, 1))
        id2 = get_job_id(jobstore)
        @test id2 != id1
        name2 = "Textual description of job2"
        priority2 = 0
        dt_created2 = now()
        dt_updated2 = dt_created2
        dt_next_fire2 = DateTime(0)
        n_triggered2 = 0
        config2 = JobConfig()
        job2 = Job(id2, action2, trigger2, name2, priority2, dt_created2, dt_updated2, dt_next_fire2, n_triggered2, config2)
        push!(jobstore, job2)
        @test length(jobstore) == 2
    end

end