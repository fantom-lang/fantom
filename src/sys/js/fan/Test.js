//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Dec 08  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Test is the base class of unit tests.
 */
var sys_Test = sys_Obj.$extend(sys_Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

sys_Test.prototype.$ctor = function()
{
  this.verifyCount = 0;
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

sys_Test.prototype.verify = function(cond, msg)
{
  if (!cond) this.fail(msg);
  this.verifyCount++;
}

sys_Test.prototype.verifyFalse = function(cond, msg)
{
  if (cond) this.fail(msg);
  this.verifyCount++;
}

sys_Test.prototype.verifyEq = function(expected, actual, msg)
{
  if (!sys_Obj.equals(expected, actual))
  {
    if (msg == null) msg = sys_Obj.toStr(expected) + " != " + sys_Obj.toStr(actual);
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
}

sys_Test.prototype.verifyNotEq = function(expected, actual, msg)
{
  if (sys_Obj.equals(expected, actual))
  {
    if (msg == null) msg = sys_Obj.toStr(expected) + " == " + sys_Obj.toStr(actual);
    this.fail(msg);
  }
  this.verifyCount++;
}

sys_Test.prototype.verifySame = function(expected, actual, msg)
{
  if (!sys_Obj.equals(expected, actual))
  {
    if (msg == null) msg = sys_Obj.toStr(expected) + " !== " + sys_Obj.toStr(actual);
    this.fail(msg);
  }
  this.verifyCount++;
}

sys_Test.prototype.verifyNotSame = function(expected, actual, msg)
{
  if (sys_Obj.equals(expected == actual))
  {
    if (msg == null) msg = sys_Obj.toStr(expected) + " === " + sys_Obj.toStr(actual);
    this.fail(msg);
  }
  this.verifyCount++;
}

sys_Test.prototype.verifyErr = function(errType, f)
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
}

sys_Test.prototype.fail = function(msg)
{
  throw this.err(msg);
}

sys_Test.prototype.err = function(msg)
{
  if (msg == null)
    return new sys_Err("Test failed");
  else
    return new sys_Err("Test failed: " + msg);
}

sys_Test.prototype.type = function()
{
  return sys_Type.find("sys::Test")
}

//////////////////////////////////////////////////////////////////////////
// TestException
//////////////////////////////////////////////////////////////////////////

function TestException(msg)
{
  this.message = msg;
  this.name = "TestException";
}

TestException.prototype.toString = function()
{
  return this.name + ": " + this.message;
}