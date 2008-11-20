//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Sep 08  Brian Frank  Creation
//
package fanx.test;

import fanx.util.*;

/**
 * InteropTest
 */
public class InteropTest
{

  long num = 1000;

  public byte   numb() { return (byte)num; }
  public short  nums() { return (short)num; }
  public int    numi() { return (int)num; }
  public long   numl() { return num; }
  public double numd() { return num; }
  public float  numf() { return num; }

  public void numb(byte x)   { num = x; }
  public void nums(short x)  { num = x; }
  public void numi(int x)    { num = x; }
  public void numl(long x)   { num = x; }
  public void numd(double x) { num = (long)x; }
  public void numf(float x)  { num = (long)x; }

  public void numadd(byte b, short s, int i, float f)  { num = b + s + i + (int)f; }


}