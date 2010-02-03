//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Jul 09  Brian Frank  Creation
//

using System;
using System.IO;

namespace Fan.Sys
{
  /// <summary>
  /// UnknownFacetErr
  /// </summary>
  public class UnknownFacetErr : Err
  {

  //////////////////////////////////////////////////////////////////////////
  // Fantom Constructors
  //////////////////////////////////////////////////////////////////////////

    public new static UnknownFacetErr make() { return make("", (Err)null); }
    public new static UnknownFacetErr make(string msg) { return make(msg, (Err)null); }
    public new static UnknownFacetErr make(string msg, Err cause)
    {
      UnknownFacetErr err = new UnknownFacetErr();
      make_(err, msg, cause);
      return err;
    }

    public static void make_(UnknownFacetErr self) { make_(self, null);  }
    public static void make_(UnknownFacetErr self, string msg) { make_(self, msg, null); }
    public static void make_(UnknownFacetErr self, string msg, Err cause) { Err.make_(self, msg, cause); }

  //////////////////////////////////////////////////////////////////////////
  // C# Constructors
  //////////////////////////////////////////////////////////////////////////

    public UnknownFacetErr(Err.Val val) : base(val) {}
    public UnknownFacetErr() : base(new UnknownFacetErr.Val()) {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.UnknownFacetErrType; }

  //////////////////////////////////////////////////////////////////////////
  // Val - C# Exception Type
  //////////////////////////////////////////////////////////////////////////

    public new class Val : Err.Val {}

  }
}