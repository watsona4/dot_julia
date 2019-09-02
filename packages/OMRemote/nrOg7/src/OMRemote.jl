__precompile__(true)
module OMRemote

  # (C) Christian Kral, 2017-2019, BSD-3 license
  # OMRemote remote access to run OpenModelica simulations from Julia
  # https://gitlab.com/christiankral/RemoteOM.git

  using OMJulia
  using Base

  export envOM, simulateOM

  function envOM(env...)
    # Set environment variables
    if length(env) == 0
      println("Setting environment for OpenModelica: OPENMODELICAHOME=/usr/")
      ENV["OPENMODELICAHOME"] = "/usr/"
    else
      println("Setting environment for OpenModelica: OPENMODELICAHOME="*env)
      ENV["OPENMODELICAHOME"] = env[1]
    end
  end

  """
  # Function call

  resFile = `simulateOM(model;sysLibs="Modelica",
  sysVers = "", workFiles = "", files = "",
  workDir = "/work", simDir = "/tmp/OpenModelica",
  StartTime = 0, StopTime = 0, Tolerance = 1E-6, copy = false)`

  # Description

  This function simulates and OpenModelica model and returns the file name
  of the result file

  # Variables

  `model` Modelica experiment to be simulated (incl. dot notation)

  `sysLibs` Modelica system libraries included by OpenModelica; default
            is the Modelica Standard Library (MLS) "Modelica"; several
            libraries may be separated by `:`

  `sysVers` Versions of system libaries (::String); the number of versions seperated
            by `:` has to be equal to the number of system libraries seperated
            by `:`

  `workFiles` Modelica files to be loaded, which, e.g., contain `model`; the
              Modelica files have to be located in in `workDir`; several
              files may be separated by `:`

  `files` Additional Modelica files to be loaded; the absolute file path has
          to be provided in order to read the file properly; several
          files may be separated by `:`

  `workDir` Working directory; default value = "/work"

  `simDir` Simulation directory, default value = "/tmp/OpenModelica"

  `StartTime` Start time of simulation; default value = 0

  `StopTime` Stop time of simulation; if the StopTime <= StartTime,
             the original setting from the Experiment
             annotation is used; default value = 0

  `Tolerance` Simulation tolerance; default value = 1E-6

  `NumberOfIntervals` Number of output intervals; default value = 500

  `copy` Copy simulation result created by OpenModelica to directory `workDir`,
         if `true`; default value = false; in case of `true` the copied file
         name is assigned to the return variable `resFile`, otherwise the
         original file location created by OpenModelica is assigned to `resFile`
  """
  function simulateOM(model;sysLibs="Modelica",sysVers="",workFiles="",files="",
                      workDir="/work",simDir="/tmp/OpenModelica",
                      StartTime=0,StopTime=0,Tolerance=1E-6,
                      NumberOfIntervals=500, copy=true)

    localDir=pwd()
    # Load MSL and libraries (separated by :) and simulate model
    # Result determined by DyMat is return argument

    # Set environment variable for system libraries
    envOM()

    # Exstension of result file, created by OpenModelica
    resExt = "_res.mat"
    rm(simDir,force=true,recursive=true)
    mkdir(simDir)
    cd(simDir)
    omc = OMJulia.OMCSession()
    # Change directory in OM
    OMJulia.sendExpression(omc, "cd(\""*simDir*"\")")

    # Set system directory
    # sysDir = ENV["OPENMODELICAHOME"]*"/"*sysdir*"/"

    # Load system libraries
    sysLibsList = split(sysLibs,":")
    sysVersList = split(sysVers,":")
    for k in collect(1:length(sysLibsList))
      # Determine name of system library
      sysLib = sysLibsList[k]
      if length(sysLibsList)>length(sysVersList)
        # Not every sysLib entry has a version number
        # In this case the version number is not treated at all
        if sysLib!=""
          print("  loadModel("*sysLib*")")
          OMJulia.sendExpression(omc, "loadModel("*sysLib*")")
          if status==true
            println(" successful")
          else
            println(" failed")
          end
        end
      elseif length(sysLibsList)==length(sysVersList)
        # Every sysLib entry has a version number
        # In this case the version number is treated
        # Determine version of system library
        sysVer = sysVersList[k]
        if sysLib!=""
          if sysVer==""
            print("  loadModel("*sysLib*")")
            status = OMJulia.sendExpression(omc, "loadModel("*sysLib*")")
          else
            print("  loadModel("*sysLib*",{\""*sysVer*"\"})")
            status = OMJulia.sendExpression(omc, "loadModel("*sysLib*",{\""*sysVer*"\"})")
          end
          if status==true
            println(" successful")
          else
            println(" failed")
          end
        end
      else
        error("sysLibs and sysVers string entries, separated by : are not equal")
      end
    end

    # Load Modelica work files
    workFilesList = split(workFiles,":")
    for workFile in workFilesList
      if workFile != ""
        print("  loadFile("*workDir*"/"*workFile*")")
        OMJulia.sendExpression(omc, "loadFile(\""*workDir*"/"*workFile*"\")")
        if status==true
          println(" successful")
        else
          println(" failed")
        end
      end
    end

    # Load additional Modelica files
    filesList = split(files,":")
    for file in filesList
      if file!=""
        print("  loadFile("*file*")")
        status = OMJulia.sendExpression(omc, "loadfile(\"*file*\")")
        if status==true
        else
          println(" failed")
          println(" successful")
        end
      end
    end

    print("  instantiateModel("*model*")")
    status = OMJulia.sendExpression(omc, "instantiateModel("*model*")")
    if status!=""
      println(" successful")
    else
      println(" failed")
    end

    # Assemble options
    simulateOpts=",tolerance="*string(Tolerance)
    if StartTime!=0
      simulateOpts=", startTime="*string(StartTime)
    end
    if StopTime>StartTime
      simulateOpts=", stopTime="*string(StopTime)
    end
    if NumberOfIntervals!=500
      simulateOpts=", numberOfIntervals="*string(NumberOfIntervals)
    end
    # Run simulaton
    print("  simulate("*model*simulateOpts*")")
    status = OMJulia.sendExpression(omc, "simulate("*model*simulateOpts*")")
    if status!=""
      println(" successful")
    else
      println(" failed")
    end

    simFile = simDir*"/"*model*resExt
    if copy
      resFile = workDir*"/"*model*resExt
      println("  copy result file from: "*simDir*"/"*model*resExt)
      println("                     to: "*resFile)
      cp(simFile,resFile,force=true)
      # Return handle and result file
      return resFile
    else
      return simFile
    end
    cd(localDir)
  end

end
