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
  /// ReadonlyErr.
  /// </summary>
  public class ReadonlyErr : Err
  {

  //////////////////////////////////////////////////////////////////////////
  // Fantom Constructors
  //////////////////////////////////////////////////////////////////////////

    public new static ReadonlyErr make() { return make("", (Err)null); }
    public new static ReadonlyErr make(string msg) { return make(msg, (Err)null); }
    public new static ReadonlyErr make(string msg, Err cause)
    {
      ReadonlyErr err = new ReadonlyErr();
      make_(err, msg, cause);
      return err;
    }

    public static void make_(ReadonlyErr self) { make_(self, null);  }
    public static void make_(ReadonlyErr self, string msg) { make_(self, msg, null); }
    public static void make_(ReadonlyErr self, string msg, Err cause) { Err.make_(self, msg, cause); }

  //////////////////////////////////////////////////////////////////////////
  // C# Constructors
  //////////////////////////////////////////////////////////////////////////

    public ReadonlyErr(Err.Val val) : base(val) {}
    public ReadonlyErr() : base(new ReadonlyErr.Val()) {}
    public ReadonlyErr(Exception actual) : base(new ReadonlyErr.Val(), actual) {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.ReadonlyErrType; }

  //////////////////////////////////////////////////////////////////////////
  // Val - C# Exception Type
  //////////////////////////////////////////////////////////////////////////

    public new class Val : Err.Val {}

  }
}