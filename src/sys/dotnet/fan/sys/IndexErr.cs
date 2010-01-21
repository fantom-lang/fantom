//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Sep 06  Andy Frank  Creation
//

using System;
using System.IO;

namespace Fan.Sys
{
  /// <summary>
  /// IndexErr.
  /// </summary>
  public class IndexErr : Err
  {

  //////////////////////////////////////////////////////////////////////////
  // C# Convenience
  //////////////////////////////////////////////////////////////////////////

    public static IndexErr make(long index)  { return make(index.ToString()); }
    public static IndexErr make(Range index) { return make(index.ToString()); }

  //////////////////////////////////////////////////////////////////////////
  // Fantom Constructors
  //////////////////////////////////////////////////////////////////////////

    public new static IndexErr make() { return make("", (Err)null); }
    public new static IndexErr make(string msg) { return make(msg, (Err)null); }
    public new static IndexErr make(string msg, Err cause)
    {
      IndexErr err = new IndexErr();
      make_(err, msg, cause);
      return err;
    }

    public static void make_(IndexErr self) { make_(self, null);  }
    public static void make_(IndexErr self, string msg) { make_(self, msg, null); }
    public static void make_(IndexErr self, string msg, Err cause) { Err.make_(self, msg, cause); }

  //////////////////////////////////////////////////////////////////////////
  // C# Constructors
  //////////////////////////////////////////////////////////////////////////

    public IndexErr(Err.Val val) : base(val) {}
    public IndexErr() : base(new IndexErr.Val()) {}
    public IndexErr(Exception actual) : base(new IndexErr.Val(), actual) {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.IndexErrType; }

  //////////////////////////////////////////////////////////////////////////
  // Val - C# Exception Type
  //////////////////////////////////////////////////////////////////////////

    public new class Val : Err.Val {}

  }
}