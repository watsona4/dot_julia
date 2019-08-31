#==============================================================================#
# AWSSQS.jl
#
# SQS API. See http://aws.amazon.com/documentation/sqs/
#
# Copyright OC Technology Pty Ltd 2014 - All rights reserved
#==============================================================================#


__precompile__()


module AWSSQS

export sqs_list_queues, sqs_get_queue, sqs_create_queue, sqs_delete_queue,
       sqs_set_policy, sqs_name, sqs_arn,
       sqs_send_message, sqs_send_message_batch, sqs_receive_message,
       sqs_delete_message, sqs_flush, sqs_get_queue_attributes, sqs_count,
       sqs_busy_count


using AWSCore
using SymDict
using Retry
using MbedTLS
using HTTP


const AWSQueue = AWSConfig


"""
    sqs_name(::AWSQueue)

Name of a queue.
"""
sqs_name(q::AWSQueue) = split(q[:resource], "/")[3]


"""
    sqs_arn(::AWSQueue)

ARN of a queue.
"""
sqs_arn(q::AWSQueue) = arn(q, "sqs", sqs_name(q))


sqs(aws::AWSConfig, action, args) = AWSCore.Services.sqs(aws, action, args)

sqs(aws::AWSConfig, action; args...) = sqs(aws, action, stringdict(args))


"""
    sqs_list_queues([::AWSConfig], prefix="")

Returns a list of `::AWSQueue`.

```
for q in sqs_list_queues()
    println(\"\$(sqs_name(q)) has ~\$(sqs_count(q)) messages.\")
end
```
"""
function sqs_list_queues(aws::AWSConfig, prefix="")

    r = sqs(aws, "ListQueues", QueueNamePrefix = prefix)
    if r["queueUrls"] == nothing
        return []
    else
        return [merge(aws, Dict(:resource => HTTP.URI(url).path)) for url in r["queueUrls"]]
    end
end

sqs_list_queues(prefix="") = sqs_list_queues(default_aws_config(), prefix)


"""
    sqs_get_queue([::AWSConfig], name)

Look up a queue by name. Returns `::AWSQueue`.

```
q = sqs_get_queue("my-queue")
sqs_send_message(q, "my message")
```
"""
function sqs_get_queue(aws::AWSConfig, name)

    @protected try

        r = sqs(aws, "GetQueueUrl", QueueName = name)
        url = r["QueueUrl"]
        return merge(aws, Dict(:resource => HTTP.URI(url).path))

    catch e
        @ignore if ecode(e) == "AWS.SimpleQueueService.NonExistentQueue" end
    end

    return nothing
end

sqs_get_queue(name) = sqs_get_queue(default_aws_config(), name)


"""
    sqs_create_queue([::AWSConfig], name; options...)

Create new queue with `name`. Returns `::AWSQueue`.

`options`: `VisibilityTimeout`, `MessageRetentionPeriod`, `DelaySeconds` etc...

See [SQS API Reference](http://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_CreateQueue.html) for detail.

```
q = sqs_create_queue("my-queue")
sqs_send_message(q, "my message")
```
"""
function sqs_create_queue(aws::AWSConfig, name; options...)

    println("""Creating SQS Queue "$name"...""")

    query = Dict(
        "QueueName" => name
    )

    for (i, (k, v)) in enumerate(options)
        query["Attribute.$i.Name"] = k
        query["Attribute.$i.Value"] = v
    end

    @repeat 4 try

        url = sqs(aws, "CreateQueue", query)["QueueUrl"]
        return merge(aws, Dict(:resource => HTTP.URI(url).path))

    catch e

        @retry if ecode(e) == "QueueAlreadyExists"
            sqs_delete_queue(aws, name)
        end

        @retry if ecode(e) == "AWS.SimpleQueueService.QueueDeletedRecently"
            println("""Waiting 1 minute to re-create Queue "$name"...""")
            sleep(60)
        end
    end

    @assert(false) # Unreachable.
end

sqs_create_queue(a; b...) = sqs_create_queue(default_aws_config(), a; b...)


