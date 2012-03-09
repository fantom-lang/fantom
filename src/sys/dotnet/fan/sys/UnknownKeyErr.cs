//
// Copyright (c) 2012, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   09 Mar 12  Brian Frank  Creation
//

using System;
using System.IO;

namespace Fan.Sys
{
  /// <summary>
  /// UnknownKeyErr
  /// </summary>
  public class UnknownKeyErr : Err
  {

  //////////////////////////////////////////////////////////////////////////
  // Fantom Constructors
  //////////////////////////////////////////////////////////////////////////

    public new static UnknownKeyErr make() { return make("", (Err)null); }
    public new static UnknownKeyErr make(string msg) { return make(msg, (Err)null); }
    public new static UnknownKeyErr make(string msg, Err cause)
    {
      UnknownKeyErr err = new UnknownKeyErr();
      make_(err, msg, cause);
      return err;
    }

    public static void make_(UnknownKeyErr self) { make_(self, null);  }
    public static void make_(UnknownKeyErr self, string msg) { make_(self, msg, null); }
    public static void make_(UnknownKeyErr self, string msg, Err cause) { Err.make_(self, msg, cause); }

  //////////////////////////////////////////////////////////////////////////
  // C# Constructors
  //////////////////////////////////////////////////////////////////////////

    public UnknownKeyErr(Err.Val val) : base(val) {}
    public UnknownKeyErr() : base(new UnknownKeyErr.Val()) {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.UnknownKeyErrType; }

  //////////////////////////////////////////////////////////////////////////
  // Val - C# Exception Type
  //////////////////////////////////////////////////////////////////////////

    public new class Val : Err.Val {}

  }
}