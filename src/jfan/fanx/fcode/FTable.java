//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Dec 05  Brian Frank  Creation
//
package fanx.fcode;

import java.io.*;
import java.util.*;
import fanx.util.*;
import fan.sys.*;
import fan.sys.Float;

/**
 * FTable is a 16-bit indexed lookup table for pod constants.
 */
public abstract class FTable
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  protected FTable(FPod pod)
  {
    this.pod = pod;
  }

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  /**
   * Get the size of the table.
   */
  public final int size() { return size; }

  /**
   * Get the object identified by the specified 16-bit index.
   */
  public final Object get(int index)
  {
    return table[index];
  }

  /**
   * Dump to the specified print writer.
   */
  public void dump(FPod pod, PrintWriter out)
  {
    for (int i=0; i<size; ++i)
    {
      out.print(StrUtil.padr("  [" + i + "] ", 8));
      out.println(toString(i));
    }
    out.flush();
  }

  /**
   * Get the value at specified index formated as a String.
   */
  public String toString(int index)
  {
    return table[index].toString();
  }

  /**
   * Serialize.
   */
  public abstract FTable read(FStore.Input in)
    throws IOException;

//////////////////////////////////////////////////////////////////////////
// Names
//////////////////////////////////////////////////////////////////////////

  static class Names extends FTable
  {
    Names(FPod pod) { super(pod); }

    public FTable read(FStore.Input in) throws IOException
    {
      if (in == null) { size = 0; return this; }
      size = in.u2();
      table = new Object[size];
      for (int i=0; i<size; ++i)
        table[i] = in.utf().intern();
      return this;
    }
  }

//////////////////////////////////////////////////////////////////////////
// TypeRefs
//////////////////////////////////////////////////////////////////////////

  static class TypeRefs extends FTable
  {
    TypeRefs(FPod pod) { super(pod); }

    public String toString(int index)
    {
      if (index == -1) return "null";
      return ((FTypeRef)table[index]).sig(pod);
    }

    public FTable read(FStore.Input in) throws IOException
    {
      if (in == null) { size = 0; return this; }
      size = in.u2();
      table = new Object[size];
      for (int i=0; i<size; ++i)
        table[i] = FTypeRef.read(in);
      return this;
    }
  }

//////////////////////////////////////////////////////////////////////////
// FieldRefs
//////////////////////////////////////////////////////////////////////////

  static class FieldRefs extends FTable
  {
    FieldRefs(FPod pod) { super(pod); }

    public String toString(int index)
    {
      int[] val = ((FTuple)table[index]).val;
      return pod.typeRefs.toString(val[0]) + "." + pod.name(val[1]) +
        " -> " + pod.typeRefs.toString(val[2]);
    }

    public FTable read(FStore.Input in) throws IOException
    {
      if (in == null) { size = 0; return this; }
      size = in.u2();
      table = new Object[size];
      for (int i=0; i<size; ++i)
      {
        int[] x = { in.u2(), in.u2(), in.u2() };
        table[i] = new FTuple(x);
      }
      return this;
    }
  }

//////////////////////////////////////////////////////////////////////////
// MethodRefs
//////////////////////////////////////////////////////////////////////////

  static class MethodRefs extends FTable
  {
    MethodRefs(FPod pod) { super(pod); }

    public String toString(int index)
    {
      int[] val = ((FTuple)table[index]).val;
      StringBuilder s = new StringBuilder();
      s.append(pod.typeRefs.toString(val[0])).append(".").append(pod.name(val[1]));
      s.append('(');
      for (int i=3; i<val.length; ++i)
      {
        if (i > 3) s.append(", ");
        s.append(pod.typeRefs.toString(val[i]));
      }
      s.append(") -> ").append(pod.typeRefs.toString(val[2]));
      return s.toString();
    }

    public FTable read(FStore.Input in) throws IOException
    {
      if (in == null) { size = 0; return this; }
      size = in.u2();
      table = new Object[size];
      for (int i=0; i<size; ++i)
      {
        int parent = in.u2();
        int name   = in.u2();
        int ret    = in.u2();
        int paramn = in.u1();
        int[] x = new int[3+paramn];
        x[0] = parent;
        x[1] = name;
        x[2] = ret;
        for (int j=0; j<paramn; ++j)
          x[j+3] = in.u2();
        table[i] = new FTuple(x);
      }
      return this;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Ints
//////////////////////////////////////////////////////////////////////////

  static class Ints extends FTable
  {
    Ints(FPod pod) { super(pod); }

    public FTable read(FStore.Input in) throws IOException
    {
       if (in == null) { size = 0; return this; }
       size = in.u2();
       table = new Object[size];
       for (int i=0; i<size; ++i)
         table[i] = Int.make( in.u8() );
       return this;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Floats
//////////////////////////////////////////////////////////////////////////

  static class Floats extends FTable
  {
    Floats(FPod pod) { super(pod); }

    public FTable read(FStore.Input in) throws IOException
    {
       if (in == null) { size = 0; return this; }
       size = in.u2();
       table = new Object[size];
       for (int i=0; i<size; ++i)
         table[i] = Float.make( in.f8() );
       return this;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Decimals
//////////////////////////////////////////////////////////////////////////

  static class Decimals extends FTable
  {
    Decimals(FPod pod) { super(pod); }

    public FTable read(FStore.Input in) throws IOException
    {
       if (in == null) { size = 0; return this; }
       size = in.u2();
       table = new Object[size];
       for (int i=0; i<size; ++i)
         table[i] = Decimal.fromStr(in.readUTF(), true);
       return this;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Strs
//////////////////////////////////////////////////////////////////////////

  static class Strs extends FTable
  {
    Strs(FPod pod) { super(pod); }

    public FTable read(FStore.Input in) throws IOException
    {
       if (in == null) { size = 0; return this; }
       size = in.u2();
       table = new Object[size];
       for (int i=0; i<size; ++i)
         table[i] = Str.make(in.utf()).intern();
       return this;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Durations
//////////////////////////////////////////////////////////////////////////

  static class Durations extends FTable
  {
    Durations(FPod pod) { super(pod); }

    public FTable read(FStore.Input in) throws IOException
    {
       if (in == null) { size = 0; return this; }
       size = in.u2();
       table = new Object[size];
       for (int i=0; i<size; ++i)
         table[i] = Duration.make( in.u8() );
       return this;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Uris
//////////////////////////////////////////////////////////////////////////

  static class Uris extends FTable
  {
    Uris(FPod pod) { super(pod); }

    public FTable read(FStore.Input in) throws IOException
    {
       if (in == null) { size = 0; return this; }
       size = in.u2();
       table = new Object[size];
       for (int i=0; i<size; ++i)
         table[i] = Uri.fromStr(in.utf());
       return this;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  FPod pod;
  int size;
  Object[] table;
  int tupleFormat;

}