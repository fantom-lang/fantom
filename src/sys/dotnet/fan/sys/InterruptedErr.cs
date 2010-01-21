//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Oct 07  Andy Frank  Creation
//

using System;

namespace Fan.Sys
{
  /// <summary>
  /// InterruptedErr
  /// </summary>
  public class InterruptedErr : Err
  {

  //////////////////////////////////////////////////////////////////////////
  // Fantom Constructors
  //////////////////////////////////////////////////////////////////////////

    public new static InterruptedErr make() { return make("", (Err)null); }
    public new static InterruptedErr make(string msg) { return make(msg, (Err)null); }
    public new static InterruptedErr make(string msg, Err cause)
    {
      InterruptedErr err = new InterruptedErr();
      make_(err, msg, cause);
      return err;
    }

    public static void make_(InterruptedErr self) { make_(self, null);  }
    public static void make_(InterruptedErr self, string msg) { make_(self, msg, null); }
    public static void make_(InterruptedErr self, string msg, Err cause) { Err.make_(self, msg, cause); }

  //////////////////////////////////////////////////////////////////////////
  // Java Constructors
  //////////////////////////////////////////////////////////////////////////

    public InterruptedErr(Err.Val val) : base(val) {}
    public InterruptedErr() : base(new InterruptedErr.Val()) {}
    public InterruptedErr(Exception actual) : base(new InterruptedErr.Val(), actual) {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.InterruptedErrType; }

  //////////////////////////////////////////////////////////////////////////
  // Val - Java Exception Type
  //////////////////////////////////////////////////////////////////////////

    public new class Val : Err.Val {}

  }
}