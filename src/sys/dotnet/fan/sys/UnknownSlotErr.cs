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
  /// UnknownSlotErr
  /// </summary>
  public class UnknownSlotErr : Err
  {

  //////////////////////////////////////////////////////////////////////////
  // Fantom Constructors
  //////////////////////////////////////////////////////////////////////////

    public new static UnknownSlotErr make() { return make("", (Err)null); }
    public new static UnknownSlotErr make(string msg) { return make(msg, (Err)null); }
    public new static UnknownSlotErr make(string msg, Err cause)
    {
      UnknownSlotErr err = new UnknownSlotErr();
      make_(err, msg, cause);
      return err;
    }

    public static void make_(UnknownSlotErr self) { make_(self, null);  }
    public static void make_(UnknownSlotErr self, string msg) { make_(self, msg, null); }
    public static void make_(UnknownSlotErr self, string msg, Err cause) { Err.make_(self, msg, cause); }

  //////////////////////////////////////////////////////////////////////////
  // C# Constructors
  //////////////////////////////////////////////////////////////////////////

    public UnknownSlotErr(Err.Val val) : base(val) {}
    public UnknownSlotErr() : base(new UnknownSlotErr.Val()) {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.UnknownSlotErrType; }

  //////////////////////////////////////////////////////////////////////////
  // Val - C# Exception Type
  //////////////////////////////////////////////////////////////////////////

    public new class Val : Err.Val {}

  }
}