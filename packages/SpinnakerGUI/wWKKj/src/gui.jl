using CImGui
using CImGui.CSyntax
using CImGui.GLFWBackend
using CImGui.OpenGLBackend
using CImGui.GLFWBackend.GLFW
using CImGui.OpenGLBackend.ModernGL
using CImGui.CSyntax.CStatic
using CImGui: ImVec2, ImVec4, IM_COL32, ImS32, ImU32, ImS64, ImU64

using Printf
using Random, FixedPointNumbers

include("gui/gui_control.jl")

function gui(;timerInterval::AbstractFloat=1/60)
    global gui_open, control_open
    global camSettings, camGPIO

    @static if Sys.isapple()
        # GL_LUMINANCE not available >= 3.0
        # OpenGL 2.1 + GLSL 120
        glsl_version = 120
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 2)
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 1)
        #GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE) # 3.2+ only
        #GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE) # required on Mac 3.0+ only
    else
        # OpenGL 3.0 + GLSL 130
        glsl_version = 120
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 2)
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 1)
        # GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE) # 3.2+ only
        # GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE) # 3.0+ only
    end


    # setup GLFW error callback
    error_callback(err::GLFW.GLFWError) = @error "GLFW ERROR: code $(err.code) msg: $(err.description)"
    GLFW.SetErrorCallback(error_callback)

    # create window
    v = get_my_version()
    window = GLFW.CreateWindow(1280, 720, "SpinnakerGUI v$v")
    @assert window != C_NULL
    GLFW.MakeContextCurrent(window)
    GLFW.SwapInterval(0)  # disable vsync
    #GLFW.SwapInterval(1)  # enable vsync

    # setup Dear ImGui context
    ctx = CImGui.CreateContext()

    # setup Dear ImGui style
    CImGui.StyleColorsDark()
    # CImGui.StyleColorsClassic()
    # CImGui.StyleColorsLight()

    # Load fonts
    fonts_dir = joinpath(@__DIR__, "gui", "fonts")
    fonts = CImGui.GetIO().Fonts
    CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "Roboto-Medium.ttf"), 14)

    # load Fonts
    # - If no fonts are loaded, dear imgui will use the default font. You can also load multiple fonts and use `CImGui.PushFont/PopFont` to select them.
    # - `CImGui.AddFontFromFileTTF` will return the `Ptr{ImFont}` so you can store it if you need to select the font among multiple.
    # - If the file cannot be loaded, the function will return C_NULL. Please handle those errors in your application (e.g. use an assertion, or display an error and quit).
    # - The fonts will be rasterized at a given size (w/ oversampling) and stored into a texture when calling `CImGui.Build()`/`GetTexDataAsXXXX()``, which `ImGui_ImplXXXX_NewFrame` below will call.
    # - Read 'fonts/README.txt' for more instructions and details.
    # fonts_dir = "gui/fonts"
    # fonts = CImGui.GetIO().Fonts
    # default_font = CImGui.AddFontDefault(fonts)
    # CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "Cousine-Regular.ttf"), 15)
    # CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "DroidSans.ttf"), 16)
    # CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "Karla-Regular.ttf"), 10)
    # CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "ProggyTiny.ttf"), 10)
    # CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "Roboto-Medium.ttf"), 16)
    # @assert default_font != C_NULL

    image_id = nothing
    previewImageWidth = nothing
    previewImageHeight = nothing


    # setup Platform/Renderer bindings
    ImGui_ImplGlfw_InitForOpenGL(window, true)
    ImGui_ImplOpenGL3_Init(glsl_version)

    clear_color = Cfloat[0.45, 0.55, 0.60, 1.00]
    previousSize = nothing
    looptime = 0.0
    guiTimer = Timer(0,interval=timerInterval)
    firstLoop = true
    while !GLFW.WindowShouldClose(window) && !sessionStat.terminate
        t_before = time()
        if camImage != nothing
            local_camImage = deepcopy(camImage) #Create copy to prevent async error if size is read at different time to image
            io = CImGui.GetIO()

            GLFW.PollEvents()
            # start the Dear ImGui frame
            ImGui_ImplOpenGL3_NewFrame()
            ImGui_ImplGlfw_NewFrame()
            CImGui.NewFrame()
            gui_open = true

            control_open && @c ShowControlWindow(&control_open)

            # specify a default position/size in case there's no data in the .ini file.
            # typically this isn't required! we only do it to make the Demo applications a little more welcoming.
            CImGui.SetNextWindowPos((20, 20), CImGui.ImGuiCond_FirstUseEver)
            CImGui.SetNextWindowSize((1280-550-20-20-20, 720-20-20), CImGui.ImGuiCond_FirstUseEver)


            # show image example
            CImGui.Begin("Raw Video Preview")
            previewWindowWidth = CImGui.GetWindowWidth() - 20
            previewWindowHeight = CImGui.GetWindowHeight() - 40 # subtracting top bar
            previewWindowAspect = previewWindowWidth / previewWindowHeight

            pos = CImGui.GetCursorScreenPos()


            camImageSize = size(local_camImage)
            camImageAspect = camImageSize[1]/camImageSize[2]

            if camImageSize != previousSize || firstLoop # creat texture for image drawing
                image_id = ImGui_ImplOpenGL3_CreateImageTexture(camImageSize[1], camImageSize[2])
                previousSize = camImageSize
            end
            ImGui_ImplOpenGL3_UpdateImageTexture(image_id, local_camImage, camImageSize[1], camImageSize[2],format=GL_LUMINANCE,type=GL_UNSIGNED_BYTE)
            if previewWindowAspect > camImageAspect
                previewImageHeight = previewWindowHeight
                previewImageWidth = previewImageHeight * camImageAspect
            else
                previewImageWidth = previewWindowWidth
                previewImageHeight = previewImageWidth / camImageAspect
            end
            CImGui.Image(Ptr{Cvoid}(image_id), (Cfloat(previewImageWidth), Cfloat(previewImageHeight)))
            if CImGui.IsItemHovered()
                CImGui.BeginTooltip()
                region_sz = 32.0

                region_x = io.MousePos.x - pos.x - region_sz * 0.5
                region_x = clamp(region_x,0.0,previewImageWidth - region_sz)

                region_y = io.MousePos.y - pos.y - region_sz * 0.5
                region_y = clamp(region_y,0.0,previewImageHeight - region_sz)

                zoom = 4.0
                #CImGui.Text(@sprintf("Min: (%d, %d)", region_x, region_y))
                #CImGui.Text(@sprintf("Max: (%d, %d)", region_x + region_sz, region_y + region_sz))
                uv0 = ImVec2(region_x / previewImageWidth, region_y / previewImageHeight)
                uv1 = ImVec2((region_x + region_sz) / previewImageWidth, (region_y + region_sz) / previewImageHeight)
                CImGui.Image(Ptr{Cvoid}(image_id), ImVec2(region_sz * zoom, region_sz * zoom), uv0, uv1, (255,255,255,255), (255,255,255,128))
                CImGui.EndTooltip()
            end

            CImGui.End()

            # rendering
            CImGui.Render()
            GLFW.MakeContextCurrent(window)
            display_w, display_h = GLFW.GetFramebufferSize(window)
            glViewport(0, 0, display_w, display_h)
            glClearColor(clear_color...)
            glClear(GL_COLOR_BUFFER_BIT)
            ImGui_ImplOpenGL3_RenderDrawData(CImGui.GetDrawData())

            GLFW.MakeContextCurrent(window)
            GLFW.SwapBuffers(window)

            firstLoop = false
        end
        if time()-t_before < timerInterval
            wait(guiTimer)
        else
            yield()
        end
    end
    close(guiTimer)
    guiTimer = nothing
    # cleanup
    ImGui_ImplOpenGL3_Shutdown()
    ImGui_ImplGlfw_Shutdown()
    CImGui.DestroyContext(ctx)

    GLFW.DestroyWindow(window)
    gui_open = false
end
