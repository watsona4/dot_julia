#Contains MPI related things that the library is missing
import MPI

#TODO document

# The RSend constand isn't defined on windows
const MPI_RSEND = if Sys.iswindows()
                      (:MPI_RSEND, MPI.libmpi)
                  else
                      MPI.MPI_RSEND
                  end

function MPI_Rsend(buf::MPI.MPIBuffertype{T}, count::Integer,
                dest::Integer, tag::Integer, comm::MPI.Comm) where T
    ccall(MPI_RSEND, Nothing,
        (Ptr{T}, Ref{Cint}, Ref{Cint}, Ref{Cint}, Ref{Cint}, Ref{Cint},
           Ref{Cint}),
        buf, count, MPI.mpitype(T), dest, tag, comm.val, 0)
end

function MPI_Rsend(buf::AbstractArray{T}, dest::Integer, tag::Integer, comm::MPI.Comm) where T
    MPI_Rsend(buf, length(buf), dest, tag, comm)
end

function MPI_Rsend(obj::T, dest::Integer, tag::Integer, comm::MPI.Comm) where T
    MPI_Rsend([obj], dest, tag, comm)
end
