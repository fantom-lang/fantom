//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Dec 06  Brian Frank  Creation
//

#ifndef _LAUNCHER_H
#define _LAUNCHER_H

#include <stdio.h>
#include <Windows.h>
#include "props.h"

extern bool debug;               // is debug turned on
extern char fanHome[MAX_PATH];   // dir path of fan installation
extern Prop* sysProps;           // {fanHome}/etc/sys/config.props
extern int fanArgc;              // argument count to pass to Fan runtime
extern char** fanArgv;           // argument values to pass to Fan runtime

#endif