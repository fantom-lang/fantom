//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Sep 06  Andy Frank  Creation
//

using System;
using System.IO;
using System.Text;
using Fan.Sys;
using Uri = Fan.Sys.Uri;
using Fanx.Util;

namespace Fanx.Fcode
{
  ///
  /// FTable is a 16-bit indexed lookup table for pod constants.
  ///
  public abstract class FTable
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    protected FTable(FPod pod)
    {
      this.m_pod = pod;
    }

  //////////////////////////////////////////////////////////////////////////
  // Access
  //////////////////////////////////////////////////////////////////////////

    ///
    /// Get the size of the table.
    ///
    public int size() { return m_size; }

    ///
    /// Get the object identified by the specified 16-bit index.
    ///
    public object get(int index)
    {
      return m_table[index];
    }

    ///
    /// Dump to the specified print writer.
    ///
    public void dump(FPod pod, TextWriter writer)
    {
      for (int i=0; i<m_size; i++)
      {
         writer.Write(StrUtil.padr("  [" + i + "] ", 8));
         writer.WriteLine(toString(i));
      }
      writer.Flush();
    }

    ///
    /// Get the value at specified index formated as a string.
    ///
    public virtual string toString(int index)
    {
      return m_table[index].ToString();
    }

    ///
    /// Serialize.
    ///
    public abstract FTable read(FStore.Input input);

  //////////////////////////////////////////////////////////////////////////
  // Names
  //////////////////////////////////////////////////////////////////////////

    internal class Names : FTable
    {
      internal Names(FPod pod) : base(pod) {}

      public override FTable read(FStore.Input input)
      {
        if (input == null) { m_size = 0; return this; }
        m_size = input.u2();
        m_table = new object[m_size];
        for (int i=0; i<m_size; i++)
          m_table[i] = String.Intern(input.utf());
        return this;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // TypeRefs
  //////////////////////////////////////////////////////////////////////////

    internal class TypeRefs : FTable
    {
      internal TypeRefs(FPod pod) : base(pod) {}

      public override string toString(int index)
      {
        if (index == -1) return "null";
        return ((FTypeRef)m_table[index]).signature;
      }

      public override FTable read(FStore.Input input)
      {
        if (input == null) { m_size = 0; return this; }
        m_size = input.u2();
        m_table = new object[m_size];
        for (int i=0; i<m_size; i++)
          m_table[i] = FTypeRef.read(input);
        return this;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // FieldRefs
  //////////////////////////////////////////////////////////////////////////

    internal class FieldRefs : FTable
    {
      internal FieldRefs(FPod pod) : base(pod) {}

      public override string toString(int index)
      {
        int[] val = ((FTuple)m_table[index]).val;
        return m_pod.m_typeRefs.toString(val[0]) + "." + m_pod.name(val[1]) +
          " -> " + m_pod.m_typeRefs.toString(val[2]);
      }

      public override FTable read(FStore.Input input)
      {
        if (input == null) { m_size = 0; return this; }
        m_size = input.u2();
        m_table = new object[m_size];
        for (int i=0; i<m_size; i++)
        {
          int[] x = { input.u2(), input.u2(), input.u2() };
          m_table[i] = new FTuple(x);
        }
        return this;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // MethodRefs
  //////////////////////////////////////////////////////////////////////////

    internal  class MethodRefs : FTable
    {
      internal MethodRefs(FPod pod) : base(pod) {}

      public override string toString(int index)
      {
        int[] val = ((FTuple)m_table[index]).val;
        StringBuilder s = new StringBuilder();
        s.Append(m_pod.m_typeRefs.toString(val[0])).Append(".").Append(m_pod.name(val[1]));
        s.Append('(');
        for (int i=3; i<val.Length; i++)
        {
          if (i > 3) s.Append(", ");
          s.Append(m_pod.m_typeRefs.toString(val[i]));
        }
        s.Append(") -> ").Append(m_pod.m_typeRefs.toString(val[2]));
        return s.ToString();
      }

      public override FTable read(FStore.Input input)
      {
        if (input == null) { m_size = 0; return this; }
        m_size = input.u2();
        m_table = new object[m_size];
        for (int i=0; i<m_size; i++)
        {
          int parent = input.u2();
          int name   = input.u2();
          int ret    = input.u2();
          int paramn = input.u1();
          int[] x = new int[3+paramn];
          x[0] = parent;
          x[1] = name;
          x[2] = ret;
          for (int j=0; j<paramn; ++j)
            x[j+3] = input.u2();
          m_table[i] = new FTuple(x);
        }
        return this;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Ints
  //////////////////////////////////////////////////////////////////////////

    internal class Ints : FTable
    {
      internal Ints(FPod pod) : base(pod) {}

      public override FTable read(FStore.Input input)
      {
         if (input == null) { m_size = 0; return this; }
         m_size = input.u2();
         m_table = new object[m_size];
         for (int i=0; i<m_size; i++)
           m_table[i] = input.u8();
         return this;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Floats
  //////////////////////////////////////////////////////////////////////////

    internal class Floats : FTable
    {
      internal Floats(FPod pod) : base(pod) {}

      public override FTable read(FStore.Input input)
      {
         if (input == null) { m_size = 0; return this; }
         m_size = input.u2();
         m_table = new object[m_size];
         for (int i=0; i<m_size; i++)
           m_table[i] = input.f8();
         return this;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Decimals
  //////////////////////////////////////////////////////////////////////////

    internal class Decimals : FTable
    {
      internal Decimals(FPod pod) : base(pod) {}

      public override FTable read(FStore.Input input)
      {
         if (input == null) { m_size = 0; return this; }
         m_size = input.u2();
         m_table = new object[m_size];
         for (int i=0; i<m_size; i++)
           m_table[i] = FanDecimal.fromStr(input.utf(), true);
         return this;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Strs
  //////////////////////////////////////////////////////////////////////////

    internal class Strs : FTable
    {
      internal Strs(FPod pod) : base(pod) {}

      public override FTable read(FStore.Input input)
      {
         if (input == null) { m_size = 0; return this; }
         m_size = input.u2();
         m_table = new object[m_size];
         for (int i=0; i<m_size; i++)
           m_table[i] = String.Intern(input.utf());
         return this;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Durations
  //////////////////////////////////////////////////////////////////////////

    internal class Durations : FTable
    {
      internal Durations(FPod pod) : base(pod) {}

      public override FTable read(FStore.Input input)
      {
         if (input == null) { m_size = 0; return this; }
         m_size = input.u2();
         m_table = new object[m_size];
         for (int i=0; i<m_size; i++)
           m_table[i] = Duration.make(input.u8());
         return this;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Uris
  //////////////////////////////////////////////////////////////////////////

    internal class Uris : FTable
    {
      internal Uris(FPod pod) : base(pod) {}

      public override FTable read(FStore.Input input)
      {
         if (input == null) { m_size = 0; return this; }
         m_size = input.u2();
         m_table = new object[m_size];
         for (int i=0; i<m_size; i++)
           m_table[i] = Uri.fromStr(input.utf());
         return this;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal FPod m_pod;
    internal int m_size;
    internal object[] m_table;
  }
}