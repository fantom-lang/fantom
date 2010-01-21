//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Oct 06  Andy Frank  Creation
//

using System;
using System.IO;

namespace Fan.Sys
{
  /// <summary>
  /// UnsupportedErr
  /// </summary>
  public class UnsupportedErr : Err
  {

  //////////////////////////////////////////////////////////////////////////
  // Fantom Constructors
  //////////////////////////////////////////////////////////////////////////

    public new static UnsupportedErr make() { return make("", (Err)null); }
    public new static UnsupportedErr make(string msg) { return make(msg, (Err)null); }
    public new static UnsupportedErr make(string msg, Err cause)
    {
      UnsupportedErr err = new UnsupportedErr();
      make_(err, msg, cause);
      return err;
    }

    public static void make_(UnsupportedErr self) { make_(self, null);  }
    public static void make_(UnsupportedErr self, string msg) { make_(self, msg, null); }
    public static void make_(UnsupportedErr self, string msg, Err cause) { Err.make_(self, msg, cause); }

  //////////////////////////////////////////////////////////////////////////
  // C# Constructors
  //////////////////////////////////////////////////////////////////////////

    public UnsupportedErr(Err.Val val) : base(val) {}
    public UnsupportedErr() : base(new UnsupportedErr.Val()) {}
    public UnsupportedErr(Exception actual) : base(new UnsupportedErr.Val(), actual) {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.UnsupportedErrType; }

  //////////////////////////////////////////////////////////////////////////
  // Val - C# Exception Type
  //////////////////////////////////////////////////////////////////////////

    public new class Val : Err.Val {}

  }
}