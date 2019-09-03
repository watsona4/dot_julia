module SpinnakerGUI

Base.@kwdef mutable struct sessionStatus
    recording::Bool = false
    bufferedframes::Int64 = 0
    savedframes::Int64 = 0
    terminate::Bool = false
    droppedframes::Int64 = 0
    resolutionupdate::Bool = true
end

include("utils.jl")

# camera settings
include("camera-settings.jl")
cam = nothing
sessionStat = sessionStatus()
camSettings = settings()
camSettingsLimits = settingsLimits()
camGPIO = GPIO()
camGPIOLimits = GPIOLimits()

# Load camera framework
ENV["USE_DUMMYCAM"] = 0         #Force dummycam
@static if Sys.isapple() || ENV["USE_DUMMYCAM"]=="1"  # Spinnaker not currently available for MacOS or CI testing
    include("camera-dummy.jl")
else
    include("camera-spinnaker.jl")
end

# global image buffers
camImage = nothing
camImageFrameBuffer = Vector{Array{UInt8}}(undef,0)

# GUI settings
gui_open = nothing
control_open = true

# performance reporting
perfGrabFramerate = 0.0



include("gui.jl")
include("recording.jl")

function start(;camid::Int64=0,recordthreads=0,reccompression=0)
    global cam, gui_open
    global sessionStat
    global camImageFrameBuffer
    sessionStat.terminate = false
    sessionStat.recording = false
    sessionStat.savedframes = 0
    sessionStat.bufferedframes = 0
    sessionStat.droppedframes = 0
    camImageFrameBuffer = Vector{Array{UInt8}}(undef,0)

    cam = cam_init(camid=camid)

    gui_open = true # Async means you have to assume it's open - could be improved
    # Start gui (operates asynchronously at at ~60 FPS)
    @info "Starting GUI (async)"
    t_gui = @async_errhandle gui(timerInterval=1/60)

    # Start settings updater (operates asynchronously at at ~10 FPS)
    @info "Starting Camera Settings Updater (async)"
    t_settings = @async_errhandle camSettingsUpdater(timerInterval=1/10)

    # Start recording listener
    @info "Starting recording listener (async)"
    t_recorder = @async_errhandle videowritelistener(threads=recordthreads,compression=reccompression)

    # Run camera control with priority
    @info "Starting Camera Acquisition (async)"
    t_capture = @async_errhandle runCamera()

    governorTimer = Timer(0.0, interval = 1)
    while !istaskdone(t_gui) && !istaskdone(t_settings) && !istaskdone(t_recorder) && !istaskdone(t_capture)
        wait(governorTimer)
    end

    if !gui_open && istaskdone(t_gui) && !istaskdone(t_settings) && !istaskdone(t_recorder) && !istaskdone(t_capture)
        # if the gui finished, and nothing else finished
        sessionStat.terminate = true #send terminate bool to async functions

        while !istaskdone(t_gui) || !istaskdone(t_settings) || !istaskdone(t_recorder) || !istaskdone(t_capture)
            wait(Timer(0.1))
        end
        @info "SpinnakerGUI: Successful exit"
    else
        println("") #Async errors cause a lack of new line
        @info "SpinnakerGUI: Something went wrong:"

        istaskdone(t_gui) && @info "GUI crashed"
        istaskdone(t_settings) && @info "Camera settings updater crashed"
        istaskdone(t_recorder) && @info "Record listener crashed"
        istaskdone(t_capture) && @info "Camera acquisition crashed"

        sessionStat.terminate = true
    end
    Spinnaker._release!(cam)
    return nothing
end


export start

end
