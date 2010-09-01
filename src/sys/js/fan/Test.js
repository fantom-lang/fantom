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
fan.sys.Test = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Test.prototype.$ctor = function()
{
  this.verifyCount = 0;
}

fan.sys.Test.make$ = function(self)
{
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Test.prototype.verify = function(cond, msg)
{
  if (!cond) this.fail(msg);
  this.verifyCount++;
}

fan.sys.Test.prototype.verifyFalse = function(cond, msg)
{
  if (cond) this.fail(msg);
  this.verifyCount++;
}

fan.sys.Test.prototype.verifyNull = function(a, msg)
{
  if (msg === undefined) msg = null;
  if (a != null)
  {
    if (msg == null) msg = fan.sys.ObjUtil.toStr(a) + " is not null";
    this.fail(msg);
  }
  this.verifyCount++;
}

fan.sys.Test.prototype.verifyNotNull = function(a, msg)
{
  if (msg === undefined) msg = null;
  if (a == null)
  {
    if (msg == null) msg = fan.sys.ObjUtil.toStr(a) + " is null";
    this.fail(msg);
  }
  this.verifyCount++;
}

fan.sys.Test.prototype.verifyEq = function(expected, actual, msg)
{
  if (!fan.sys.ObjUtil.equals(expected, actual))
  {
    if (msg == null) msg = fan.sys.ObjUtil.toStr(expected) + " != " + fan.sys.ObjUtil.toStr(actual);
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

fan.sys.Test.prototype.verifyNotEq = function(expected, actual, msg)
{
  if (fan.sys.ObjUtil.equals(expected, actual))
  {
    if (msg == null) msg = fan.sys.ObjUtil.toStr(expected) + " == " + fan.sys.ObjUtil.toStr(actual);
    this.fail(msg);
  }
  this.verifyCount++;
}

fan.sys.Test.prototype.verifySame = function(expected, actual, msg)
{
  if (!fan.sys.ObjUtil.equals(expected, actual))
  {
    if (msg == null) msg = fan.sys.ObjUtil.toStr(expected) + " !== " + fan.sys.ObjUtil.toStr(actual);
    this.fail(msg);
  }
  this.verifyCount++;
}

fan.sys.Test.prototype.verifyNotSame = function(expected, actual, msg)
{
  if (fan.sys.ObjUtil.equals(expected == actual))
  {
    if (msg == null) msg = fan.sys.ObjUtil.toStr(expected) + " === " + fan.sys.ObjUtil.toStr(actual);
    this.fail(msg);
  }
  this.verifyCount++;
}

fan.sys.Test.prototype.verifyType = function(obj, t)
{
  this.verifyEq(fan.sys.Type.of(obj), t);
}

fan.sys.Test.prototype.verifyErr = function(errType, func)
{
  try
  {
    func.call();
  }
  catch (err)
  {
    var e = fan.sys.Err.make(err);
    if (e.$typeof() == errType) { this.verifyCount++; return; }
    //if (verbose) System.out.println("  verifyErr: " + e);
    println("  verifyErr: " + e);
    this.fail(e.$typeof() + " thrown, expected " + errType);
  }
  this.fail("No err thrown, expected " + errType);
}

fan.sys.Test.prototype.fail = function(msg)
{
  throw this.err(msg);
}

fan.sys.Test.prototype.err = function(msg)
{
  if (msg == null)
    return fan.sys.Err.make("Test failed");
  else
    return fan.sys.Err.make("Test failed: " + msg);
}

fan.sys.Test.prototype.$typeof = function()
{
  return fan.sys.Test.$type;
}

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

//fan.sys.Test.prototype.trap(String name, List args)

fan.sys.Test.prototype.tempDir = function()
{
  if (this.m_tempDir == null && fan.sys.Env.$rhino)
  {
    var x = fan.sys.Env.cur().tempDir();
    this.m_tempDir = x.plus(fan.sys.Uri.fromStr("test/"), false);
    this.m_tempDir.$delete();
    this.m_tempDir.create();
  }
  return this.m_tempDir;
}

//////////////////////////////////////////////////////////////////////////
// TestException
//////////////////////////////////////////////////////////////////////////

function TestException(msg)
{
  this.mge = msg;
  this.name = "TestException";
}

TestException.prototype.toString = function()
{
  return this.name + ": " + this.msg;
}