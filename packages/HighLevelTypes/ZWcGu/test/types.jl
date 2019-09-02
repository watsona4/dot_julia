
@hl struct Person
    name::String
end
    
@hl struct Developer <: Person
    salary::Int
end

@hl struct SpecializedDeveloper <: Developer
    language::String
end

function sumsalaries(first::Developer, second::Developer)
    return first.salary + second.salary
end

@hl struct Job
    nb_hours::Int
    assigned_dev::Developer
end

@concretify @hl struct ConcreteJob
    nb_hours::Int
    assigned_dev::Developer
end
