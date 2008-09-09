//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Dec 06  Brian Frank  Creation
//

#ifndef _PROPS_H
#define _PROPS_H

#include <stdio.h>

typedef struct Prop
{
  const char* name;
  const char* val;
  struct Prop* next;
} Prop;

extern Prop* readProps(const char* filename);

extern const char* getProp(Prop* props, const char* name);
extern const char* getProp(Prop* props, const char* name, const char* def);

extern Prop* setProp(Prop* props, const char* name, const char* value);

#endif