//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   7 Feb 07  Andy Frank  Creation
//

using System;

namespace Fan.Sys
{
  /// <summary>
  /// NotImmutableErr
  /// </summary>
  public class NotImmutableErr : Err
  {

  //////////////////////////////////////////////////////////////////////////
  // Fantom Constructors
  //////////////////////////////////////////////////////////////////////////

    public new static NotImmutableErr make() { return make("", (Err)null); }
    public new static NotImmutableErr make(string msg) { return make(msg, (Err)null); }
    public new static NotImmutableErr make(string msg, Err cause)
    {
      NotImmutableErr err = new NotImmutableErr();
      make_(err, msg, cause);
      return err;
    }

    public static void make_(NotImmutableErr self) { make_(self, null);  }
    public static void make_(NotImmutableErr self, string msg) { make_(self, msg, null); }
    public static void make_(NotImmutableErr self, string msg, Err cause) { Err.make_(self, msg, cause); }

  //////////////////////////////////////////////////////////////////////////
  // Java Constructors
  //////////////////////////////////////////////////////////////////////////

    public NotImmutableErr(Err.Val val) : base(val) {}
    public NotImmutableErr() : base(new NotImmutableErr.Val()) {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.NotImmutableErrType; }

  //////////////////////////////////////////////////////////////////////////
  // Val - Java Exception Type
  //////////////////////////////////////////////////////////////////////////

    public new class Val : Err.Val {}

  }
}