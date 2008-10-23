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
  /// UnknownThreadErr
  /// </summary>
  public class UnknownThreadErr : Err
  {

  //////////////////////////////////////////////////////////////////////////
  // Fan Constructors
  //////////////////////////////////////////////////////////////////////////

    public new static UnknownThreadErr make() { return make((string)null, (Err)null); }
    public new static UnknownThreadErr make(string msg) { return make(msg, (Err)null); }
    public new static UnknownThreadErr make(string msg, Err cause)
    {
      UnknownThreadErr err = new UnknownThreadErr();
      make_(err, msg, cause);
      return err;
    }

    public static void make_(UnknownThreadErr self) { make_(self, null);  }
    public static void make_(UnknownThreadErr self, string msg) { make_(self, msg, null); }
    public static void make_(UnknownThreadErr self, string msg, Err cause) { Err.make_(self, msg, cause); }

  //////////////////////////////////////////////////////////////////////////
  // C# Constructors
  //////////////////////////////////////////////////////////////////////////

    public UnknownThreadErr(Err.Val val) : base(val) {}
    public UnknownThreadErr() : base(new UnknownThreadErr.Val()) {}
    public UnknownThreadErr(Exception actual) : base(new UnknownThreadErr.Val(), actual) {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type type() { return Sys.UnknownThreadErrType; }

  //////////////////////////////////////////////////////////////////////////
  // Val - C# Exception Type
  //////////////////////////////////////////////////////////////////////////

    public new class Val : Err.Val {}

  }
}