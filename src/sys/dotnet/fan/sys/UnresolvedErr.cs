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

    public new static UnresolvedErr make(string msg, Exception cause)  { return make(msg, Err.make(cause)); }
    public static UnresolvedErr make(Uri uri) { return make(uri.m_str); }

  //////////////////////////////////////////////////////////////////////////
  // Fantom Constructors
  //////////////////////////////////////////////////////////////////////////

    public new static UnresolvedErr make() { return make("", (Err)null); }
    public new static UnresolvedErr make(string msg) { return make(msg, (Err)null); }
    public new static UnresolvedErr make(string msg, Err cause)
    {
      UnresolvedErr err = new UnresolvedErr();
      make_(err, msg, cause);
      return err;
    }

    public static void make_(UnresolvedErr self) { make_(self, null);  }
    public static void make_(UnresolvedErr self, string msg) { make_(self, msg, null); }
    public static void make_(UnresolvedErr self, string msg, Err cause) { Err.make_(self, msg, cause); }

  //////////////////////////////////////////////////////////////////////////
  // C# Constructors
  //////////////////////////////////////////////////////////////////////////

    public UnresolvedErr(Err.Val val) : base(val) {}
    public UnresolvedErr() : base(new UnresolvedErr.Val()) {}
    public UnresolvedErr(Exception actual) : base(new UnresolvedErr.Val(), actual) {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.UnresolvedErrType; }

  //////////////////////////////////////////////////////////////////////////
  // Val - C# Exception Type
  //////////////////////////////////////////////////////////////////////////

    public new class Val : Err.Val {}

  }
}