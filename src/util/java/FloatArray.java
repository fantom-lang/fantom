//
// Copyright (c) 2012, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Feb 12  Brian Frank  Creation
//
package fan.util;

import fan.sys.*;
import java.util.Arrays;

public abstract class FloatArray extends FanObj
{

  public static FloatArray makeF4(long size) { return new F4((int)size); }
  public static FloatArray makeF8(long size) { return new F8((int)size); }

  public final Type typeof() { return typeof; }
  private static final Type typeof = Type.find("util::FloatArray");

  public abstract String kind();
  public abstract Object array();

  public abstract long size();
  public abstract double get(long i);
  public abstract void set(long i, double v);

  public FloatArray copyFrom(FloatArray that) { return copyFrom(that, null, 0); }
  public FloatArray copyFrom(FloatArray that, Range thatRange) { return copyFrom(that, thatRange, 0); }
  public FloatArray copyFrom(FloatArray that, Range thatRange, long thisOffset)
  {
    if (kind() != that.kind()) throw ArgErr.make("Mismatched arrays: " + kind() + " != " + that.kind());
    int start, end;
    int thatSize = (int)that.size();
    if (thatRange == null) { start = 0; end = thatSize-1; }
    else  { start = thatRange.startIndex(thatSize); end  = thatRange.endIndex(thatSize); }
    System.arraycopy(that.array(), start, this.array(), (int)thisOffset, end-start+1);
    return this;
  }

  public FloatArray fill(double val) { return fill(val, null); }
  public FloatArray fill(double val, Range range)
  {
    int start, end;
    int size = (int)size();
    if (range == null) { start = 0; end = size-1; }
    else  { start = range.startIndex(size); end = range.endIndex(size); }
    for (int i=start; i<=end; ++i) set(i, val);
    return this;
  }

  public FloatArray sort() { return sort(null); }
  public FloatArray sort(Range range)
  {
    int start, end;
    int size = (int)size();
    if (range == null) { start = 0; end = size-1; }
    else { start = range.startIndex(size); end = range.endIndex(size); }
    doSort(start, end+1);
    return this;
  }
  abstract void doSort(int from, int to);

  static class F4 extends FloatArray
  {
    F4(int size) { array = new float[size]; }
    public String kind() { return "F4"; }
    public final long size() { return array.length; }
    public double get(long i) { return array[(int)i]; }
    public final void set(long i, double v) { array[(int)i] = (float)v; }
    public final Object array() { return array; }
    final void doSort(int from, int to) { Arrays.sort(array, from, to); }
    final float[] array;
  }

  static class F8 extends FloatArray
  {
    F8(int size) { array = new double[size]; }
    public final String kind() { return "F8"; }
    public final long size() { return array.length; }
    public final double get(long i) { return array[(int)i]; }
    public final void set(long i, double v) { array[(int)i] = v; }
    public final Object array() { return array; }
    final void doSort(int from, int to) { Arrays.sort(array, from, to); }
    private final double[] array;
  }

}