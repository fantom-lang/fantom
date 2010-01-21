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
  /// ParseErr.
  /// </summary>
  public class ParseErr : Err
  {

  //////////////////////////////////////////////////////////////////////////
  // C# Convenience
  //////////////////////////////////////////////////////////////////////////

    public static ParseErr make(string type, string val)
    {
      return make("Invalid " + type + ": '" + val + "'");
    }

    public static ParseErr make(string type, string val, object more)
    {
      return make("Invalid " + type + ": '" + val + "': " + more);
    }

  //////////////////////////////////////////////////////////////////////////
  // Fantom Constructors
  //////////////////////////////////////////////////////////////////////////

    public new static ParseErr make() { return make("", (Err)null); }
    public new static ParseErr make(string msg) { return make(msg, (Err)null); }
    public new static ParseErr make(string msg, Err cause)
    {
      ParseErr err = new ParseErr();
      make_(err, msg, cause);
      return err;
    }

    public static void make_(ParseErr self) { make_(self, null);  }
    public static void make_(ParseErr self, string msg) { make_(self, msg, null); }
    public static void make_(ParseErr self, string msg, Err cause) { Err.make_(self, msg, cause); }

  //////////////////////////////////////////////////////////////////////////
  // C# Constructors
  //////////////////////////////////////////////////////////////////////////

    public ParseErr(Err.Val val) : base(val) {}
    public ParseErr() : base(new ParseErr.Val()) {}
    public ParseErr(Exception actual) : base(new ParseErr.Val(), actual) {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.ParseErrType; }

  //////////////////////////////////////////////////////////////////////////
  // Val - C# Exception Type
  //////////////////////////////////////////////////////////////////////////

    public new class Val : Err.Val {}

  }
}