"""
    sqs_set_policy(::AWSQueue, policy)

Set [access `policy`](http://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-creating-custom-policies.html#sqs-creating-custom-policies-access-policy-examples) for a queue.
"""
function sqs_set_policy(queue::AWSQueue, policy::String)

    sqs(queue, "SetQueueAttributes", Dict("Attribute.Name" => "Policy",
                                           "Attribute.Value" => policy))
end


"""
    sqs_delete_queue(::AWSQueue)

Delete a queue.
"""
function sqs_delete_queue(queue::AWSQueue)

    @protected try

        println("Deleting SQS Queue $(sqs_name(queue))")
        sqs(queue, "DeleteQueue")

    catch e
        @ignore if ecode(e) == "AWS.SimpleQueueService.NonExistentQueue" end
    end
end


"""
    sqs_send_message(::AWSQueue, message)

Send a `message` to a queue.
"""
function sqs_send_message(queue::AWSQueue, message)

    sqs(queue, "SendMessage",
               MessageBody = message,
               MD5OfMessageBody = string(digest(MD_MD5, message)))
end


"""
    sqs_send_message_batch(::AWSQueue, messages)

Send a collection of `messages` to a queue.
"""
function sqs_send_message_batch(queue::AWSQueue, messages)

    batch = [Dict("Id" => i, "MessageBody" => message)
        for (i, message) in enumerate(messages)]

    sqs(queue, "SendMessageBatch", SendMessageBatchRequestEntry=batch)
end


"""
    sqs_receive_message(::AWSQueue)

Returns a `Dict` containing `:message` and `:handle`
or `nothing` if the queue is empty.

```
m = sqs_receive_message(q)
println(m[:message])
sqs_delete_message(m)
```
"""
function sqs_receive_message(queue::AWSQueue)

    r = sqs(queue, "ReceiveMessage", MaxNumberOfMessages = "1")
    r = r["messages"]
    if r == nothing
        return nothing
    end

    handle  = r[1]["ReceiptHandle"]
    message = r[1]["Body"]
    md5     = r[1]["MD5OfBody"]

    @assert md5 == bytes2hex(digest(MD_MD5, message))

    @SymDict(message, handle)
end


mutable struct AWSSQSMessages
    queue
end


"""
    sqs_messages(::AWSQueue)

Returns an iterator that retrieves messages from a queue.

```
for m in sqs_messages(q)
    println(m[:message])
    sqs_delete_message(m)
end
```
"""
sqs_messages(queue::AWSQueue) = AWSSQSMessages(queue)

Base.eltype(::Type{AWSSQSMessages}) = Dict{Symbol,Any}
Base.iterate(q::AWSSQSMessages, it=nothing) = (sqs_receive_message(q.queue), nothing)


"""
    sqs_delete_message(::AWSQueue, message)

Delete a `message` from a queue.
"""
function sqs_delete_message(queue::AWSQueue, message)

    sqs(queue, "DeleteMessage", ReceiptHandle = message[:handle])
end


"""
    sqs_flush(::AWSQueue)

Delete all messages from a queue.
"""
function sqs_flush(queue::AWSQueue)

    while (m = sqs_receive_message(queue)) != nothing
        sqs_delete_message(queue, m)
    end
end


"""
    sqs_get_queue_attributes(::AWSQueue)

Get [Queue Attributes](http://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_GetQueueAttributes.html) for a queue.
"""
function sqs_get_queue_attributes(queue::AWSQueue)

    @protected try

        r = sqs(queue, "GetQueueAttributes",
                       Dict("AttributeName.1" => "All"))

        return Dict(i["Name"] => i["Value"] for i in r["Attributes"])

    catch e
        @ignore if ecode(e) == "AWS.SimpleQueueService.NonExistentQueue" end
    end

    return nothing
end


"""
    sqs_count(::AWSQueue)

Approximate number of messages in a queue.
"""
function sqs_count(queue::AWSQueue)

    parse(Int,sqs_get_queue_attributes(queue)["ApproximateNumberOfMessages"])
end


"""
    sqs_busy_count(::AWSQueue)

Approximate number of messages not visible in a queue.
"""
function sqs_busy_count(queue::AWSQueue)

    parse(Int,sqs_get_queue_attributes(queue)["ApproximateNumberOfMessagesNotVisible"])
end



end # module AWSSQS



#==============================================================================#
# End of file.
#==============================================================================#

