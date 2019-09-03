const Cftok = UInt32

const IPC_RMID = 0 # remove identifier
const IPC_SET  = 1 # set options
const IPC_STAT = 2 # get options

const IPC_CREAT  = 0o1000 # create entry if key does not exist
const IPC_EXCL   = 0o2000 # fail if key exists
const IPC_NOWAIT = 0o4000 # error if request must wait

const SEM_UNDO = 0x1000 # undo the operation on exit

@static if Sys.isapple()
    const GETPID   = 4 # get sempid
    const GETVAL   = 5 # get semval
    const GETALL   = 6 # get all semval's
    const GETNCNT  = 3 # get semncnt
    const GETZCNT  = 7 # get semzcnt
    const SETVAL   = 8 # set semval
    const SETALL   = 9 # set all semval's
else
    const GETPID   = 11 # get sempid  # 4
    const GETVAL   = 12 # get semval  # 5
    const GETALL   = 13 # get all semval's  # 6
    const GETNCNT  = 14 # get semncnt # 3
    const GETZCNT  = 15 # get semzcnt # 7
    const SETVAL   = 16 # set semval # 8
    const SETALL   = 17 # set all semval's # 9
end

const SEM_STAT = 18 # linux specific
const SEM_INFO = 19 # linux specific

struct SemBuf
    sem_num::Cushort  # semaphore index in array
    sem_op::Cshort    # semaphore operation
    sem_flg::Cshort   # operation flags
end

function SemBuf(sem_num, sem_op; wait::Bool=true, undo::Bool=false)
    flg = 0
    wait || (flg |= IPC_NOWAIT)
    undo && (flg |= SEM_UNDO)
    SemBuf(sem_num, sem_op, flg)
end

ftok(path::String, id::Int) = ccall(:ftok, Cftok, (Cstring,Cint), path, id)

function semcreate(tok::Cftok, nsems::Int; create::Bool=true, create_exclusive::Bool=false, permission::Integer=0o660)
    flags = Cint(permission)
    if create
        flags |= IPC_CREAT
        if create_exclusive
            flags |= IPC_EXCL
        end
    end
    id = ccall(:semget, Cint, (Cftok, Cint, Cint), tok, nsems, flags)
    systemerror("error creating semaphore", id < 0)
    id
end

function semrm(id::Cint)
    ret = ccall(:semctl, Cint, (Cint,Cint,Cint), id, Cint(0), IPC_RMID)
    systemerror("error deleting semaphore", ret < 0)
end

function semset(id::Cint, val::Cint, which=0)
    ret = ccall(:semctl, Cint, (Cint,Cint,Cint,Cint), id, which, SETVAL, val);
    systemerror("error setting semaphore", ret < 0)
end

function semset(id::Cint, vals::Vector{Cushort})
    ret = ccall(:semctl, Cint, (Cint,Cint,Cint,Ptr{Cushort}), id, 0, SETALL, vals);
    systemerror("error setting semaphore", ret < 0)
end

function semget(id::Cint, which=0)
    ccall(:semctl, Cint, (Cint,Cint,Cint), id, which, GETVAL);
end

function semget(id::Cint, vals::Vector{Cushort})
    ret = ccall(:semctl, Cint, (Cint,Cint,Cint,Ptr{Cushort}), id, 0, GETALL, vals);
    systemerror("error getting semaphore", ret < 0)
end

function semop(id::Cint, ops::Vector{SemBuf})
    ret = ccall(:semop, Cint, (Cint,Ptr{Nothing},Csize_t), id, ops, length(ops))
    systemerror("error in semaphore operation", ret < 0)
end
