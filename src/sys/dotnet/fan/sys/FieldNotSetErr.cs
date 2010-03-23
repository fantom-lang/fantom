//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Mar 10  Brian Frank  Creation
//

using System;
using System.IO;

namespace Fan.Sys
{
  /// <summary>
  /// FieldNotSetErr
  /// </summary>
  public class FieldNotSetErr : Err
  {

  //////////////////////////////////////////////////////////////////////////
  // Fantom Constructors
  //////////////////////////////////////////////////////////////////////////

    public new static FieldNotSetErr make() { return make("", (Err)null); }
    public new static FieldNotSetErr make(string msg) { return make(msg, (Err)null); }
    public new static FieldNotSetErr make(string msg, Err cause)
    {
      FieldNotSetErr err = new FieldNotSetErr();
      make_(err, msg, cause);
      return err;
    }

    public static void make_(FieldNotSetErr self) { make_(self, null);  }
    public static void make_(FieldNotSetErr self, string msg) { make_(self, msg, null); }
    public static void make_(FieldNotSetErr self, string msg, Err cause) { Err.make_(self, msg, cause); }

  //////////////////////////////////////////////////////////////////////////
  // C# Constructors
  //////////////////////////////////////////////////////////////////////////

    public FieldNotSetErr(Err.Val val) : base(val) {}
    public FieldNotSetErr() : base(new FieldNotSetErr.Val()) {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.FieldNotSetErrType; }

  //////////////////////////////////////////////////////////////////////////
  // Val - C# Exception Type
  //////////////////////////////////////////////////////////////////////////

    public new class Val : Err.Val {}

  }
}