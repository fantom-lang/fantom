//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Dec 08  Andy Frank  Creation
//

/**
 * Test is the base class of unit tests.
 */
var sys_Test = sys_Obj.extend(
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  _ctor: function() {},

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  verify: function(cond, msg)
  {
    if (!cond) this.fail(msg);
    this.verifyCount++;
  },

  verifyFalse: function(cond, msg)
  {
    if (cond) this.fail(msg);
    this.verifyCount++;
  },

  verifyEq: function(expected, actual, msg)
  {
    if (!sys_Obj.equals(expected, actual))
    {
      if (msg == null) msg = expected + " != " + actual;
      this.fail(msg);
    }
    /*
    if (expected != null && actual != null)
    {
      if (hash(expected) != hash(actual))
      {
        fail("Equal but different hash codes: " +
          expected + " (0x" + FanInt.toHex(hash(expected)) + ") ?= " +
          actual   + " (0x" + FanInt.toHex(hash(actual)) + ")");
      }
    }
    */
    this.verifyCount++;
  },

  verifyNotEq: function(expected, actual, msg)
  {
    if (sys_Obj.equals(expected, actual))
    {
      if (msg == null) msg = expected + " == " + actual;
      this.fail(msg);
    }
    this.verifyCount++;
  },

  verifySame: function(expected, actual, msg)
  {
    if (!sys_Obj.equals(expected, actual))
    {
      if (msg == null) msg = expected + " !== " + actual;
      this.fail(msg);
    }
    this.verifyCount++;
  },

  verifyNotSame: function(expected, actual, msg)
  {
    if (sys_Obj.equals(expected == actual))
    {
      if (msg == null) msg = expected + " === " + actual;
      this.fail(msg);
    }
    this.verifyCount++;
  },

  verifyErr: function(errType, f)
  {
    try
    {
      f();
    }
    catch (err)
    {
      var e = sys_Err.make(err);
      if (e.type() == errType) { this.verifyCount++; return; }
      //if (verbose) System.out.println("  verifyErr: " + e);
      println("  verifyErr: " + e);
      this.fail(e.type() + " thrown, expected " + errType);
    }
    this.fail("No err thrown, expected " + errType);
  },

  fail: function(msg)
  {
    throw this.err(msg);
  },

  err: function(msg)
  {
    if (msg == null)
      return new sys_Err("Test failed");
    else
      return new sys_Err("Test failed: " + msg);
  },

  type: function()
  {
    return sys_Type.find("sys::Test")
  },

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  verifyCount: 0,

});

function TestException(msg)
{
  this.message = msg;
  this.name = "TestException";
}

TestException.prototype.toString = function()
{
  return this.name + ": " + this.message;
}