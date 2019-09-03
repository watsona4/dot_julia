using SlurmWorkloadFileGenerator.Directives

export Sbatch,
    prefix,
    ARRAY,
    ACCOUNT,
    COMMENT,
    CPUS_PER_GPU,
    CPUS_PER_TASK,
    DISTRIBUTION,
    INPUT,
    JOB_NAME,
    MAIL_TYPE,
    MAIL_USER,
    MEM,
    MEM_PER_CPU,
    NODES,
    NTASKS,
    NTASKS_PER_CORE,
    NTASKS_PER_NODE,
    OUTPUT,
    PARTITION,
    PRIORITY,
    QUIET,
    RESERVATION,
    CORE_SPEC,
    TIME,
    UID,
    VERSION,
    VERBOSE,
    WAIT,
    EXCLUDE

struct Sbatch{A <: AbstractVector{<: Directive}, B <: AbstractString}
    directives::A
    script::B
end

prefix(::Sbatch) = "SBATCH"

ARRAY(v) = Directive("array", 'a', v)
ACCOUNT(v) = Directive("account", 'A', v)
COMMENT(v) = Directive("comment", nothing, v)
CPUS_PER_GPU(v) = Directive("cpus-per-gpu", nothing, v)
CPUS_PER_TASK(v) = Directive("cpus-per-task", 'c', v)
DISTRIBUTION(v) = Directive("distribution", 'm', v)
INPUT(v::AbstractString) = Directive("input", 'i', v)
JOB_NAME(v::AbstractString) = Directive("job-name", 'J', v)
MAIL_TYPE(v) = Directive("mail-type", nothing, v)
MAIL_USER(v::AbstractString) = Directive("mail-user", nothing, v)
MEM(v) = Directive("mem", nothing, v)
MEM_PER_CPU(v) = Directive("mem-per-cpu", nothing, v)
NODES(v) = Directive("nodes", 'N', v)
NTASKS(v) = Directive("ntasks", 'n', v)
NTASKS_PER_CORE(v::Integer) = Directive("ntasks-per-core", nothing, v)
NTASKS_PER_NODE(v::Integer) = Directive("ntasks-per-node", nothing, v)
OUTPUT(v::AbstractString) = Directive("output", 'o', v)
PARTITION(v) = Directive("partition", 'p', v)
PRIORITY(v) = Directive("priority", nothing, v)
QUIET(v::Bool) = Directive("quiet", 'Q', v)
RESERVATION(v) = Directive("reservation", nothing, v)
CORE_SPEC(v) = Directive("core-spec", 'S', v)
TIME(v) = Directive("time", 't', v)
UID(v) = Directive("uid", nothing, v)
VERSION(v) = Directive("version", 'V', v)
VERBOSE(v) = Directive("verbose", 'v', v)
WAIT(v) = Directive("wait", 'W', v)
EXCLUDE(v) = Directive("exclude", 'x', v)
