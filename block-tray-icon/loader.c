#include "stdafx.h"

static INT(*ChromeStart)(VOID) = NULL;
static BOOL(STDAPICALLTYPE* Shell_NotifyIconW_Orig)(DWORD, PNOTIFYICONDATAW) = Shell_NotifyIconW;

BOOL STDAPICALLTYPE Shell_NotifyIconW_Hook(DWORD dwMessage, _In_ PNOTIFYICONDATAW lpData)
{
	return FALSE;
}

INT DetouredStart()
{
	DetourTransactionBegin();
	DetourUpdateThread(GetCurrentThread());
	DetourAttach((PVOID*)&Shell_NotifyIconW_Orig, (PVOID)Shell_NotifyIconW_Hook);
	DetourTransactionCommit();
	
	return ChromeStart();
}

VOID loader_init()
{
	if ((ChromeStart = DetourGetEntryPoint(NULL))) {
		DetourTransactionBegin();
		DetourUpdateThread(GetCurrentThread());
		DetourAttach((PVOID*)&ChromeStart, (PVOID)DetouredStart);
		DetourTransactionCommit();
	}
}