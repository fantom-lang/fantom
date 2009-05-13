//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 May 09  Andy Frank  Creation
//

with (sys_Pod.$add("webappClient"))
{
  $addType("Doc",     "sys::Obj");
  $addType("Effect",  "sys::Obj");
  $addType("Elem",    "sys::Obj");
  $addType("Event",   "sys::Obj");
  $addType("HttpReq", "sys::Obj");
  $addType("HttpRes", "sys::Obj");
  $addType("Window",  "sys::Obj");
};
