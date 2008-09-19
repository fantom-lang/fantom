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

    public new static IndexErr make(string msg)  { return make(Str.make(msg)); }
    public static IndexErr make(Int index)       { return make(Str.make(index.ToString())); }
    public static IndexErr make(Range index) { return make(Str.make(index.ToString())); }

  //////////////////////////////////////////////////////////////////////////
  // Fan Constructors
  //////////////////////////////////////////////////////////////////////////

    public new static IndexErr make() { return make((Str)null, (Err)null); }
    public new static IndexErr make(Str msg) { return make(msg, null); }
    public new static IndexErr make(Str msg, Err cause)
    {
      IndexErr err = new IndexErr();
      make_(err, msg, cause);
      return err;
    }

    public static void make_(IndexErr self) { make_(self, null);  }
    public static void make_(IndexErr self, Str msg) { make_(self, msg, null); }
    public static void make_(IndexErr self, Str msg, Err cause) { Err.make_(self, msg, cause); }

  //////////////////////////////////////////////////////////////////////////
  // C# Constructors
  //////////////////////////////////////////////////////////////////////////

    public IndexErr(Err.Val val) : base(val) {}
    public IndexErr() : base(new IndexErr.Val()) {}
    public IndexErr(Exception actual) : base(new IndexErr.Val(), actual) {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type type() { return Sys.IndexErrType; }

  //////////////////////////////////////////////////////////////////////////
  // Val - C# Exception Type
  //////////////////////////////////////////////////////////////////////////

    public new class Val : Err.Val {}

  }
}
