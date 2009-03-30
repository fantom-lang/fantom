//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Mar 09  Andy Frank  Creation
//

namespace Fan.Sys
{
  /// <summary>
  /// TimeoutErr.
  /// </summary>
  public class TimeoutErr : Err
  {

  //////////////////////////////////////////////////////////////////////////
  // Fan Constructors
  //////////////////////////////////////////////////////////////////////////

    public new static TimeoutErr make() { return make((string)null, (Err)null); }
    public new static TimeoutErr make(string msg) { return make(msg, (Err)null); }
    public new static TimeoutErr make(string msg, Err cause)
    {
      TimeoutErr err = new TimeoutErr();
      make_(err, msg, cause);
      return err;
    }

    public static void make_(TimeoutErr self) { make_(self, null);  }
    public static void make_(TimeoutErr self, string msg) { make_(self, msg, null); }
    public static void make_(TimeoutErr self, string msg, Err cause) { Err.make_(self, msg, cause); }

  //////////////////////////////////////////////////////////////////////////
  // C# Constructors
  //////////////////////////////////////////////////////////////////////////

    public TimeoutErr(Err.Val val) : base(val) {}
    public TimeoutErr() : base(new TimeoutErr.Val()) {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type type() { return Sys.TimeoutErrType; }

  //////////////////////////////////////////////////////////////////////////
  // Val - C# Exception Type
  //////////////////////////////////////////////////////////////////////////

    public new class Val : Err.Val {}

  }
}