//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Jan 06  Brian Frank  Creation
//
package fan.sys;

/**
 * IndexErr
 */
public class IndexErr
  extends Err
{

//////////////////////////////////////////////////////////////////////////
// Java Convenience
//////////////////////////////////////////////////////////////////////////

  public static IndexErr make(long index)   { return make(String.valueOf(index)); }
  public static IndexErr make(Range index) { return make(String.valueOf(index)); }

//////////////////////////////////////////////////////////////////////////
// Fantom Constructors
//////////////////////////////////////////////////////////////////////////

  public static IndexErr make() { return make("", (Err)null); }
  public static IndexErr make(String msg) { return make(msg, (Err)null); }
  public static IndexErr make(String msg, Err cause)
  {
    IndexErr err = new IndexErr();
    make$(err, msg, cause);
    return err;
  }

  public static void make$(IndexErr self) { make$(self, null);  }
  public static void make$(IndexErr self, String msg) { make$(self, msg, null); }
  public static void make$(IndexErr self, String msg, Err cause) { Err.make$(self, msg, cause); }

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  public IndexErr() {}
  public IndexErr(Throwable actual) { super(actual); }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.IndexErrType; }

}