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
  // C# Convenience
  //////////////////////////////////////////////////////////////////////////

    public new static UnknownTypeErr make(string msg)  { return make(Str.make(msg)); }

  //////////////////////////////////////////////////////////////////////////
  // Fan Constructors
  //////////////////////////////////////////////////////////////////////////

    public new static UnknownTypeErr make() { return make((Str)null, (Err)null); }
    public new static UnknownTypeErr make(Str msg) { return make(msg, null); }
    public new static UnknownTypeErr make(Str msg, Err cause)
    {
      UnknownTypeErr err = new UnknownTypeErr();
      make_(err, msg, cause);
      return err;
    }

    public static void make_(UnknownTypeErr self) { make_(self, null);  }
    public static void make_(UnknownTypeErr self, Str msg) { make_(self, msg, null); }
    public static void make_(UnknownTypeErr self, Str msg, Err cause) { Err.make_(self, msg, cause); }

  //////////////////////////////////////////////////////////////////////////
  // C# Constructors
  //////////////////////////////////////////////////////////////////////////

    public UnknownTypeErr(Err.Val val) : base(val) {}
    public UnknownTypeErr() : base(new UnknownTypeErr.Val()) {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type type() { return Sys.UnknownTypeErrType; }

  //////////////////////////////////////////////////////////////////////////
  // Val - C# Exception Type
  //////////////////////////////////////////////////////////////////////////

    public new class Val : Err.Val {}

  }
}