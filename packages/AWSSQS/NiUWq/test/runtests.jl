#==============================================================================#
# SQS/test/runtests.jl
#
# Copyright OC Technology Pty Ltd 2014 - All rights reserved
#==============================================================================#


using AWSSQS
using AWSCore
using Test
using Dates

AWSCore.set_debug_level(1)


#-------------------------------------------------------------------------------
# Load credentials...
#-------------------------------------------------------------------------------

aws = AWSCore.aws_config(region="ap-southeast-2")



#-------------------------------------------------------------------------------
# SQS tests
#-------------------------------------------------------------------------------

for q in sqs_list_queues(aws, "ocaws-jl-test-queue-")
    sqs_delete_queue(q)
end

test_queue = "ocaws-jl-test-queue-" * lowercase(Dates.format(now(Dates.UTC),
                                                            "yyyymmddTHHMMSSZ"))
@testset "test queue" begin 
qa = sqs_create_queue(aws, test_queue)

qb = sqs_get_queue(aws, test_queue)

@test qa[:resource] == qb[:resource]

sqs_send_message(qa, "Hello!")

m = sqs_receive_message(qa)
@test m[:message] == "Hello!"

sqs_delete_message(qa, m)
sqs_flush(qa)

msgs = repeat(["test message"], outer = 10)
sqs_send_message_batch(qa, msgs) # this do not work  
for i in 1:10
    m = sqs_receive_message(qa)
    @test m[:message] == "test message"
    sqs_delete_message(qa, m)
end 
sqs_flush(qa)

info = sqs_get_queue_attributes(qa)
@test info["ApproximateNumberOfMessages"] == "0"
@test sqs_count(qa) == 0

sqs_delete_queue(qa)

end 
#==============================================================================#
# End of file.
#==============================================================================#
