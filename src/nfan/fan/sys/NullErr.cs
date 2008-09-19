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
  /// NullErr.
  /// </summary>
  public class NullErr : Err
  {

  //////////////////////////////////////////////////////////////////////////
  // C# Convenience
  //////////////////////////////////////////////////////////////////////////

    public new static NullErr make(string msg)  { return make(Str.make(msg)); }

  //////////////////////////////////////////////////////////////////////////
  // Fan Constructors
  //////////////////////////////////////////////////////////////////////////

    public new static NullErr make() { return make((Str)null, (Err)null); }
    public new static NullErr make(Str msg) { return make(msg, null); }
    public new static NullErr make(Str msg, Err cause)
    {
      NullErr err = new NullErr();
      make_(err, msg, cause);
      return err;
    }

    public static void make_(NullErr self) { make_(self, null);  }
    public static void make_(NullErr self, Str msg) { make_(self, msg, null); }
    public static void make_(NullErr self, Str msg, Err cause) { Err.make_(self, msg, cause); }

  //////////////////////////////////////////////////////////////////////////
  // C# Constructors
  //////////////////////////////////////////////////////////////////////////

    public NullErr(Err.Val val) : base(val) {}
    public NullErr() : base(new NullErr.Val()) {}
    public NullErr(Exception actual) : base(new NullErr.Val(), actual) {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type type() { return Sys.NullErrType; }

  //////////////////////////////////////////////////////////////////////////
  // Val - C# Exception Type
  //////////////////////////////////////////////////////////////////////////

    public new class Val : Err.Val {}

  }
}
