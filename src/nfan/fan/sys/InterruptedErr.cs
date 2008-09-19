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
  // C# Convenience
  //////////////////////////////////////////////////////////////////////////

    public new static InterruptedErr make(string msg)  { return make(Str.make(msg)); }

  //////////////////////////////////////////////////////////////////////////
  // Fan Constructors
  //////////////////////////////////////////////////////////////////////////

    public new static InterruptedErr make() { return make((Str)null, (Err)null); }
    public new static InterruptedErr make(Str msg) { return make(msg, null); }
    public new static InterruptedErr make(Str msg, Err cause)
    {
      InterruptedErr err = new InterruptedErr();
      make_(err, msg, cause);
      return err;
    }

    public static void make_(InterruptedErr self) { make_(self, null);  }
    public static void make_(InterruptedErr self, Str msg) { make_(self, msg, null); }
    public static void make_(InterruptedErr self, Str msg, Err cause) { Err.make_(self, msg, cause); }

  //////////////////////////////////////////////////////////////////////////
  // Java Constructors
  //////////////////////////////////////////////////////////////////////////

    public InterruptedErr(Err.Val val) : base(val) {}
    public InterruptedErr() : base(new InterruptedErr.Val()) {}
    public InterruptedErr(Exception actual) : base(new InterruptedErr.Val(), actual) {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type type() { return Sys.InterruptedErrType; }

  //////////////////////////////////////////////////////////////////////////
  // Val - Java Exception Type
  //////////////////////////////////////////////////////////////////////////

    public new class Val : Err.Val {}

  }
}
