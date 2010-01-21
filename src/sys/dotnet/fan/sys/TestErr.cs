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
  // Fantom Constructors
  //////////////////////////////////////////////////////////////////////////

    public new static TestErr make() { return make("", (Err)null); }
    public new static TestErr make(string msg) { return make(msg, (Err)null); }
    public new static TestErr make(string msg, Err cause)
    {
      TestErr err = new TestErr();
      make_(err, msg, cause);
      return err;
    }

    public static void make_(TestErr self) { make_(self, null);  }
    public static void make_(TestErr self, string msg) { make_(self, msg, null); }
    public static void make_(TestErr self, string msg, Err cause) { Err.make_(self, msg, cause); }

  //////////////////////////////////////////////////////////////////////////
  // C# Constructors
  //////////////////////////////////////////////////////////////////////////

    public TestErr(Err.Val val) : base(val) {}
    public TestErr() : base(new TestErr.Val()) {}
    public TestErr(Exception actual) : base(new TestErr.Val(), actual) {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.TestErrType; }

  //////////////////////////////////////////////////////////////////////////
  // Val - C# Exception Type
  //////////////////////////////////////////////////////////////////////////

    public new class Val : Err.Val {}

  }
}