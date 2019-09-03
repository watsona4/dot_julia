using CImGui
using CImGui.CSyntax
using CImGui.CSyntax.CStatic

# demonstrate the various window flags. typically you would just use the default!
control_no_titlebar = false
control_no_scrollbar = true
control_no_menu = true
control_no_move = false
control_no_resize = false
control_no_collapse = false
control_no_close = true
control_no_nav = true
control_no_background = false
control_no_bring_to_front = false

"""
    ShowControlWindow(p_open::Ref{Bool})

Show control window with camera info and controls.
"""
function ShowControlWindow(p_open::Ref{Bool})
    global cam, camImage
    global camSettings, camGPIO
    global sessionStat

    camIsRunning = isrunning(cam)

    # Control window
    # demonstrate the various window flags. typically you would just use the default!
    window_flags = CImGui.ImGuiWindowFlags(0)
    control_no_titlebar       && (window_flags |= CImGui.ImGuiWindowFlags_NoTitleBar;)
    control_no_scrollbar      && (window_flags |= CImGui.ImGuiWindowFlags_NoScrollbar;)
    !control_no_menu          && (window_flags |= CImGui.ImGuiWindowFlags_MenuBar;)
    control_no_move           && (window_flags |= CImGui.ImGuiWindowFlags_NoMove;)
    control_no_resize         && (window_flags |= CImGui.ImGuiWindowFlags_NoResize;)
    control_no_collapse       && (window_flags |= CImGui.ImGuiWindowFlags_NoCollapse;)
    control_no_nav            && (window_flags |= CImGui.ImGuiWindowFlags_NoNav;)
    control_no_background     && (window_flags |= CImGui.ImGuiWindowFlags_NoBackground;)
    control_no_bring_to_front && (window_flags |= CImGui.ImGuiWindowFlags_NoBringToFrontOnFocus;)
    control_no_close && (p_open = C_NULL;) # don't pass our bool* to Begin

    # specify a default position/size in case there's no data in the .ini file.
    # typically this isn't required! we only do it to make the Demo applications a little more welcoming.
    CImGui.SetNextWindowPos((1280-550-20, 20), CImGui.ImGuiCond_FirstUseEver)
    CImGui.SetNextWindowSize((550, 310), CImGui.ImGuiCond_FirstUseEver)

    CImGui.Begin("Control", p_open, window_flags) || (CImGui.End(); return)
    CImGui.Text("ImGui $(CImGui.IMGUI_VERSION)")

    # most "big" widgets share a common width settings by default.
    # CImGui.PushItemWidth(CImGui.GetWindowWidth() * 0.65)    # use 2/3 of the space for widgets and 1/3 for labels (default)
    CImGui.PushItemWidth(CImGui.GetFontSize() * -12)        # use fixed width for labels (by passing a negative value), the rest goes to widgets. We choose a width proportional to our font size.

    CImGui.Text(@sprintf("Display: %.1f FPS", CImGui.GetIO().Framerate))
    CImGui.Text(@sprintf("Framegrab: %.1f FPS", perfGrabFramerate))
    CImGui.Spacing()
    CImGui.Text("Settings")
    ## FRAMERATE
    @cstatic ctrl_framerate=Cfloat(12.00) begin
        ctrl_framerate = Cfloat(camSettings.acquisitionFramerate)
        CImGui.PushItemWidth(200)
        @c CImGui.SliderFloat("Framerate (fps)", &ctrl_framerate,
            camSettingsLimits.acquisitionFramerate[1],
            camSettingsLimits.acquisitionFramerate[2], "%.3f")
        camSettings.acquisitionFramerate = ctrl_framerate
    end

    ## EXPOSURE
    @cstatic ctrl_mode=0 ctrl_exposure=Cfloat(12.00) ctrl_auto=false begin
        ctrl_exposure = Cfloat(camSettings.exposureTime)
        ctrl_auto = (camSettings.exposureAuto == :continuous)
        CImGui.PushItemWidth(200)
        @c CImGui.SliderFloat("Exposure (ms)", &ctrl_exposure,
            camSettingsLimits.exposureTime[1],
            camSettingsLimits.exposureTime[2], "%.3f")
        CImGui.SameLine()
        @c CImGui.Checkbox("Auto exp.", &ctrl_auto)
        #=
        items = map(x->string(x),camSettingsLimits.exposureMode)
        CImGui.PushItemWidth(50); CImGui.SameLine()
        @cstatic item_current="timed" begin #NOT LINKED!!
            # here our selection is a single pointer stored outside the object.
            if CImGui.BeginCombo("Mode", item_current) # the second parameter is the label previewed before opening the combo.
                for n = 0:length(items)-1
                    is_selected = item_current == items[n+1]
                    CImGui.Selectable(items[n+1], is_selected) && (item_current = items[n+1];)
                    is_selected && CImGui.SetItemDefaultFocus() # set the initial focus when opening the combo (scrolling + for keyboard navigation support in the upcoming navigation branch)
                end
                CImGui.EndCombo()
            end
        end
        =#
        if ctrl_auto
            camSettings.exposureAuto = :continuous
        else
            camSettings.exposureAuto = :off
            camSettings.exposureTime = ctrl_exposure
        end
    end

    ## GAIN
    @cstatic ctrl_gain=Cfloat(0.00) ctrl_autogain=false begin
        ctrl_gain = Cfloat(camSettings.gain)
        ctrl_autogain = (camSettings.gainAuto == :continuous)
        CImGui.PushItemWidth(200)
        @c CImGui.SliderFloat("Gain (dB)", &ctrl_gain,
            camSettingsLimits.gain[1],
            camSettingsLimits.gain[2], "%.3f")
        CImGui.SameLine()
        @c CImGui.Checkbox("Auto Gain", &ctrl_autogain)

        if ctrl_autogain
            camSettings.gainAuto = :continuous
        else
            camSettings.gainAuto = :off
            camSettings.gain = ctrl_gain
        end
    end

    #==
    ## GAMMA
    @cstatic ctrl_gamma=Cfloat(12.00) begin
        ctrl_gamma = Cfloat(camSettings.gamma)
        CImGui.PushItemWidth(200)
        @c CImGui.SliderFloat("Gamma", &ctrl_gamma,
            camSettingsLimits.gamma[1],
            camSettingsLimits.gamma[2], "%.3f")
        camSettings.gamma = ctrl_gamma
    end

    ## BLACK LEVEL
    @cstatic ctrl_blacklevel=Cfloat(12.00) begin
        ctrl_blacklevel = Cfloat(camSettings.blackLevel)
        CImGui.PushItemWidth(200)
        @c CImGui.SliderFloat("Black Level", &ctrl_blacklevel,
            camSettingsLimits.blackLevel[1],
            camSettingsLimits.blackLevel[2], "%.3f")
        camSettings.blackLevel = ctrl_blacklevel
    end
    =#


    CImGui.Spacing()
    CImGui.Text("Image Format")



    ## IMAGE OFFSET X
    @cstatic ctrl_val=Cint(0) begin
        ctrl_val = Cint(camSettings.offsetX)
        CImGui.PushItemWidth(200)
        @c CImGui.SliderInt("Offset X", &ctrl_val,
            camSettingsLimits.offsetX[1],
            camSettingsLimits.offsetX[2], "%i")
        camSettings.offsetX = 2*(round(ctrl_val/2,RoundToZero))
    end
    if !camIsRunning
        CImGui.SameLine()
        ## IMAGE WIDTH
        @cstatic ctrl_val=Cint(100) begin
            ctrl_val = Cint(camSettings.width)
            CImGui.PushItemWidth(200)
            @c CImGui.SliderInt("Width", &ctrl_val,
                camSettingsLimits.width[1],
                camSettingsLimits.width[2], "%i")
            camSettings.width = 2*(round(ctrl_val/2,RoundToZero))
        end
    end
    ## IMAGE OFFSET Y
    @cstatic ctrl_val=Cint(0) begin
        ctrl_val = Cint(camSettings.offsetY)
        CImGui.PushItemWidth(200)
        @c CImGui.SliderInt("Offset Y", &ctrl_val,
            camSettingsLimits.offsetY[1],
            camSettingsLimits.offsetY[2], "%i")
        camSettings.offsetY = 2*(round(ctrl_val/2,RoundToZero))
    end
    if !camIsRunning
        CImGui.SameLine()
        ## IMAGE HEIGHT
        @cstatic ctrl_val=Cint(100) begin
            ctrl_val = Cint(camSettings.height)
            CImGui.PushItemWidth(200)
            @c CImGui.SliderInt("Height", &ctrl_val,
                camSettingsLimits.height[1],
                camSettingsLimits.height[2], "%i")
            camSettings.height = 2*(round(ctrl_val/2,RoundToZero))
        end
    end


    ## PLAY/PAUSE
    @cstatic begin
        if camIsRunning
            if CImGui.Button("Pause",(200,25))
                stop!(cam)
                @info "Camera stopped"
            end
        else
            if CImGui.Button("Run",(200,25))
                startcheckrunningfix!(cam)
            end
        end
    end

    ## RECORDING
    @cstatic begin
        if sessionStat.recording
            if CImGui.Button("Stop Recording",(200,25))
                sessionStat.recording = false
                buffermode!(cam,"NewestOnly")
            end
        else
            if CImGui.Button("Record",(200,25))
                sessionStat.recording = true
                buffermode!(cam,"OldestFirst")
            end
        end
        CImGui.SameLine()
        CImGui.Text(@sprintf("Frames: [%i buffered. %i dropped. %i saved]", sessionStat.bufferedframes,sessionStat.droppedframes,sessionStat.savedframes))
    end


    CImGui.End() # demo
end
