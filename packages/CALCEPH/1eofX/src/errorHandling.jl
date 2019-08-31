

"""
    disableCustomHandler()

Disables the user custom error handler.

"""
function disableCustomHandler()
    ccall((:calceph_seterrorhandler, libcalceph), Cvoid,
                  (Cint, Ptr{Cvoid}), 1, C_NULL)
end

mutable struct UserHandlerContainer
    f::Function
end

const userHandlerContainerInstance = UserHandlerContainer(s::String->Nothing)

function userHandlerWrapper(msg::Cstring)::Cvoid
    global userHandlerContainerInstance
    s = unsafe_string(msg)
    userHandlerContainerInstance.f(s)
    return
end

# see https://discourse.julialang.org/t/cfunction-error-handler/20678
#userHandlerCWrapper = @cfunction(userHandlerWrapper, Cvoid, (Cstring,))
userHandlerCWrapper = Nothing

"""
    setCustomHandler(f::Function)

Sets the user custom error handler.

# Arguments
- `f`: function taking a single argument of type String which will contain the CALCEPH error message. f should return Nothing.

Use setCustomHandler(s->Nothing) to disable CALCEPH error messages printout to the console.

"""
function setCustomHandler(f::Function)
    global userHandlerContainerInstance
    global userHandlerCWrapper
    userHandlerCWrapper = @cfunction(userHandlerWrapper, Cvoid, (Cstring,))
    userHandlerContainerInstance.f = f
    ccall((:calceph_seterrorhandler, libcalceph), Cvoid,
                  (Cint, Ptr{Cvoid}), 3, userHandlerCWrapper)
end
