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
      throw Err.make("No test currently executing for " + typeof()).val;
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

  public void verifyEq(Object expected, Object actual) { verifyEq(expected, actual, null); }
  public void verifyEq(Object expected, Object actual, String msg)
  {
    if (!OpUtil.compareEQ(expected, actual))
    {
      if (msg == null) msg = s(expected) + " != " + s(actual);
      fail(msg);
    }
    if (expected != null && actual != null)
    {
      if (hash(expected) != hash(actual))
      {
        fail("Equal but different hash codes: " +
          expected + " (0x" + FanInt.toHex(hash(expected)) + ") ?= " +
          actual   + " (0x" + FanInt.toHex(hash(actual)) + ")");
      }
    }
    verifyCount++;
  }

  public void verifyNotEq(Object expected, Object actual) { verifyNotEq(expected, actual, null); }
  public void verifyNotEq(Object expected, Object actual, String msg)
  {
    if (!OpUtil.compareNE(expected, actual))
    {
      if (msg == null) msg = s(expected) + " == " + s(actual);
      fail(msg);
    }
    verifyCount++;
  }

  public void verifySame(Object expected, Object actual) { verifySame(expected, actual, null); }
  public void verifySame(Object expected, Object actual, String msg)
  {
    if (expected != actual)
    {
      if (msg == null) msg = s(expected) + " !== " + s(actual);
      fail(msg);
    }
    verifyCount++;
  }

  public void verifyNotSame(Object expected, Object actual) { verifyNotSame(expected, actual, null); }
  public void verifyNotSame(Object expected, Object actual, String msg)
  {
    if (expected == actual)
    {
      if (msg == null) msg = s(expected) + " === " + s(actual);
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
    catch (Err.Val e)
    {
      if (verbose) System.out.println("  verifyErr: " + e);
      if (e.err().typeof() == errType) { verifyCount++; return; }
      fail(e.err().typeof() + " thrown, expected " + errType);
    }
    catch (Throwable e)
    {
      if (verbose) System.out.println("  verifyErr: " + e);
      Err err = Err.make(e);
      if (err.typeof() == errType) { verifyCount++; return; }
      fail(e.toString() + " thrown, expected " + errType);
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
      return TestErr.make("Test failed").val;
    else
      return TestErr.make("Test failed: " + msg).val;
  }

  static String s(Object obj)
  {
    if (obj == null) return "null";
    if (obj instanceof String) return FanStr.toCode((String)obj);
    if (obj instanceof List) return ((List)obj).of().toString() + obj;
    return toStr(obj);
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  public Object trap(String name, List args)
  {
    if (name.equals("verifyCount")) return Long.valueOf(verifyCount);
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