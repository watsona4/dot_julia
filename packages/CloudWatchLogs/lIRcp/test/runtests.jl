using Mocking
Mocking.enable(; force=true)

using CloudWatchLogs
using CloudWatchLogs: MAX_EVENT_SIZE

import AWSCore
import AWSCore.Services: logs, sts
using AWSCore: AWSConfig, aws_config, AWSCredentials, AWSException
using Dates
using EzXML
using HTTP
using Printf
using Memento
using Memento.TestUtils
using Test
using TimeZones
using UUIDs

const LOGGER = getlogger(CloudWatchLogs)


function assume_role(config::AWSConfig, role_arn::AbstractString; kwargs...)
    response = sts(
        config,
        "AssumeRole";
        RoleArn=role_arn,
        RoleSessionName=session_name(),
        kwargs...
    )

    response_creds = response["Credentials"]
    response_user = response["AssumedRoleUser"]

    AWSCredentials(
        response_creds["AccessKeyId"],
        response_creds["SecretAccessKey"],
        response_creds["SessionToken"],
        response_user["Arn"],
    )
end

function session_name()
    user = get(ENV, "USER", "unknown")
    location = gethostname()

    name = "$user@$location"
    ts = string(round(Int, time()))

    # RoleSessionName must be no more than 64 characters
    max_name_length = 64 - length(ts) - 1

    if length(name) > max_name_length
        name = name[1:max_name_length-3] * "..."
    end

    return "$name-$ts"
end

function stack_output(config::AWSConfig, stack_name::AbstractString)
    outputs = Dict{String, String}()

    # https://github.com/JuliaCloud/AWSCore.jl/issues/41
    response = AWSCore.service_query(
        config;
        service="cloudformation",
        version="2010-05-15",
        operation="DescribeStacks",
        args=[:StackName=>stack_name],
        return_raw=true,
    )

    xml = EzXML.root(EzXML.parsexml(response))
    ns = EzXML.namespace(xml)
    outputs_xml = findall("//ns:Stacks/ns:member[1]/ns:Outputs/ns:member", xml, ["ns"=>ns])
    for output_xml in outputs_xml
        key = string(findfirst("//ns:OutputKey/text()", output_xml, ["ns"=>ns]))
        val = string(findfirst("//ns:OutputValue/text()", output_xml, ["ns"=>ns]))
        outputs[key] = val
    end

    return outputs
end


@testset "CloudWatchLogs.jl" begin
    include("event.jl")
    include("mocked_aws.jl")
    include("online.jl")
end
