//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Jan 06  Brian Frank  Creation
//
package fan.sys;

import java.util.*;
import fanx.util.*;

/**
 * Test is the base class of unit tests.
 */
public class Test
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  public static void make$(Test t) {}

//////////////////////////////////////////////////////////////////////////
// Object Overrides
//////////////////////////////////////////////////////////////////////////

  public Type typeof()
  {
    return Sys.TestType;
  }

//////////////////////////////////////////////////////////////////////////
// Lifecycle
//////////////////////////////////////////////////////////////////////////

  public Method curTestMethod()
  {
    if (curTestMethod == null)
      throw Err.make("No test currently executing for " + typeof());
    return curTestMethod;
  }

  public void setup() {}

  public void teardown() {}

//////////////////////////////////////////////////////////////////////////
// Verify
//////////////////////////////////////////////////////////////////////////

  public void verify(boolean cond) { verify(cond, null); }
  public void verify(boolean cond, String msg)
  {
    if (!cond) fail(msg);
    verifyCount++;
  }

  public void verifyTrue(boolean cond) { verify(cond, null); }
  public void verifyTrue(boolean cond, String msg) { verify(cond, msg); }

  public void verifyFalse(boolean cond) { verifyFalse(cond, null); }
  public void verifyFalse(boolean cond, String msg)
  {
    if (cond) fail(msg);
    verifyCount++;
  }

  public void verifyNull(Object a) { verifyNull(a, null); }
  public void verifyNull(Object a, String msg)
  {
    if (a != null)
    {
      if (msg == null) msg = s(a) + " is not null";
      fail(msg);
    }
    verifyCount++;
  }

  public void verifyNotNull(Object a) { verifyNotNull(a, null); }
  public void verifyNotNull(Object a, String msg)
  {
    if (a == null)
    {
      if (msg == null) msg = "is null";
      fail(msg);
    }
    verifyCount++;
  }

  public void verifyEq(Object a, Object b) { verifyEq(a, b, null); }
  public void verifyEq(Object a, Object b, String msg)
  {
    if (!OpUtil.compareEQ(a, b))
    {
      // if we have two multi-line strings display line in error
      if (a instanceof String && b instanceof String)
      {
        List aLines = FanStr.splitLines((String)a);
        List bLines = FanStr.splitLines((String)b);
        if (aLines.sz() > 1 || bLines.sz() > 1)
        {
          if (aLines.sz() != bLines.sz())
          {
            msg = "Num lines: " + aLines.sz() + " != " + bLines.sz();
          }
          else
          {
            for (int i=0; i<aLines.sz(); ++i)
            {
              if (!aLines.get(i).equals(bLines.get(i)))
              {
                msg = "Line " + (i+1) + ": " + FanStr.toCode((String)aLines.get(i)) + " != " + FanStr.toCode((String)bLines.get(i));
                break;
              }
            }
          }
        }
      }

      if (msg == null) msg = s(a) + " != " + s(b);
      fail(msg);
    }
    if (a != null && b != null)
    {
      if (hash(a) != hash(b))
      {
        fail("Equal but different hash codes: " +
          a + " (0x" + FanInt.toHex(hash(a)) + ") ?= " +
          b + " (0x" + FanInt.toHex(hash(b)) + ")");
      }
    }
    verifyCount++;
  }

  public void verifyNotEq(Object a, Object b) { verifyNotEq(a, b, null); }
  public void verifyNotEq(Object a, Object b, String msg)
  {
    if (!OpUtil.compareNE(a, b))
    {
      if (msg == null) msg = s(a) + " == " + s(b);
      fail(msg);
    }
    verifyCount++;
  }

  public void verifySame(Object a, Object b) { verifySame(a, b, null); }
  public void verifySame(Object a, Object b, String msg)
  {
    if (a != b)
    {
      if (msg == null) msg = s(a) + " !== " + s(b);
      fail(msg);
    }
    verifyCount++;
  }

  public void verifyNotSame(Object a, Object b) { verifyNotSame(a, b, null); }
  public void verifyNotSame(Object a, Object b, String msg)
  {
    if (a == b)
    {
      if (msg == null) msg = s(a) + " === " + s(b);
      fail(msg);
    }
    verifyCount++;
  }

  public void verifyType(Object obj, Type t)
  {
    verifyEq(Type.of(obj), t);
  }

  public void verifyErr(Type errType, Func f)
  {
    try
    {
      f.call(this);
    }
    catch (Err e)
    {
      if (verbose) System.out.println("   verifyErr: " + e);
      if (e.typeof() == errType || errType == null) { verifyCount++; return; }
      fail(e.typeof() + " thrown, expected " + errType);
    }
    catch (Throwable e)
    {
      if (verbose) System.out.println("   verifyErr: " + e);
      Err err = Err.make(e);
      if (err.typeof() == errType || errType == null) { verifyCount++; return; }
      fail(e.toString() + " thrown, expected " + errType);
    }
    fail("No err thrown, expected " + errType);
  }

  public void verifyErrMsg(Type errType, String errMsg, Func f)
  {
    try
    {
      f.call(this);
    }
    catch (Err e)
    {
      if (verbose) System.out.println("  verifyErrMsg: " + e);
      if (e.typeof() != errType) {
        fail(e.typeof() + " thrown, expected " + errType);
      }
      verifyCount++;
      verifyEq(errMsg, e.msg());
      return;
    }
    catch (Throwable e)
    {
      if (verbose) System.out.println("  verifyErrMsg: " + e);
      Err err = Err.make(e);
      if (err.typeof() != errType) {
        fail(e.toString() + " thrown, expected " + errType);
      }
      verifyCount++;
      verifyEq(errMsg, err.msg());
      return;
    }
    fail("No err thrown, expected " + errType);
  }

  public void fail() { fail(null); }
  public void fail(String msg)
  {
    throw err(msg);
  }

  private RuntimeException err(String msg)
  {
    if (msg == null)
      return TestErr.make("Test failed");
    else
      return TestErr.make("Test failed: " + msg);
  }

  static String s(Object obj)
  {
    if (obj == null) return "null";
    if (obj instanceof String) return FanStr.toCode((String)obj) + " [sys::Str]";
    if (obj instanceof List) return ((List)obj).of().toString() + obj;
    return toStr(obj) + " [" + FanObj.typeof(obj) + "]";
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  public Object trap(String name, List args)
  {
    if (name.equals("verifyCount")) return Long.valueOf(verifyCount);
    if (name.equals("verbose"))
    {
      if (args != null && args.sz() == 1)
      {
        verbose = ((Boolean)args.get(0)).booleanValue();
      }
      return Boolean.valueOf(verbose);
    }

    if (name.equals("curTestMethod") && args != null && args.sz() == 1)
      this.curTestMethod = (Method) args.get(0);

    return super.trap(name, args);
  }

  public File tempDir()
  {
    if (tempDir == null)
    {
      tempDir = Env.cur().tempDir().plus(Uri.fromStr("test/"), false);
      tempDir.delete();
      tempDir.create();
    }
    return tempDir;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public int verifyCount;
  public static boolean verbose;
  public Method curTestMethod;
  File tempDir;

}

