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

    public static ArgErr make(long index)   { return make(index.ToString()); }
    public static ArgErr make(Range index) { return make(index.ToString()); }

  //////////////////////////////////////////////////////////////////////////
  // Fantom Constructors
  //////////////////////////////////////////////////////////////////////////

    public new static ArgErr make() { return make("", (Err)null); }
    public new static ArgErr make(string msg) { return make(msg, (Err)null); }
    public new static ArgErr make(string msg, Err cause)
    {
      ArgErr err = new ArgErr();
      make_(err, msg, cause);
      return err;
    }

    public static void make_(ArgErr self) { make_(self, null);  }
    public static void make_(ArgErr self, string msg) { make_(self, msg, null); }
    public static void make_(ArgErr self, string msg, Err cause) { Err.make_(self, msg, cause); }

  //////////////////////////////////////////////////////////////////////////
  // C# Constructors
  //////////////////////////////////////////////////////////////////////////

    public ArgErr(Err.Val val) : base(val) {}
    public ArgErr() : base(new ArgErr.Val()) {}
    public ArgErr(Exception actual) : base(new ArgErr.Val(), actual) {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.ArgErrType; }

  //////////////////////////////////////////////////////////////////////////
  // Val - C# Exception Type
  //////////////////////////////////////////////////////////////////////////

    public new class Val : Err.Val {}

  }
}