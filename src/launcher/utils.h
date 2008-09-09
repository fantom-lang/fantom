//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Dec 06  Brian Frank  Creation
//

#ifndef _UTILS_H
#define _UTILS_H

extern int err(const char* msg, const char* arg1, const char* arg2);
extern int err(const char* msg, const char* arg1);
extern int err(const char* msg);

extern int readRegistry(const char* subKey, char* name, char* buf, int bufLen);

#endif