__precompile__(true)
module WinReg

export querykey

const HKEY_CLASSES_ROOT     = 0x80000000
const HKEY_CURRENT_USER     = 0x80000001
const HKEY_LOCAL_MACHINE    = 0x80000002
const HKEY_USERS            = 0x80000003
const HKEY_PERFORMANCE_DATA = 0x80000004
const HKEY_CURRENT_CONFIG   = 0x80000005
const HKEY_DYN_DATA         = 0x80000006


const REG_NONE                    = 0 # no value type
const REG_SZ                      = 1 # null-terminated ASCII string
const REG_EXPAND_SZ               = 2 # Unicode nul terminated string
const REG_BINARY                  = 3 # Free form binary
const REG_DWORD                   = 4 # 32-bit number
const REG_DWORD_LITTLE_ENDIAN     = 4 # 32-bit number (same as REG_DWORD)
const REG_DWORD_BIG_ENDIAN        = 5 # 32-bit number
const REG_LINK                    = 6 # Symbolic Link (unicode)
const REG_MULTI_SZ                = 7 # Multiple Unicode strings
const REG_RESOURCE_LIST           = 8 # Resource list in the resource map
const REG_FULL_RESOURCE_DESCRIPTOR = 9 # Resource list in the hardware description
const REG_RESOURCE_REQUIREMENTS_LIST = 10
const REG_QWORD                   = 11 # 64-bit number
const REG_QWORD_LITTLE_ENDIAN     = 11 # 64-bit number (same as REG_QWORD)


const KEY_ALL_ACCESS          = 0xF003F # Combines the STANDARD_RIGHTS_REQUIRED, KEY_QUERY_VALUE, KEY_SET_VALUE, KEY_CREATE_SUB_KEY, KEY_ENUMERATE_SUB_KEYS, KEY_NOTIFY, and KEY_CREATE_LINK access rights.
const KEY_CREATE_LINK         = 0x00020  # Reserved for system use.
const KEY_CREATE_SUB_KEY      = 0x00004  # Required to create a subkey of a registry key.
const KEY_ENUMERATE_SUB_KEYS  = 0x00008  # Required to enumerate the subkeys of a registry key.
const KEY_EXECUTE             = 0x20019  # Equivalent to KEY_READ.
const KEY_NOTIFY              = 0x00010  # Required to request change notifications for a registry key or for subkeys of a registry key.
const KEY_QUERY_VALUE         = 0x00001  # Required to query the values of a registry key.
const KEY_READ                = 0x20019  # Combines the STANDARD_RIGHTS_READ, KEY_QUERY_VALUE, KEY_ENUMERATE_SUB_KEYS, and KEY_NOTIFY values.
const KEY_SET_VALUE           = 0x00002  # Required to create, delete, or set a registry value.

const KEY_WOW64_32KEY         = 0x00200  # Indicates that an application on 64-bit Windows should operate on the 32-bit registry view. This flag is ignored by 32-bit Windows. For more information, see Accessing an Alternate Registry View.
# This flag must be combined using the OR operator with the other flags in this table that either query or access registry values.
# Windows 2000:  This flag is not supported.
const KEY_WOW64_64KEY         = 0x00100  # Indicates that an application on 64-bit Windows should operate on the 64-bit registry view. This flag is ignored by 32-bit Windows. For more information, see Accessing an Alternate Registry View.
# This flag must be combined using the OR operator with the other flags in this table that either query or access registry values.
# Windows 2000:  This flag is not supported.

const KEY_WRITE               = 0x20006  # Combines the STANDARD_RIGHTS_WRITE, KEY_SET_VALUE, and KEY_CREATE_SUB_KEY access rights.

function openkey(base::UInt32, path::AbstractString, accessmask::UInt32=KEY_READ)
    keyref = Ref{UInt32}()
    ret = ccall((:RegOpenKeyExW, "advapi32"),
                stdcall, Clong,
                (UInt32, Cwstring, UInt32, UInt32, Ref{UInt32}),
                base, path, 0, accessmask, keyref)
    if ret != 0
        error("Could not open registry key")
    end
    keyref[]
end

function querykey(key::UInt32, valuename::AbstractString)
    dwSize = Ref{UInt32}()
    dwDataType = Ref{UInt32}()

    ret = ccall((:RegQueryValueExW, "advapi32"),
                stdcall, Clong,
                (UInt32, Cwstring, Ptr{UInt32},
                 Ref{UInt32}, Ptr{UInt8}, Ref{UInt32}),
                key, valuename, C_NULL,
                dwDataType, C_NULL, dwSize)
    if ret != 0
        error("Could not find registry value name")
    end

    if VERSION < v"0.7.0-"
        data = Array{UInt8}(dwSize[])
    else
        data = Array{UInt8}(undef,dwSize[])
    end
    ret = ccall((:RegQueryValueExW, "advapi32"),
                stdcall, Clong,
                (UInt32, Cwstring, Ptr{UInt32},
                 Ptr{UInt32}, Ptr{UInt8}, Ref{UInt32}),
                key, valuename, C_NULL,
                C_NULL, data, dwSize)
    if ret != 0
        error("Could not retrieve registry data")
    end

    if dwDataType[] == REG_SZ || dwDataType[] == REG_EXPAND_SZ
        data_wstr = reinterpret(Cwchar_t,data)
        # string may or may not be null-terminated
        # need to copy, until https://github.com/JuliaLang/julia/pull/27810 is fixed
        if data_wstr[end] == 0
            data_wstr2 = data_wstr[1:end-1]
        else
            data_wstr2 = data_wstr[1:end]
        end        
        return transcode(String, data_wstr2)
    elseif dwDataType[] == REG_DWORD
        return reinterpret(Int32,data)[]
    elseif dwDataType[] == REG_QWORD
        return reinterpret(Int64,data)[]
    else
        return data
    end
end

function querykey(base::UInt32, path::AbstractString, valuename::AbstractString)
    key = openkey(base,path)
    val = querykey(key, valuename)
    closekey(key)
    val
end

function closekey(key::UInt32)
    ret = ccall((:RegCloseKey, "advapi32"),
                stdcall, Clong,
                (UInt32,),
                key)
    if ret != 0
        error("Could not close key")
    end
    nothing
end


end # module
