//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 May 10  Brian Frank  Creation
//
package fan.testNative;

import fan.sys.*;

/**
 * NativeClass
 */
public class NativeClass
  extends FanObj
{

  public static NativeClass make()
  {
    NativeClass self = new NativeClass();
    make$(self);
    return self;
  }

  public static void make$(NativeClass self) {}

  public NativeClass() {}

  public Type typeof() { return Type.find("testNative::NativeClass"); }

  public long add(long a, long b) { return a + b; }
}