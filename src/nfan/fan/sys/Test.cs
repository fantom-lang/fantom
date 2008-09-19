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

    public Str id()
    {
      if (m_id == null)
      {
        Str qname = type().qname();
        int n = 0;
        if (idMap[qname] != null) n = (int)idMap[qname];
        m_id = Str.make(qname.val + n);
        idMap[qname] = n+1;
      }
      return m_id;
    }

    public virtual void setup() {}

    public virtual void teardown() {}

  //////////////////////////////////////////////////////////////////////////
  // verify
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
        if (msg == null) msg = Str.make(expected + " != " + actual);
        fail(msg);
      }
      if (expected != null && actual != null)
      {
        if (expected.hash().val != actual.hash().val)
        {
          fail(Str.make("Equal but different hash codes: " + expected + " ?= " + actual));
        }
      }
      verifyCount++;
    }

    public void verifyNotEq(Obj expected, Obj actual) { verifyNotEq(expected, actual, null); }
    public void verifyNotEq(Obj expected, Obj actual, Str msg)
    {
      if (!OpUtil.compareNE(expected, actual).val)
      {
        if (msg == null) msg = Str.make(expected + " == " + actual);
        fail(msg);
      }
      verifyCount++;
    }

    public void verifySame(Obj expected, Obj actual) { verifySame(expected, actual, null); }
    public void verifySame(Obj expected, Obj actual, Str msg)
    {
      if (!OpUtil.compareSame(expected, actual).val)
      {
        if (msg == null) msg = Str.make(expected + " !== " + actual);
        fail(msg);
      }
      verifyCount++;
    }

    public void verifyNotSame(Obj expected, Obj actual) { verifyNotSame(expected, actual, null); }
    public void verifyNotSame(Obj expected, Obj actual, Str msg)
    {
      if (OpUtil.compareSame(expected, actual).val)
      {
        if (msg == null) msg = Str.make(expected + " === " + actual);
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
        fail(Str.make(e.err().type() + " thrown, expected " + errType));
      }
      catch (System.Exception e)
      {
        if (verbose) System.Console.WriteLine("  verifyErr: " + e);
        Err err = Fan.Sys.Err.make(e);
        if (err.type() == errType) { verifyCount++; return; }
        fail(Str.make(e.GetType() + " thrown, expected " + errType));
      }
      fail(Str.make("No err thrown, expected " + errType));
    }

    public void fail() { fail(null); }
    public void fail(Str msg)
    {
      throw err(msg);
    }

    private Exception err(Str msg)
    {
      if (msg == null)
        return Fan.Sys.TestErr.make("Test failed").val;
      else
        return Fan.Sys.TestErr.make("Test failed: " + msg.val).val;
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
    Str m_id = null;

  }
}
