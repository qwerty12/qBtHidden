; https://github.com/giampaolo/psutil/blob/master/psutil/arch/windows/proc_info.c
GetProcessCommandLine(pid) {
    static PROCESS_QUERY_LIMITED_INFORMATION := 0x1000
           ,ProcessCommandLineInformation := 60
           ,STATUS_BUFFER_OVERFLOW := 0x80000005
           ,STATUS_BUFFER_TOO_SMALL := 0xC0000023
           ,STATUS_INFO_LENGTH_MISMATCH := 0xC0000004

    hProcess := 0

    try {
        hProcess := DllCall("OpenProcess", "UInt", PROCESS_QUERY_LIMITED_INFORMATION, "Int", False, "UInt", pid, "Ptr")
        if !hProcess
            throw "Failed to open process, error: " . A_LastError

        status := DllCall("ntdll.dll\NtQueryInformationProcess", "Ptr", hProcess, "UInt", ProcessCommandLineInformation, "Ptr", 0, "UInt", 0, "UInt*", BufferSize, "UInt")
        if (status != STATUS_BUFFER_OVERFLOW && status != STATUS_BUFFER_TOO_SMALL && status != STATUS_INFO_LENGTH_MISMATCH)
            throw "Failed to determine buffer size, error: " . status

        VarSetCapacity(CommandLineBuffer, BufferSize)
        if ((status := DllCall("ntdll.dll\NtQueryInformationProcess", "Ptr", hProcess, "UInt", ProcessCommandLineInformation, "Ptr", &CommandLineBuffer, "UInt", BufferSize, "Ptr", &BufferSize)) < 0)
            throw "Failed to query command line, error: " . status

        return StrGet(NumGet(CommandLineBuffer, A_PtrSize, "Ptr"), NumGet(CommandLineBuffer,, "UShort"), "UTF-16")
    } finally {
        if (hProcess)
            DllCall("CloseHandle", "Ptr", hProcess)
    }
}