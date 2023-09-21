#NoEnv
#NoTrayIcon
AutoTrim Off
SetBatchLines, -1
ListLines, Off
#SingleInstance Off
Process, Priority,, B
#Persistent
#Include %A_ScriptDir%\Lib\RegisterSyncCallback.ahk
#Include %A_ScriptDir%\Lib\TermWait.ahk
#Include %A_ScriptDir%\Lib\Helpers.ahk
#Include %A_ScriptDir%\Lib\GetProcessCommandLine.ahk

if (!DllCall("shell32\SHGetKnownFolderPath", "Ptr", GUID(FOLDERID_RoamingAppData := "{3EB685DB-65F9-4CF6-A03A-E3EF65729F3D}"), "UInt", 0, "Ptr", 0, "Ptr*", RoamingAppData)) {
    WStrOut(RoamingAppData)
} else {
    ExitApp 1
}

dllPath := A_ScriptDir . "\block-tray-icon\x64\Release\block-tray-icon.dll"
,qbDir := "C:\Program Files\qBittorrent"
,qbExe := qbDir . "\qbittorrent.exe"
,qbCmd := """" . qbExe . """" . A_Space . """" . "--profile=" . RoamingAppData . "\qBtSonarr" . """" . A_Space . """" . "--configuration=" . """"

DetectHiddenWindows On
Sleep 1
WinGet, wins, List, QTrayIconMessageWindow ahk_exe qbittorrent.exe
Loop, %wins%
{
    this_id := wins%A_Index%
    WinGet, this_pid, PID, ahk_id %this_id%   
    if (this_pid && GetProcessCommandLine(this_pid) == qbCmd) {
        MYWM_NOTIFYICON := (WM_APP := 0x8000) + 101
        NIN_SELECT := (WM_USER := 0x0400) + 0
        Loop % WinExist("qBittorrent v ahk_pid " . this_pid) ? 1 : 3
            SendMessage, %MYWM_NOTIFYICON%, 0, % MAKELPARAM(NIN_SELECT, 0),, ahk_id %this_id%
        ExitApp
    }
}
DetectHiddenWindows Off

if (FileExist(dllPath)) {
    cbDllPath := VarSetCapacity(dllPath)
    if (DllCall("kernel32.dll\GetBinaryTypeW", "WStr", qbExe, "UInt*", BinaryType)) {
        if ((BinaryType == 6 && A_PtrSize == 8) || (BinaryType == 0 && A_PtrSize == 4)) {
            LoadDll := True
        }
    }
}

MSGID := 0x8500
qbPid := 0
lpTermWaitGlobal := 0

EnvSet, CLINK_NOAUTORUN, 1
VarSetCapacity(SYSTEM_INFO, 24 + A_PtrSize*3)
,DllCall("GetSystemInfo", "Ptr", &SYSTEM_INFO)
,coresNumber := NumGet(SYSTEM_INFO, 8 + A_PtrSize*3, "UInt")
,lastTwoCoresAffinity := (1 << (coresNumber - 2)) | (1 << (coresNumber - 1))
,OnMessage(MSGID, "AHK_TERMNOTIFY")
,OnExit("ExitFunc")
,StartQb()

ExitFunc()
{
    global lpTermWaitGlobal

    OnExit("ExitFunc", 0)
    ,OnMessage(MSGID, "")
    ,TermWait_StopWaiting(lpTermWaitGlobal)
}

AHK_TERMNOTIFY(wParam, lParam)
{
    global lpTermWaitGlobal, qbPid

    TermWait_StopWaiting(lParam)
    ,lpTermWaitGlobal := qbPid := 0

    if (wParam == 0)
        ExitApp

    SetTimer, StartQb, -5000
}

