//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Nov 07  Andy Frank  Creation
//

using System;
using System.IO;

namespace Fan.Sys
{
  /// <summary>
  /// UnresolvedErr
  /// </summary>
  public class UnresolvedErr : Err
  {

  //////////////////////////////////////////////////////////////////////////
  // C# Convenience
  //////////////////////////////////////////////////////////////////////////

    public new static UnresolvedErr make(string msg) { return make(Str.make(msg)); }
    public new static UnresolvedErr make(String msg, Exception cause)  { return make(Str.make(msg), Err.make(cause)); }
    public static UnresolvedErr make(String msg, Err cause)  { return make(Str.make(msg), cause); }
    public static UnresolvedErr make(Uri uri) { return make(uri.m_str); }

  //////////////////////////////////////////////////////////////////////////
  // Fan Constructors
  //////////////////////////////////////////////////////////////////////////

    public new static UnresolvedErr make() { return make((Str)null, (Err)null); }
    public new static UnresolvedErr make(Str msg) { return make(msg, null); }
    public new static UnresolvedErr make(Str msg, Err cause)
    {
      UnresolvedErr err = new UnresolvedErr();
      make_(err, msg, cause);
      return err;
    }

    public static void make_(UnresolvedErr self) { make_(self, null);  }
    public static void make_(UnresolvedErr self, Str msg) { make_(self, msg, null); }
    public static void make_(UnresolvedErr self, Str msg, Err cause) { Err.make_(self, msg, cause); }

  //////////////////////////////////////////////////////////////////////////
  // C# Constructors
  //////////////////////////////////////////////////////////////////////////

    public UnresolvedErr(Err.Val val) : base(val) {}
    public UnresolvedErr() : base(new UnresolvedErr.Val()) {}
    public UnresolvedErr(Exception actual) : base(new UnresolvedErr.Val(), actual) {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type type() { return Sys.UnresolvedErrType; }

  //////////////////////////////////////////////////////////////////////////
  // Val - C# Exception Type
  //////////////////////////////////////////////////////////////////////////

    public new class Val : Err.Val {}

  }
}
