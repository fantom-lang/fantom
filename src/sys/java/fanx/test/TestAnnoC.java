//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Sep 10  Brian Frank  Creation
//
package fanx.test;

import java.lang.annotation.*;

@Retention(RetentionPolicy.RUNTIME)
public @interface TestAnnoC
{
  boolean bool()   default false;
  int i()          default 0;
  long l()         default 0L;
  float f()        default 0f;
  double d()       default 0d;
  byte b()         default 0;
  short s()        default 0;
  Thread.State e() default Thread.State.NEW;
  String str()     default "";
}