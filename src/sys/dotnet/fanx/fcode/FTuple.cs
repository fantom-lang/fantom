//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Sep 06  Andy Frank  Creation
//

using System;
using System.Text;

namespace Fanx.Fcode
{
  ///
  /// FTuple stores a list of FTable indices to model a more complex
  /// struction like a type's qname or a slot signature.
  ///
  public class FTuple
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructors
  //////////////////////////////////////////////////////////////////////////

    public FTuple(int a, int b)
    {
      this.val = new int[] { a, b };
    }

    public FTuple(int a, int b, int c)
    {
      this.val = new int[] { a, b, c };
    }

    public FTuple(int[] val)
    {
      this.val = val;
    }

  //////////////////////////////////////////////////////////////////////////
  // .NET
  //////////////////////////////////////////////////////////////////////////

    public override int GetHashCode()
    {
      if (hashCode == 0)
      {
        int hash = 33;
        for (int i=0; i<val.Length; ++i)
          hash ^= val[i] << i;
      }
      return hashCode;
    }

    public override bool Equals(object obj)
    {
      FTuple x = (FTuple)obj;
      if (val.Length != x.val.Length) return false;
      for (int i=0; i<val.Length; ++i)
        if (val[i] != x.val[i]) return false;
      return true;
    }

    public override string ToString()
    {
      StringBuilder s = new StringBuilder();
      s.Append('{');
      for (int i=0; i<val.Length; i++)
      {
        if (i > 0) s.Append(", ");
        s.Append(val[i]);
      }
      s.Append('}');
      return s.ToString();
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public int[] val;
    private int hashCode = 0;

  }
}
