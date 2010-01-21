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
  /// UnknownSymbolErr
  /// </summary>
  public class UnknownSymbolErr : Err
  {

  //////////////////////////////////////////////////////////////////////////
  // Fantom Constructors
  //////////////////////////////////////////////////////////////////////////

    public new static UnknownSymbolErr make() { return make("", (Err)null); }
    public new static UnknownSymbolErr make(string msg) { return make(msg, (Err)null); }
    public new static UnknownSymbolErr make(string msg, Err cause)
    {
      UnknownSymbolErr err = new UnknownSymbolErr();
      make_(err, msg, cause);
      return err;
    }

    public static void make_(UnknownSymbolErr self) { make_(self, null);  }
    public static void make_(UnknownSymbolErr self, string msg) { make_(self, msg, null); }
    public static void make_(UnknownSymbolErr self, string msg, Err cause) { Err.make_(self, msg, cause); }

  //////////////////////////////////////////////////////////////////////////
  // C# Constructors
  //////////////////////////////////////////////////////////////////////////

    public UnknownSymbolErr(Err.Val val) : base(val) {}
    public UnknownSymbolErr() : base(new UnknownSymbolErr.Val()) {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.UnknownSymbolErrType; }

  //////////////////////////////////////////////////////////////////////////
  // Val - C# Exception Type
  //////////////////////////////////////////////////////////////////////////

    public new class Val : Err.Val {}

  }
}