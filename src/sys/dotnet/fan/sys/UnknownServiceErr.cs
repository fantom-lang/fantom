//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Dec 07  Andy Frank  Creation
//

using System;
using System.IO;

namespace Fan.Sys
{
  /// <summary>
  /// UnknownServiceErr
  /// </summary>
  public class UnknownServiceErr : Err
  {

  //////////////////////////////////////////////////////////////////////////
  // Fantom Constructors
  //////////////////////////////////////////////////////////////////////////

    public new static UnknownServiceErr make() { return make("", (Err)null); }
    public new static UnknownServiceErr make(string msg) { return make(msg, (Err)null); }
    public new static UnknownServiceErr make(string msg, Err cause)
    {
      UnknownServiceErr err = new UnknownServiceErr();
      make_(err, msg, cause);
      return err;
    }

    public static void make_(UnknownServiceErr self) { make_(self, null);  }
    public static void make_(UnknownServiceErr self, string msg) { make_(self, msg, null); }
    public static void make_(UnknownServiceErr self, string msg, Err cause) { Err.make_(self, msg, cause); }

  //////////////////////////////////////////////////////////////////////////
  // C# Constructors
  //////////////////////////////////////////////////////////////////////////

    public UnknownServiceErr(Err.Val val) : base(val) {}
    public UnknownServiceErr() : base(new UnknownServiceErr.Val()) {}
    public UnknownServiceErr(Exception actual) : base(new UnknownServiceErr.Val(), actual) {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.UnknownServiceErrType; }

  //////////////////////////////////////////////////////////////////////////
  // Val - C# Exception Type
  //////////////////////////////////////////////////////////////////////////

    public new class Val : Err.Val {}

  }
}