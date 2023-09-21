#include "stdafx.h"

BOOL APIENTRY _DllMainCRTStartup( HMODULE hModule,
                       DWORD  dwReasonForCall,
                       LPVOID lpReserved
					 )
{
	UNREFERENCED_PARAMETER(lpReserved);

	switch (dwReasonForCall)
	{
	case DLL_PROCESS_ATTACH:
		__security_init_cookie();
		DisableThreadLibraryCalls(hModule);
		GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_PIN | GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS, (LPCWSTR)hModule, &g_hInstance);
		loader_init();
		break;
	}
	return TRUE;
}

