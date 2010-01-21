//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Sep 06  Andy Frank  Creation
//

using System;
using System.IO;

namespace Fan.Sys
{
  /// <summary>
  /// NullErr.
  /// </summary>
  public class NullErr : Err
  {

  //////////////////////////////////////////////////////////////////////////
  // Fantom Constructors
  //////////////////////////////////////////////////////////////////////////

    public new static NullErr make() { return make("", (Err)null); }
    public new static NullErr make(string msg) { return make(msg, (Err)null); }
    public new static NullErr make(string msg, Err cause)
    {
      NullErr err = new NullErr();
      make_(err, msg, cause);
      return err;
    }

    public static void make_(NullErr self) { make_(self, null);  }
    public static void make_(NullErr self, string msg) { make_(self, msg, null); }
    public static void make_(NullErr self, string msg, Err cause) { Err.make_(self, msg, cause); }

  //////////////////////////////////////////////////////////////////////////
  // C# Constructors
  //////////////////////////////////////////////////////////////////////////

    public static Err.Val makeCoerce() { return make("Coerce to non-null", (Err)null).val; }

    public NullErr(Err.Val val) : base(val) {}
    public NullErr() : base(new NullErr.Val()) {}
    public NullErr(Exception actual) : base(new NullErr.Val(), actual) {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.NullErrType; }

  //////////////////////////////////////////////////////////////////////////
  // Val - C# Exception Type
  //////////////////////////////////////////////////////////////////////////

    public new class Val : Err.Val {}

  }
}