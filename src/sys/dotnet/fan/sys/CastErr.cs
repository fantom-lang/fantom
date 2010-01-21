//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Apr 07  Andy Frank  Creation
//

using System;

namespace Fan.Sys
{
  /// <summary>
  /// CastErr
  /// </summary>
  public class CastErr : Err
  {

  //////////////////////////////////////////////////////////////////////////
  // C# Convenience
  //////////////////////////////////////////////////////////////////////////

    public static CastErr make(long index)   { return make(index.ToString()); }
    public static CastErr make(Range index) { return make(index.ToString()); }

  //////////////////////////////////////////////////////////////////////////
  // Fantom Constructors
  //////////////////////////////////////////////////////////////////////////

    public new static CastErr make() { return make("", (Err)null); }
    public new static CastErr make(string msg) { return make(msg, (Err)null); }
    public new static CastErr make(string msg, Err cause)
    {
      CastErr err = new CastErr();
      make_(err, msg, cause);
      return err;
    }

    public static void make_(CastErr self) { make_(self, null);  }
    public static void make_(CastErr self, string msg) { make_(self, msg, null); }
    public static void make_(CastErr self, string msg, Err cause) { Err.make_(self, msg, cause); }

  //////////////////////////////////////////////////////////////////////////
  // C# Constructors
  //////////////////////////////////////////////////////////////////////////

    public CastErr(Err.Val val) : base(val) {}
    public CastErr() : base(new CastErr.Val()) {}
    public CastErr(Exception actual) : base(new CastErr.Val(), actual) {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.CastErrType; }

  //////////////////////////////////////////////////////////////////////////
  // Val - C# Exception Type
  //////////////////////////////////////////////////////////////////////////

    public new class Val : Err.Val {}

  }
}