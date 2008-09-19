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

    public new static ParseErr make(string msg)  { return make(Str.make(msg)); }

    public static ParseErr make(string type, string val)
    {
      return make(Str.make("Invalid " + type + ": '" + val + "'"));
    }

    public static ParseErr make(String type, Str val)
    {
      return make(Str.make("Invalid " + type + ": '" + val + "'"));
    }

    public static ParseErr make(string type, string val, object more)
    {
      return make(Str.make("Invalid " + type + ": '" + val + "': " + more));
    }

    public static ParseErr make(string type, Str val, object more)
    {
      return make(Str.make("Invalid " + type + ": '" + val + "': " + more));
    }

  //////////////////////////////////////////////////////////////////////////
  // Fan Constructors
  //////////////////////////////////////////////////////////////////////////

    public new static ParseErr make() { return make((Str)null, (Err)null); }
    public new static ParseErr make(Str msg) { return make(msg, null); }
    public new static ParseErr make(Str msg, Err cause)
    {
      ParseErr err = new ParseErr();
      make_(err, msg, cause);
      return err;
    }

    public static void make_(ParseErr self) { make_(self, null);  }
    public static void make_(ParseErr self, Str msg) { make_(self, msg, null); }
    public static void make_(ParseErr self, Str msg, Err cause) { Err.make_(self, msg, cause); }

  //////////////////////////////////////////////////////////////////////////
  // C# Constructors
  //////////////////////////////////////////////////////////////////////////

    public ParseErr(Err.Val val) : base(val) {}
    public ParseErr() : base(new ParseErr.Val()) {}
    public ParseErr(Exception actual) : base(new ParseErr.Val(), actual) {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type type() { return Sys.ParseErrType; }

  //////////////////////////////////////////////////////////////////////////
  // Val - C# Exception Type
  //////////////////////////////////////////////////////////////////////////

    public new class Val : Err.Val {}

  }
}
