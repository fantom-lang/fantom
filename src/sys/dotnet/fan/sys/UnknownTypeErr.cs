//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Sep 06  Andy Frank  Creation
//

using System;
using System.IO;

namespace Fan.Sys
{
  /// <summary>
  /// UnknownTypeErr
  /// </summary>
  public class UnknownTypeErr : Err
  {

  //////////////////////////////////////////////////////////////////////////
  // Fantom Constructors
  //////////////////////////////////////////////////////////////////////////

    public new static UnknownTypeErr make() { return make("", (Err)null); }
    public new static UnknownTypeErr make(string msg) { return make(msg, (Err)null); }
    public new static UnknownTypeErr make(string msg, Err cause)
    {
      UnknownTypeErr err = new UnknownTypeErr();
      make_(err, msg, cause);
      return err;
    }

    public static void make_(UnknownTypeErr self) { make_(self, null);  }
    public static void make_(UnknownTypeErr self, string msg) { make_(self, msg, null); }
    public static void make_(UnknownTypeErr self, string msg, Err cause) { Err.make_(self, msg, cause); }

  //////////////////////////////////////////////////////////////////////////
  // C# Constructors
  //////////////////////////////////////////////////////////////////////////

    public UnknownTypeErr(Err.Val val) : base(val) {}
    public UnknownTypeErr() : base(new UnknownTypeErr.Val()) {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.UnknownTypeErrType; }

  //////////////////////////////////////////////////////////////////////////
  // Val - C# Exception Type
  //////////////////////////////////////////////////////////////////////////

    public new class Val : Err.Val {}

  }
}