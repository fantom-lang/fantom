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
  /// UnknownPodErr
  /// </summary>
  public class UnknownPodErr : Err
  {

  //////////////////////////////////////////////////////////////////////////
  // Fantom Constructors
  //////////////////////////////////////////////////////////////////////////

    public new static UnknownPodErr make() { return make("", (Err)null); }
    public new static UnknownPodErr make(string msg) { return make(msg, (Err)null); }
    public new static UnknownPodErr make(string msg, Err cause)
    {
      UnknownPodErr err = new UnknownPodErr();
      make_(err, msg, cause);
      return err;
    }

    public static void make_(UnknownPodErr self) { make_(self, null);  }
    public static void make_(UnknownPodErr self, string msg) { make_(self, msg, null); }
    public static void make_(UnknownPodErr self, string msg, Err cause) { Err.make_(self, msg, cause); }

  //////////////////////////////////////////////////////////////////////////
  // C# Constructors
  //////////////////////////////////////////////////////////////////////////

    public UnknownPodErr(Err.Val val) : base(val) {}
    public UnknownPodErr() : base(new UnknownPodErr.Val()) {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.UnknownPodErrType; }

  //////////////////////////////////////////////////////////////////////////
  // Val - C# Exception Type
  //////////////////////////////////////////////////////////////////////////

    public new class Val : Err.Val {}

  }
}