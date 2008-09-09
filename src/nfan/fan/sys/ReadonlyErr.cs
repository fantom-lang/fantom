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
  // C# Convenience
  //////////////////////////////////////////////////////////////////////////

    public new static ReadonlyErr make(string msg)  { return make(Str.make(msg)); }

  //////////////////////////////////////////////////////////////////////////
  // Fan Constructors
  //////////////////////////////////////////////////////////////////////////

    public new static ReadonlyErr make() { return make((Str)null, (Err)null); }
    public new static ReadonlyErr make(Str msg) { return make(msg, null); }
    public new static ReadonlyErr make(Str msg, Err cause)
    {
      ReadonlyErr err = new ReadonlyErr();
      make_(err, msg, cause);
      return err;
    }

    public static void make_(ReadonlyErr self) { make_(self, null);  }
    public static void make_(ReadonlyErr self, Str msg) { make_(self, msg, null); }
    public static void make_(ReadonlyErr self, Str msg, Err cause) { Err.make_(self, msg, cause); }

  //////////////////////////////////////////////////////////////////////////
  // C# Constructors
  //////////////////////////////////////////////////////////////////////////

    public ReadonlyErr(Err.Val val) : base(val) {}
    public ReadonlyErr() : base(new ReadonlyErr.Val()) {}
    public ReadonlyErr(Exception actual) : base(new ReadonlyErr.Val(), actual) {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type type() { return Sys.ReadonlyErrType; }

  //////////////////////////////////////////////////////////////////////////
  // Val - C# Exception Type
  //////////////////////////////////////////////////////////////////////////

    public new class Val : Err.Val {}

  }
}