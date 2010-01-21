//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Apr 09  Brian Frank  Creation
//

using System;

namespace Fan.Sys
{
  /// <summary>
  /// ConstErr
  /// </summary>
  public class ConstErr : Err
  {

  //////////////////////////////////////////////////////////////////////////
  // Fantom Constructors
  //////////////////////////////////////////////////////////////////////////

    public new static ConstErr make() { return make("", (Err)null); }
    public new static ConstErr make(string msg) { return make(msg, (Err)null); }
    public new static ConstErr make(string msg, Err cause)
    {
      ConstErr err = new ConstErr();
      make_(err, msg, cause);
      return err;
    }

    public static void make_(ConstErr self) { make_(self, null);  }
    public static void make_(ConstErr self, string msg) { make_(self, msg, null); }
    public static void make_(ConstErr self, string msg, Err cause) { Err.make_(self, msg, cause); }

  //////////////////////////////////////////////////////////////////////////
  // Java Constructors
  //////////////////////////////////////////////////////////////////////////

    public ConstErr(Err.Val val) : base(val) {}
    public ConstErr() : base(new ConstErr.Val()) {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.ConstErrType; }

  //////////////////////////////////////////////////////////////////////////
  // Val - Java Exception Type
  //////////////////////////////////////////////////////////////////////////

    public new class Val : Err.Val {}

  }
}