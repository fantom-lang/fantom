//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Dec 2008  Andy Frank  Creation
//   20 May 2009  Andy Frank  Refactor to new OO model
//   17 Apr 2023  Andy Frank  Refactor to ES
//

/**
 * Test is the base class of unit tests.
 */
class Test extends Obj {

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  constructor() { 
    super(); 
    this.#verifyCount = 0;
  }

  #verifyCount;
  #tempDir;

  static make$(self) { }

  verifyCount$() { return this.#verifyCount; }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  verify(cond, msg=null) {
    if (!cond) this.fail(msg);
    this.#verifyCount++;
  }

  verifyTrue(cond, msg=null) {
    return this.verify(cond, msg);
  }

  verifyFalse(cond, msg=null) {
    if (cond) this.fail(msg);
    this.#verifyCount++;
  }

  verifyNull(a, msg=null) {
    if (a != null) {
      if (msg == null) msg = ObjUtil.toStr(a) + " is not null";
      this.fail(msg);
    }
    this.#verifyCount++;
  }

  verifyNotNull(a, msg=null) {
    if (a == null) {
      if (msg == null) msg = ObjUtil.toStr(a) + " is null";
      this.fail(msg);
    }
    this.#verifyCount++;
  }

  verifyEq(expected, actual, msg=null) {
    if (!ObjUtil.equals(expected, actual)) {
      if (msg == null) msg = ObjUtil.toStr(expected) + " != " + ObjUtil.toStr(actual);
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
    this.#verifyCount++;
  }

  verifyNotEq(expected, actual, msg=null)
  {
    if (ObjUtil.equals(expected, actual)) {
      if (msg == null) msg = ObjUtil.toStr(expected) + " == " + ObjUtil.toStr(actual);
      this.fail(msg);
    }
    this.#verifyCount++;
  }

  verifySame(expected, actual, msg=null) {
    if (!ObjUtil.same(expected, actual)) {
      if (msg == null) msg = ObjUtil.toStr(expected) + " [" + expected.typeof$() + "] != " + ObjUtil.toStr(actual) + " [" + actual.typeof$() + "]";
      this.fail(msg);
    }
    this.#verifyCount++;
  }

  verifyNotSame(expected, actual, msg=null) {
    if (ObjUtil.same(expected, actual)) {
      if (msg == null) msg = ObjUtil.toStr(expected) + " === " + ObjUtil.toStr(actual);
      this.fail(msg);
    }
    this.#verifyCount++;
  }

  verifyType(obj, t) {
    this.verifyEq(Type.of(obj), t);
  }

  verifyErr(errType, func) {
    try
    {
      func();
    }
    catch (err)
    {
      const e = Err.make(err);
      if (e.typeof$() == errType || errType == null) { this.#verifyCount++; return; }
      //if (verbose) System.out.print("  verifyErr: " + e + "\n");
      console.log("  verifyErr: " + e + "\n");
      this.fail(e.typeof$() + " thrown, expected " + errType);
    }
    this.fail("No err thrown, expected " + errType);
  }

  verifyErrMsg(errType, errMsg, func) {
    try
    {
      func();
    }
    catch (err)
    {
      const e = Err.make(err);
      if (e.typeof$() != errType) {
        print("  verifyErrMsg: " + e + "\n");
        this.fail(e.typeof$() + " thrown, expected " + errType);
      }
      this.#verifyCount++;
      this.verifyEq(errMsg, e.msg());
      return;
    }
    this.fail("No err thrown, expected " + errType);
  }

  fail(msg=null) {
    throw this.#err(msg);
  }

  #err(msg=null) {
    if (msg == null)
      return Err.make("Test failed");
    else
      return Err.make("Test failed: " + msg);
  }

  setup() {}

  teardown() {}

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

//fan.sys.Test.prototype.trap(String name, List args)

  tempDir() {
    if (this.#tempDir == null && Env.__isNode()) {
      const x = Env.cur().tempDir();
      this.#tempDir = x.plus(Uri.fromStr("test/"), false);
      this.#tempDir.delete$();
      this.#tempDir.create();
    }
    return this.#tempDir;
  }

//////////////////////////////////////////////////////////////////////////
// TestException: TODO:FIXIT can i remove this code 
//////////////////////////////////////////////////////////////////////////

/*
function TestException(msg)
{
  this.mge = msg;
  this.name = "TestException";
}

TestException.prototype.toString = function()
{
  return this.name + ": " + this.msg;
}
*/
}