//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Dec 06  Andy Frank  Creation
//

#include <stdio.h>
#include <mscoree.h>
#include <Windows.h>
#include "launcher.h"
#include "utils.h"

#define KEY_LEN 256
typedef HRESULT (*_CorBindToRuntimeEx)(LPCWSTR,LPCWSTR,DWORD,REFCLSID,REFIID,LPVOID FAR *);
ICLRRuntimeHost *pClrHost;

//////////////////////////////////////////////////////////////////////////
// Init CLR
//////////////////////////////////////////////////////////////////////////

/**
 * Check for .NET framework version 2.0 using registery.
 */
int checkDotnetFwVer()
{
  if (debug) printf("-- findDotnetVer\n");

  // query registry to get installed .NET Framework versions
  const char* key= "SOFTWARE\\Microsoft\\.NETFramework\\policy";
  HKEY hKey;
  if (RegOpenKeyEx(HKEY_LOCAL_MACHINE, key, 0, KEY_READ, &hKey) != ERROR_SUCCESS)
    //return err("Cannot read registry: %s", key);
    return err(".NET Framework v2.0 not found");

  // list all installed versions of fw
  if (debug) printf("--   registry keys:\n");

  DWORD dwIndex = 0;
  DWORD cbName = KEY_LEN;
  char val[KEY_LEN];
  int fwFound = -1;

  while ((ERROR_NO_MORE_ITEMS !=
    RegEnumKeyEx(hKey, dwIndex, val, &cbName, NULL, NULL, NULL, NULL)))
  {
    if (debug) printf("--     %s\n", val);
    if (strcmp(val, "v2.0") == 0) fwFound = ERROR_SUCCESS;
    if (strcmp(val, "V2.0") == 0) fwFound = ERROR_SUCCESS;
    dwIndex++;
    cbName = KEY_LEN;
  }

  // close
  RegCloseKey(hKey);

  // return result
  if (fwFound != ERROR_SUCCESS)
    return err(".NET Framework v2.0 not found");

  return 0;
}

//////////////////////////////////////////////////////////////////////////
// Load the CLR
//////////////////////////////////////////////////////////////////////////

int loadClr()
{
  if (debug) printf("-- loadClr\n");

  // dynamically load mscoree.dll
  if (debug) printf("--   load mscoree.dll\n");
  HINSTANCE dll = LoadLibrary("mscoree.dll");
  if (dll == NULL)
    return err("Cannot load library: mscoree.dll");

  // query for CorBindToRuntimeEx
  _CorBindToRuntimeEx corBindToRuntimeEx =
    (_CorBindToRuntimeEx)GetProcAddress(dll, "CorBindToRuntimeEx");
  if (corBindToRuntimeEx == NULL)
    return err("Cannot find CorBindToRuntimeEx in mscoree.dll");

  // load CLR
  HRESULT hr = corBindToRuntimeEx(
    NULL,                  // desired CLR version (NULL = latest)
    NULL,                  // desired GC flavor (NULL = workstation)
    0,                     // desired startup flags
    CLSID_CLRRuntimeHost,  // CLSID of CLR
    IID_ICLRRuntimeHost,   // IID of ICLRRuntimeHost
    (PVOID*)&pClrHost);    // return COM interface

  if (!SUCCEEDED(pClrHost))
    return err("Cannot load CLR Host");

  return 0;
}

//////////////////////////////////////////////////////////////////////////
// Run the main method
//////////////////////////////////////////////////////////////////////////

int runDotnetMain()
{
  // initialize and start the CLR
  pClrHost->Start();

  // get sys path
  char sysPath[MAX_PATH];
  strcpy(sysPath, fanHome);
  strcat(sysPath, "\\lib\\dotnet\\sys.dll");
  ULONG sz = strlen(sysPath) + 1;
  LPWSTR wSysPath = new WCHAR[sz];
  MultiByteToWideChar(CP_ACP, 0, sysPath, sz, wSysPath, sz);
  if (debug)
  {
    printf("--   sysPath  = %s\n", sysPath);
    printf("--   wSysPath = %S\n", wSysPath);
  }

  // figure out main
  char mainClassName[256];
  sprintf(mainClassName, "Fanx.Tools.%s", FAN_TOOL);
  sz = strlen(mainClassName) + 1;
  LPWSTR wMainClassName = new WCHAR[sz];
  MultiByteToWideChar(CP_ACP, 0, mainClassName, sz, wMainClassName, sz);
  if (debug)
  {
    printf("--   mainClassName  = %s\n", mainClassName);
    printf("--   wMainClassName = %S\n", wMainClassName);
  }

  // since we only have a single str to work with
  // stuff everything into our reserved str, delimited
  // with newlines

  char reserved[1024];
  reserved[0] = '\0'; // need this or we get garbage at beginning of str
  strcat(reserved, fanHome);
  strcat(reserved, "\n");
  for (int i=0; i<fanArgc; i++)
  {
    if (i > 0) strcat(reserved, "\n");
    strcat(reserved, fanArgv[i]);
  }
  sz = strlen(reserved) + 1;
  LPWSTR wReserved = new WCHAR[sz];
  MultiByteToWideChar(CP_ACP, 0, reserved, sz, wReserved, sz);
  if (debug) printf("--   wReserved = %S\n", wReserved);

  DWORD retVal = 0;
  HRESULT hr = pClrHost->ExecuteInDefaultAppDomain(
      wSysPath, wMainClassName, L"run", wReserved, &retVal);

  if (debug)
  {
    printf("--   Managed code returned %d\n", retVal);
    printf("--   HRESULT = %d\n", hr);
  }

  if (!SUCCEEDED(hr))
    return err("Could not run %s\n", mainClassName);

  return 0;
}

//////////////////////////////////////////////////////////////////////////
// .NET Main
//////////////////////////////////////////////////////////////////////////

int runDotnet()
{
  if (checkDotnetFwVer()) return -1;
  if (loadClr())          return -1;
  if (runDotnetMain())    return -1;
  return 0;
}