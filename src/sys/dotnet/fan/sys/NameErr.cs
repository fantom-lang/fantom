//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Dec 07  Andy Frank  Creation
//

using System;
using System.IO;

namespace Fan.Sys
{
  /// <summary>
  /// NameErr
  /// </summary>
  public class NameErr : Err
  {

  //////////////////////////////////////////////////////////////////////////
  // Fantom Constructors
  //////////////////////////////////////////////////////////////////////////

    public new static NameErr make() { return make("", (Err)null); }
    public new static NameErr make(string msg) { return make(msg, (Err)null); }
    public new static NameErr make(string msg, Err cause)
    {
      NameErr err = new NameErr();
      make_(err, msg, cause);
      return err;
    }

    public static void make_(NameErr self) { make_(self, null);  }
    public static void make_(NameErr self, string msg) { make_(self, msg, null); }
    public static void make_(NameErr self, string msg, Err cause) { Err.make_(self, msg, cause); }

  //////////////////////////////////////////////////////////////////////////
  // C# Constructors
  //////////////////////////////////////////////////////////////////////////

    public NameErr(Err.Val val) : base(val) {}
    public NameErr() : base(new NameErr.Val()) {}
    public NameErr(Exception actual) : base(new NameErr.Val(), actual) {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.NameErrType; }

  //////////////////////////////////////////////////////////////////////////
  // Val - C# Exception Type
  //////////////////////////////////////////////////////////////////////////

    public new class Val : Err.Val {}

  }
}