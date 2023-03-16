local build = require("build/build.t")
local async = require("async")
local m = {}

assert(
  build.target_name() == "Windows", 
  "Winapi can only be used on windows!"
)

local C = build.includecstring([[
#include <stdint.h>

typedef uint32_t UINT,*PUINT,*LPUINT;

typedef char CHAR;
typedef uint8_t BYTE;
typedef uint16_t WORD;
typedef uint32_t DWORD;
typedef uint64_t QWORD;

typedef uint8_t * PBYTE;
typedef uint16_t * PWORD;
typedef uint32_t * PDWORD;
typedef uint64_t * PQWORD;

typedef uint32_t * LPDWORD;

typedef int32_t LONG;
typedef uint32_t ULONG;

typedef uint32_t * ULONG_PTR;

typedef int BOOL;

typedef CHAR *LPSTR;

typedef void* HANDLE;
typedef HANDLE HINSTANCE;
typedef HANDLE HMODULE;

typedef struct tagMOUSEINPUT {
  LONG      dx;
  LONG      dy;
  DWORD     mouseData;
  DWORD     dwFlags;
  DWORD     time;
  ULONG_PTR dwExtraInfo;
} MOUSEINPUT, *PMOUSEINPUT, *LPMOUSEINPUT;

typedef struct tagKEYBDINPUT {
  WORD      wVk;
  WORD      wScan;
  DWORD     dwFlags;
  DWORD     time;
  ULONG_PTR dwExtraInfo;
} KEYBDINPUT, *PKEYBDINPUT, *LPKEYBDINPUT;

typedef struct tagHARDWAREINPUT {
  DWORD uMsg;
  WORD  wParamL;
  WORD  wParamH;
} HARDWAREINPUT, *PHARDWAREINPUT, *LPHARDWAREINPUT;

typedef struct tagINPUT {
  DWORD type;
  union {
    MOUSEINPUT    mi;
    KEYBDINPUT    ki;
    HARDWAREINPUT hi;
  } DUMMYUNIONNAME;
} INPUT, *PINPUT, *LPINPUT;

typedef int HKL;

UINT SendInput(UINT cInputs, LPINPUT pInputs, int cbSize);
void keybd_event(BYTE bVk, BYTE bScan, DWORD dwFlags, ULONG_PTR dwExtraInfo);
void mouse_event(DWORD dwFlags, DWORD dx, DWORD dy, DWORD dwData, ULONG_PTR dwExtraInfo);
UINT MapVirtualKeyExW(UINT uCode, UINT uMapType, HKL  dwhkl);
UINT MapVirtualKeyA(UINT uCode, UINT uMapType);
BOOL SetCursorPos(int X, int Y);

BOOL IsDebuggerPresent();

#define PROCESS_QUERY_INFORMATION 0x0400
#define PROCESS_VM_READ 0x0010

BOOL EnumProcesses(DWORD *lpidProcess, DWORD cb, LPDWORD lpcbNeeded);
HANDLE OpenProcess(DWORD dwDesiredAccess, BOOL bInheritHandle, DWORD dwProcessId);
BOOL CloseHandle(HANDLE hObject);
BOOL EnumProcessModulesEx(HANDLE hProcess, HMODULE *lphModule, DWORD cb, LPDWORD lpcbNeeded, DWORD dwFilterFlag);
BOOL EnumProcessModules(HANDLE hProcess, HMODULE *lphModule, DWORD cb, LPDWORD lpcbNeeded);
DWORD GetModuleBaseNameA(HANDLE hProcess, HMODULE hModule, LPSTR lpBaseName, DWORD nSize);
BOOL QueryFullProcessImageNameA(HANDLE hProcess, DWORD dwFlags, LPSTR lpExeName, PDWORD lpdwSize);

BOOL SetConsoleOutputCP(UINT wCodePageID);

BOOL QueryPerformanceFrequency(int64_t* lpFrequency);
BOOL QueryPerformanceCounter(int64_t* lpPerformanceCount);
]])
m.C = C

return m