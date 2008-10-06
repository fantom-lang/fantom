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

  public Type type()
  {
    return Sys.TestType;
  }

//////////////////////////////////////////////////////////////////////////
// Lifecycle
//////////////////////////////////////////////////////////////////////////

  public String id()
  {
    if (id == null)
    {
      String qname = type().qname();
      Integer n = (Integer)idMap.get(qname);
      if (n == null) n = Integer.valueOf(0);
      id = qname + n;
      idMap.put(qname, Integer.valueOf(n.intValue()+1));
    }
    return id;
  }

  public void setup() {}

  public void teardown() {}

//////////////////////////////////////////////////////////////////////////
// Verify
//////////////////////////////////////////////////////////////////////////

  public void verify(Boolean cond) { verify(cond, null); }
  public void verify(Boolean cond, String msg)
  {
    if (!cond) fail(msg);
    verifyCount++;
  }

  public void verifyFalse(Boolean cond) { verifyFalse(cond, null); }
  public void verifyFalse(Boolean cond, String msg)
  {
    if (cond) fail(msg);
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
      if (hash(expected).longValue() != hash(actual).longValue())
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
    if (!OpUtil.compareSame(expected, actual))
    {
      if (msg == null) msg = s(expected) + " !== " + s(actual);
      fail(msg);
    }
    verifyCount++;
  }

  public void verifyNotSame(Object expected, Object actual) { verifyNotSame(expected, actual, null); }
  public void verifyNotSame(Object expected, Object actual, String msg)
  {
    if (OpUtil.compareSame(expected, actual))
    {
      if (msg == null) msg = s(expected) + " === " + s(actual);
      fail(msg);
    }
    verifyCount++;
  }

  public void verifyErr(Type errType, Func f)
  {
    try
    {
      f.call0();
    }
    catch (Err.Val e)
    {
      if (verbose) System.out.println("  verifyErr: " + e);
      if (e.err().type() == errType) { verifyCount++; return; }
      fail(e.err().type() + " thrown, expected " + errType);
    }
    catch (Throwable e)
    {
      if (verbose) System.out.println("  verifyErr: " + e);
      Err err = Err.make(e);
      if (err.type() == errType) { verifyCount++; return; }
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
    return toStr(obj);
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  public File tempDir()
  {
    if (tempDir == null)
    {
      tempDir = Sys.appDir();
      tempDir.delete();
      tempDir.create();
    }
    return tempDir;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static final HashMap idMap = new HashMap(); // qname -> Integer

  public int verifyCount;
  public static boolean verbose;
  File tempDir;
  String id;

}
