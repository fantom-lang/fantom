//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Dec 06  Andy Frank  Creation
//

using System;
using System.Collections;
using Fanx.Util;

namespace Fan.Sys
{
  /// <summary>
  /// Test is the base class of unit tests.
  /// </summary>
  public class Test : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructors
  //////////////////////////////////////////////////////////////////////////

    public static void make_(Test t) {}

  //////////////////////////////////////////////////////////////////////////
  // Obj Overrides
  //////////////////////////////////////////////////////////////////////////

    public override Type type()
    {
      return Sys.TestType;
    }

  //////////////////////////////////////////////////////////////////////////
  // Lifecycle
  //////////////////////////////////////////////////////////////////////////

    public string id()
    {
      if (m_id == null)
      {
        string qname = type().qname();
        int n = 0;
        if (idMap[qname] != null) n = (int)idMap[qname];
        m_id = qname + n;
        idMap[qname] = n+1;
      }
      return m_id;
    }

    public virtual void setup() {}

    public virtual void teardown() {}

  //////////////////////////////////////////////////////////////////////////
  // verify
  //////////////////////////////////////////////////////////////////////////

    public void verify(Boolean cond) { verify(cond, null); }
    public void verify(Boolean cond, string msg)
    {
      if (!cond.booleanValue()) fail(msg);
      verifyCount++;
    }

    public void verifyFalse(Boolean cond) { verifyFalse(cond, null); }
    public void verifyFalse(Boolean cond, string msg)
    {
      if (cond.booleanValue()) fail(msg);
      verifyCount++;
    }

    public void verifyEq(object expected, object actual) { verifyEq(expected, actual, null); }
    public void verifyEq(object expected, object actual, string msg)
    {
      if (!OpUtil.compareEQ(expected, actual).booleanValue())
      {
        //if (msg == null) msg = s(expected) + " != " + s(actual);
        if (msg == null) msg = s(expected) +
          " [" + (expected != null ? expected.GetType().ToString() : "null") + "] != "
          + s(actual) + " [" + (actual != null ? actual.GetType().ToString() : "null") + "]";
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

    public void verifyNotEq(object expected, object actual) { verifyNotEq(expected, actual, null); }
    public void verifyNotEq(object expected, object actual, string msg)
    {
      if (!OpUtil.compareNE(expected, actual).booleanValue())
      {
        if (msg == null) msg = s(expected) + " == " + s(actual);
        fail(msg);
      }
      verifyCount++;
    }

    public void verifySame(object expected, object actual) { verifySame(expected, actual, null); }
    public void verifySame(object expected, object actual, string msg)
    {
      if (!OpUtil.compareSame(expected, actual).booleanValue())
      {
        if (msg == null) msg = s(expected) + " !== " + s(actual);
        fail(msg);
      }
      verifyCount++;
    }

    public void verifyNotSame(object expected, object actual) { verifyNotSame(expected, actual, null); }
    public void verifyNotSame(object expected, object actual, string msg)
    {
      if (OpUtil.compareSame(expected, actual).booleanValue())
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
        if (verbose) System.Console.WriteLine("  verifyErr: " + e);
        if (e.err().type() == errType) { verifyCount++; return; }
        fail(e.err().type() + " thrown, expected " + errType);
      }
      catch (System.Exception e)
      {
        if (verbose) System.Console.WriteLine("  verifyErr: " + e);
        Err err = Fan.Sys.Err.make(e);
        if (err.type() == errType) { verifyCount++; return; }
        fail(e.GetType() + " thrown, expected " + errType);
      }
      fail("No err thrown, expected " + errType);
    }

    public void fail() { fail(null); }
    public void fail(string msg)
    {
      throw err(msg);
    }

    private Exception err(string msg)
    {
      if (msg == null)
        return Fan.Sys.TestErr.make("Test failed").val;
      else
        return Fan.Sys.TestErr.make("Test failed: " + msg).val;
    }

    private static string s(object obj)
    {
      if (obj == null) return "null";
      if (obj is string) return FanStr.toCode((string)obj);
      if (obj is List) return ((List)obj).of().ToString() + obj;
      return toStr(obj);
    }

  //////////////////////////////////////////////////////////////////////////
  // Utils
  //////////////////////////////////////////////////////////////////////////

    public File tempDir()
    {
      if (m_tempDir == null)
      {
        m_tempDir = Sys.appDir();
        m_tempDir.delete();
        m_tempDir.create();
      }
      return m_tempDir;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal static readonly Hashtable idMap = new Hashtable(); // qname -> Integer

    public int verifyCount;
    public static bool verbose;
    File m_tempDir = null;
    string m_id = null;

  }
}