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
// Obj Overrides
//////////////////////////////////////////////////////////////////////////

  public Type type()
  {
    return Sys.TestType;
  }

//////////////////////////////////////////////////////////////////////////
// Lifecycle
//////////////////////////////////////////////////////////////////////////

  public Str id()
  {
    if (id == null)
    {
      Str qname = type().qname();
      Integer n = (Integer)idMap.get(qname);
      if (n == null) n = Integer.valueOf(0);
      id = Str.make(qname.val + n);
      idMap.put(qname, Integer.valueOf(n.intValue()+1));
    }
    return id;
  }

  public void setup() {}

  public void teardown() {}

//////////////////////////////////////////////////////////////////////////
// Verify
//////////////////////////////////////////////////////////////////////////

  public void verify(Bool cond) { verify(cond, null); }
  public void verify(Bool cond, Str msg)
  {
    if (!cond.val) fail(msg);
    verifyCount++;
  }

  public void verifyFalse(Bool cond) { verifyFalse(cond, null); }
  public void verifyFalse(Bool cond, Str msg)
  {
    if (cond.val) fail(msg);
    verifyCount++;
  }

  public void verifyEq(Obj expected, Obj actual) { verifyEq(expected, actual, null); }
  public void verifyEq(Obj expected, Obj actual, Str msg)
  {
    if (!OpUtil.compareEQ(expected, actual).val)
    {
      if (msg == null) msg = Str.make(s(expected) + " != " + s(actual));
      fail(msg);
    }
    if (expected != null && actual != null)
    {
      if (expected.hash().val != actual.hash().val)
      {
        fail(Str.make("Equal but different hash codes: " +
          expected + " (0x" + expected.hash().toHex() + ") ?= " +
          actual   + " (0x" + actual.hash().toHex() + ")"));
      }
    }
    verifyCount++;
  }

  public void verifyNotEq(Obj expected, Obj actual) { verifyNotEq(expected, actual, null); }
  public void verifyNotEq(Obj expected, Obj actual, Str msg)
  {
    if (!OpUtil.compareNE(expected, actual).val)
    {
      if (msg == null) msg = Str.make(s(expected) + " == " + s(actual));
      fail(msg);
    }
    verifyCount++;
  }

  public void verifySame(Obj expected, Obj actual) { verifySame(expected, actual, null); }
  public void verifySame(Obj expected, Obj actual, Str msg)
  {
    if (!OpUtil.compareSame(expected, actual).val)
    {
      if (msg == null) msg = Str.make(s(expected) + " !== " + s(actual));
      fail(msg);
    }
    verifyCount++;
  }

  public void verifyNotSame(Obj expected, Obj actual) { verifyNotSame(expected, actual, null); }
  public void verifyNotSame(Obj expected, Obj actual, Str msg)
  {
    if (OpUtil.compareSame(expected, actual).val)
    {
      if (msg == null) msg = Str.make(s(expected) + " === " + s(actual));
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
      fail(Str.make(e.err().type() + " thrown, expected " + errType));
    }
    catch (Throwable e)
    {
      if (verbose) System.out.println("  verifyErr: " + e);
      Err err = Err.make(e);
      if (err.type() == errType) { verifyCount++; return; }
      fail(Str.make(e.toString() + " thrown, expected " + errType));
    }
    fail(Str.make("No err thrown, expected " + errType));
  }

  public void fail() { fail(null); }
  public void fail(Str msg)
  {
    throw err(msg);
  }

  private RuntimeException err(Str msg)
  {
    if (msg == null)
      return TestErr.make("Test failed").val;
    else
      return TestErr.make("Test failed: " + msg.val).val;
  }

  static String s(Obj obj)
  {
    if (obj == null) return "null";
    if (obj instanceof Str) return ((Str)obj).toCode().val;
    return obj.toStr().val;
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
  Str id;

}