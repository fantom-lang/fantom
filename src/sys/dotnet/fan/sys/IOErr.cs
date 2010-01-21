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
  /// IOErr.
  /// </summary>
  public class IOErr : Err
  {

  //////////////////////////////////////////////////////////////////////////
  // C# Convenience
  //////////////////////////////////////////////////////////////////////////

    public new static IOErr make(string msg, Exception cause)  { return make(msg, Err.make(cause)); }

  //////////////////////////////////////////////////////////////////////////
  // Fantom Constructors
  //////////////////////////////////////////////////////////////////////////

    public new static IOErr make() { return make("", (Err)null); }
    public new static IOErr make(string msg) { return make(msg, (Err)null); }
    public new static IOErr make(string msg, Err cause)
    {
      IOErr err = new IOErr();
      make_(err, msg, cause);
      return err;
    }

    public static void make_(IOErr self) { make_(self, null);  }
    public static void make_(IOErr self, string msg) { make_(self, msg, null); }
    public static void make_(IOErr self, string msg, Err cause) { Err.make_(self, msg, cause); }

  //////////////////////////////////////////////////////////////////////////
  // C# Constructors
  //////////////////////////////////////////////////////////////////////////

    public IOErr(Err.Val val) : base(val) {}
    public IOErr() : base(new IOErr.Val()) {}
    public IOErr(Exception actual) : base(new IOErr.Val(), actual) {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.IOErrType; }

  //////////////////////////////////////////////////////////////////////////
  // Val - C# Exception Type
  //////////////////////////////////////////////////////////////////////////

    public new class Val : Err.Val {}

  }
}