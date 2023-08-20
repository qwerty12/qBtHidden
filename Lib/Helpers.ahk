_PROCESS_INFORMATION(ByRef pi) {
    static piCb := A_PtrSize == 8 ? 24 : 16
    if (IsByRef(pi))
        VarSetCapacity(pi, piCb, 0)
}

_PROCESS_INFORMATION_hProcess(ByRef pi) {
    return NumGet(pi,, "Ptr")
}

_PROCESS_INFORMATION_hThread(ByRef pi) {
    return NumGet(pi, A_PtrSize, "Ptr")
}

_PROCESS_INFORMATION_dwProcessId(ByRef pi) {
    return NumGet(pi, A_PtrSize * 2, "UInt")
}

cbStartupInfoEx := A_PtrSize == 8 ? 112 : 72
_STARTUPINFOEX(ByRef si, ShowWindow := -1) {
    global cbStartupInfoEx
    if (IsByRef(si)) {
        VarSetCapacity(si, cbStartupInfoEx, 0), NumPut(cbStartupInfoEx, si,, "UInt")
		,dwFlags := 0
		if (ShowWindow != -1) {
			dwFlags |= 0x00000001 ; STARTF_USESHOWWINDOW
			,NumPut(ShowWindow, si, A_PtrSize == 8 ? 64 : 48, "UShort") ; wShowWindow
		}
		dwFlags |= STARTF_FORCEOFFFEEDBACK := 0x00000080
		,NumPut(dwFlags, si, A_PtrSize == 8 ? 60 : 44, "UInt")
    }
}

CloseHandle(hObject) {
    static INVALID_HANDLE_VALUE := -1
    return (hObject && hObject != INVALID_HANDLE_VALUE) ? DllCall("kernel32.dll\CloseHandle", "Ptr", hObject) : False
}

GetCurrentProcess() {
    static hProc := DllCall("GetCurrentProcess", "Ptr") ; always -1
    return hProc
}

GetParentProcessID() {
    ; Undocumented but far easier than CreateToolhelp32Snapshot
    VarSetCapacity(PROCESS_BASIC_INFORMATION, pbiSz := A_PtrSize == 8 ? 48 : 24)
    if (DllCall("ntdll.dll\NtQueryInformationProcess", "Ptr", GetCurrentProcess(), "UInt", 0, "Ptr", &PROCESS_BASIC_INFORMATION, "UInt", pbiSz, "Ptr", 0) >= 0)
        return NumGet(PROCESS_BASIC_INFORMATION, pbiSz - A_PtrSize, "UInt")
    return 0
}

; From Lexikos' VA.ahk
WStrOut(ByRef str) {
	str := StrGet(ptr := str, "UTF-16")
	,DllCall("ole32\CoTaskMemFree", "ptr", ptr)
	return str
}

; From Lexikos' VA.ahk: Convert string to binary GUID structure.
GUID(ByRef guid_out, guid_in="%guid_out%") {
    if (guid_in == "%guid_out%")
        guid_in :=   guid_out
    if  guid_in is integer
        return guid_in
    VarSetCapacity(guid_out, 16, 0)
	,DllCall("ole32\CLSIDFromString", "wstr", guid_in, "ptr", &guid_out)
	return &guid_out
}

; jeeswg: https://www.autohotkey.com/boards/viewtopic.php?t=68367
MAKELPARAM(l, h)
{
	;note: equivalent to MAKELRESULT
	ret := (l & 0xffff) | (h & 0xffff) << 16

	;UInt to Int if necessary on 32-bit AHK:
	if (A_PtrSize == 4) && (ret >= 0x80000000)
		return ret - 0x80000000
	return ret
}