StartQb() {
    static BELOW_NORMAL_PRIORITY_CLASS := 0x00004000, INFINITE := 0xFFFFFFFF, SW_HIDE := 0, CREATE_SUSPENDED := 0x00000004, EXTENDED_STARTUPINFO_PRESENT := 0x00080000, MEM_COMMIT := 0x00001000, PAGE_READWRITE := 0x04, MEM_RELEASE := 0x8000
          ,LoadLibrary := DllCall("GetProcAddress", "Ptr", DllCall("GetModuleHandle", "Str", "kernel32.dll", "Ptr"), "AStr", A_IsUnicode ? "LoadLibraryW" : "LoadLibraryA", "Ptr")
    global lastTwoCoresAffinity, MSGID, lpTermWaitGlobal, cbStartupInfoEx, qbDir, qbExe, qbCmd, qbPid, dllPath, LoadDll, cbDllPath

    _PROCESS_INFORMATION(pi)
    ,_STARTUPINFOEX(si, SW_HIDE)
    ,dwCreationFlags := CREATE_SUSPENDED

    /*
    if ((parentPid := GetParentProcessID())) {
        if ((hParentProcess := DllCall("OpenProcess", "UInt", PROCESS_CREATE_PROCESS := 0x0080, "Int", False, "UInt", parentPid, "Ptr"))) {
            DllCall("InitializeProcThreadAttributeList", "Ptr", 0, "UInt", 1, "UInt", 0, "Ptr*", size)
            if (size) {
                VarSetCapacity(AttributeList, size + A_PtrSize)
                if (DllCall("InitializeProcThreadAttributeList", "Ptr", &AttributeList, "UInt", 1, "UInt", 0, "Ptr*", size)) {
                    NumPut(hParentProcess, AttributeList, size, "Ptr")
                    if (DllCall("UpdateProcThreadAttribute", "Ptr", &AttributeList, "UInt", 0, "UPtr", PROC_THREAD_ATTRIBUTE_PARENT_PROCESS := 0x00020000, "Ptr", &AttributeList+size, "Ptr", A_PtrSize, "Ptr", 0, "Ptr", 0)) {
                        NumPut(&AttributeList, si, cbStartupInfoEx - A_PtrSize, "Ptr")
                        ,dwCreationFlags |= EXTENDED_STARTUPINFO_PRESENT
                    }
                } else {
                    VarSetCapacity(AttributeList, 0)
                }
            }
        }
    }
    */

    if (DllCall("CreateProcessW", "WStr", qbExe, "WStr", qbCmd, "Ptr", 0, "Ptr", 0, "Int", False, "UInt", dwCreationFlags, "Ptr", 0, "WStr", qbDir, "Ptr", &si, "Ptr", &pi)) {
        hProcess := _PROCESS_INFORMATION_hProcess(pi)
        ,hThread := _PROCESS_INFORMATION_hThread(pi)
        ,qbPid := _PROCESS_INFORMATION_dwProcessId(pi)

        if (LoadDll) {           
            if ((pRemoteDllPath := DllCall("VirtualAllocEx", "Ptr", hProcess, "Ptr", 0, "Ptr", cbDllPath, "UInt", MEM_COMMIT, "UInt", PAGE_READWRITE, "Ptr"))) {
                if (DllCall("WriteProcessMemory", "Ptr", hProcess, "Ptr", pRemoteDllPath, "Ptr", &dllPath, "Ptr", cbDllPath, "Ptr", 0)) {
                    if (hRemoteThread := DllCall("CreateRemoteThread", "Ptr", hProcess, "Ptr", 0, "Ptr", 0, "Ptr", LoadLibrary, "Ptr", pRemoteDllPath, "UInt", 0, "Ptr", 0, "Ptr")) {
                        DllCall("WaitForSingleObject", "Ptr", hRemoteThread, "UInt", INFINITE)
                        ,CloseHandle(hRemoteThread)
                    }
                }
                DllCall("VirtualFreeEx", "Ptr", hProcess, "Ptr", pRemoteDllPath, "Ptr", 0, "UInt", MEM_RELEASE)
            }
        }

        lpTermWaitGlobal := TermWait_WaitForProcTerm(A_ScriptHwnd, MSGID, hProcess,, True, True)
        ,DllCall("SetProcessAffinityMask", "Ptr", hProcess, "UPtr", lastTwoCoresAffinity)
        ,DllCall("SetPriorityClass", "Ptr", hProcess, "UInt", BELOW_NORMAL_PRIORITY_CLASS)
        ,DllCall("ResumeThread", "Ptr", hThread)
        ,CloseHandle(hThread)
    } else {
        ExitApp 1
    }

    /*
    if (VarSetCapacity(AttributeList))
        DllCall("DeleteProcThreadAttributeList", "Ptr", &AttributeList)

    CloseHandle(hParentProcess)
    */
}
