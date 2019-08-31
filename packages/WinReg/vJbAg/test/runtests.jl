using WinReg
if VERSION < v"0.7.0-"
    using Base.Test
else
    using Test
end

@test querykey(WinReg.HKEY_LOCAL_MACHINE,"System\\CurrentControlSet\\Control\\Session Manager\\Environment","OS") == "Windows_NT"
