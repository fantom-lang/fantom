//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Oct 06  Andy Frank  Creation
//

using System;

namespace Fan.Sys
{
  /// <summary>
  /// ArgErr
  /// </summary>
  public class ArgErr : Err
  {

  //////////////////////////////////////////////////////////////////////////
  // C# Convenience
  //////////////////////////////////////////////////////////////////////////

    public new static ArgErr make(string msg)  { return make(Str.make(msg)); }
    public static ArgErr make(Int index)   { return make(Str.make(index.ToString())); }
    public static ArgErr make(Range index) { return make(Str.make(index.ToString())); }

  //////////////////////////////////////////////////////////////////////////
  // Fan Constructors
  //////////////////////////////////////////////////////////////////////////

    public new static ArgErr make() { return make((Str)null, (Err)null); }
    public new static ArgErr make(Str msg) { return make(msg, null); }
    public new static ArgErr make(Str msg, Err cause)
    {
      ArgErr err = new ArgErr();
      make_(err, msg, cause);
      return err;
    }

    public static void make_(ArgErr self) { make_(self, null);  }
    public static void make_(ArgErr self, Str msg) { make_(self, msg, null); }
    public static void make_(ArgErr self, Str msg, Err cause) { Err.make_(self, msg, cause); }

  //////////////////////////////////////////////////////////////////////////
  // C# Constructors
  //////////////////////////////////////////////////////////////////////////

    public ArgErr(Err.Val val) : base(val) {}
    public ArgErr() : base(new ArgErr.Val()) {}
    public ArgErr(Exception actual) : base(new ArgErr.Val(), actual) {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type type() { return Sys.ArgErrType; }

  //////////////////////////////////////////////////////////////////////////
  // Val - C# Exception Type
  //////////////////////////////////////////////////////////////////////////

    public new class Val : Err.Val {}

  }
}