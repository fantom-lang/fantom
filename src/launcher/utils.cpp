//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Dec 06  Brian Frank  Creation
//

#include <stdio.h>
#include <Windows.h>
#include "utils.h"

//////////////////////////////////////////////////////////////////////////
// Error Utils
//////////////////////////////////////////////////////////////////////////

/**
 * Print an error message and return -1.
 */
int err(const char* msg, const char* arg1, const char* arg2)
{
  printf("ERROR: ");
  printf(msg, arg1, arg2);
  printf("\n");
  return -1;
}
int err(const char* msg, const char* arg1) { return err(msg, arg1, "ignored"); }
int err(const char* msg) { return err(msg, "ignored", "ignored"); }

//////////////////////////////////////////////////////////////////////////
// Registry Utils
//////////////////////////////////////////////////////////////////////////

/**
 * Read a registry string from HKEY_LOCAL_MACHINE.
 */
int readRegistry(const char* subKey, char* name, char* buf, int bufLen)
{
  // open key
  HKEY hKey;
  if (RegOpenKeyEx(HKEY_LOCAL_MACHINE, subKey, 0, KEY_QUERY_VALUE, &hKey) != ERROR_SUCCESS)
    return err("Cannot read registry: %s %s", subKey, name);

  // query
  int query = RegQueryValueEx(hKey, name, NULL, NULL, (LPBYTE)buf, (LPDWORD)&bufLen);

  // close
  RegCloseKey(hKey);

  // return result
  if (query != ERROR_SUCCESS)
    return err("Cannot read registry: %s %s", subKey, name);

  return 0;
}