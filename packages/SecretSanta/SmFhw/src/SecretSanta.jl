module SecretSanta

using Combinatorics
using Dates
using GLPKMathProgInterface
using JSON
using JuMP
using Random
using SMTPClient

struct SecretSantaModel
    model::JuMP.Model
    data::Dict{String, Any}
    constraints::Dict{Symbol, Any} # JuMP constraint references.
    variables::Dict{Symbol, Any} # JuMP variable references.
    solution::Dict{String, Any} # Solution reference.
end

function SecretSantaModel(data::Dict{String, Any})
    # Create the set of the participants.
    P = data["participants"]

    # Create the node set.
    N = [x["email"] for x in P]
    
    # Create arcs for a complete bipartite graph.
    exclude = vcat([[[x["email"], y] for y in x["exclude"]] for x in P]...)
    A = collect(combinations(N, 2)) # Collect arcs from i to j.
    A = vcat([reverse(a) for a in A], A) # Concatenate arcs from j to i.
    A = filter(x -> !(x in exclude), A) # Remove excluded arcs.
    A = [(a[1], a[2]) for a in A] # Convert to array of tuples.

    # Shuffle the array of arcs to induce random solutions.
    A = Random.shuffle(A)

    # Create the JuMP model.
    model = Model(solver = GLPKSolverMIP(msg_lev = 0))
    variables = Dict{Symbol, Any}(:x => nothing)
    constraints = Dict{Symbol, Any}(:out_flow => nothing, :in_flow => nothing)
    constraints[:out_flow] = Dict{String, ConstraintRef}()
    constraints[:in_flow] = Dict{String, ConstraintRef}()

    # Create variables corresponding to arc selection.
    variables[:x] = @variable(model, [a in A], lowerbound = 0, upperbound = 1,
                              start = 0, category = :Cont, basename = "x")

    for i in N
        out_arcs = collect(filter(x -> (x[1] == i), A))
        out_vars = Array{JuMP.Variable}([variables[:x][a] for a in out_arcs])
        constraints[:out_flow][i] = @constraint(model, sum(out_vars) == 1)

        in_arcs = collect(filter(x -> (x[2] == i), A))
        in_vars = Array{JuMP.Variable}([variables[:x][a] for a in in_arcs])
        constraints[:in_flow][i] = @constraint(model, sum(in_vars) == 1)
    end

    solution = Dict{String, Any}()
    ssm = SecretSantaModel(model, data, constraints, variables, solution)
    return ssm # Return the SecretSantaModel instance.
end

function build_model(input_path::String)
    data = JSON.parsefile(input_path)
    return SecretSantaModel(data)
end

function solve_model(ssm::SecretSantaModel)
    status = JuMP.solve(ssm.model)

    if status == :Optimal
        A = ssm.variables[:x].indexsets[1]
        return filter(a -> isapprox(getvalue(ssm.variables[:x][a]), 1.0), A)
    else
        error("Secret Santa assignment is not possible. Adjust participants.")
    end
end

function send_email(ssm::SecretSantaModel, sender::Dict{String,Any}, recipient::Dict{String,Any}, test::Bool = true)
    # Prepare the subject of the email.
    subject = ssm.data["email"]["subject"]
    recipient_name = recipient["name"]
    subject = replace(subject, "{recipient}" => recipient_name)

    # Prepare the body of the email.
    message = ssm.data["email"]["message"]
    sender_name = sender["name"]
    sender_email = sender["email"]
    recipient_email = recipient["email"]
    message = replace(message, "{sender}" => sender_name)
    message = replace(message, "{recipient}" => recipient_name)
    message = replace(message, "{recipient_email}" => recipient_email)

    time_now = Dates.now(Dates.UTC)
    datetime = Dates.format(time_now, "e, dd u yyyy HH:MM:SS")

    body = "Date: $(datetime) +0000\n" *
           "From: Santa Claus <$(ssm.data["email"]["username"])>\n" *
           "To: $(sender_email)\n" * "Subject: $(subject)\n" * "\n" *
           message * "\n"

    body_io = IOBuffer(body)

    # Prepare email sending options.
    opt = SendOptions(isSSL = true, username = ssm.data["email"]["username"],
                      passwd = ssm.data["email"]["password"])

    # Prepare the email.
    server = ssm.data["email"]["smtp_server"]
    port = string(ssm.data["email"]["smtp_port"])
    url = "smtps://$(server):$(port)"
    rcpt = ["$(sender_email)"]
    from = "$(ssm.data["email"]["username"])"

    if !test
        # Send the email.
        resp = send(url, rcpt, from, body_io, opt)
    else
        println("------------------------------------------------------------")
        println("Message to $(sender_name) ($(sender_email))")
        println("Subject: $(subject)")
        println("$(message)")
        println("------------------------------------------------------------")
    end
end

function send_matchings(ssm::SecretSantaModel, solution::Array{Tuple{String, String}, 1}, test::Bool = true)
    participants = ssm.data["participants"]

    for matching in solution
        sender = findfirst(x -> x["email"] == matching[1], participants)
        recipient = findfirst(x -> x["email"] == matching[2], participants)
        send_email(ssm, participants[sender], participants[recipient], test)
    end
end

function run(input_path::String; test::Bool = true)
    ssm = build_model(input_path)
    solution = solve_model(ssm)
    send_matchings(ssm, solution, test)
end

end
