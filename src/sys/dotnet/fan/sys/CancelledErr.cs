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
  /// Cancelled.
  /// </summary>
  public class CancelledErr : Err
  {

  //////////////////////////////////////////////////////////////////////////
  // Fantom Constructors
  //////////////////////////////////////////////////////////////////////////

    public new static CancelledErr make() { return make("", (Err)null); }
    public new static CancelledErr make(string msg) { return make(msg, (Err)null); }
    public new static CancelledErr make(string msg, Err cause)
    {
      CancelledErr err = new CancelledErr();
      make_(err, msg, cause);
      return err;
    }

    public static void make_(CancelledErr self) { make_(self, null);  }
    public static void make_(CancelledErr self, string msg) { make_(self, msg, null); }
    public static void make_(CancelledErr self, string msg, Err cause) { Err.make_(self, msg, cause); }

  //////////////////////////////////////////////////////////////////////////
  // C# Constructors
  //////////////////////////////////////////////////////////////////////////

    public CancelledErr(Err.Val val) : base(val) {}
    public CancelledErr() : base(new CancelledErr.Val()) {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.CancelledErrType; }

  //////////////////////////////////////////////////////////////////////////
  // Val - C# Exception Type
  //////////////////////////////////////////////////////////////////////////

    public new class Val : Err.Val {}

  }
}