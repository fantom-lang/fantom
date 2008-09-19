//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Mar 08  Andy Frank  Creation
//

using System;
using System.IO;

namespace Fan.Sys
{
  /// <summary>
  /// TestErr
  /// </summary>
  public class TestErr : Err
  {

  //////////////////////////////////////////////////////////////////////////
  // C# Convenience
  //////////////////////////////////////////////////////////////////////////

    public new static TestErr make(string msg) { return make(Str.make(msg)); }

  //////////////////////////////////////////////////////////////////////////
  // Fan Constructors
  //////////////////////////////////////////////////////////////////////////

    public new static TestErr make() { return make((Str)null, (Err)null); }
    public new static TestErr make(Str msg) { return make(msg, null); }
    public new static TestErr make(Str msg, Err cause)
    {
      TestErr err = new TestErr();
      make_(err, msg, cause);
      return err;
    }

    public static void make_(TestErr self) { make_(self, null);  }
    public static void make_(TestErr self, Str msg) { make_(self, msg, null); }
    public static void make_(TestErr self, Str msg, Err cause) { Err.make_(self, msg, cause); }

  //////////////////////////////////////////////////////////////////////////
  // C# Constructors
  //////////////////////////////////////////////////////////////////////////

    public TestErr(Err.Val val) : base(val) {}
    public TestErr() : base(new TestErr.Val()) {}
    public TestErr(Exception actual) : base(new TestErr.Val(), actual) {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type type() { return Sys.TestErrType; }

  //////////////////////////////////////////////////////////////////////////
  // Val - C# Exception Type
  //////////////////////////////////////////////////////////////////////////

    public new class Val : Err.Val {}

  }
}
