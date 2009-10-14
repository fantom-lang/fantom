//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Jan 06  Brian Frank  Creation
//

**
** Test is the base for Fan unit tests.
**
abstract class Test
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** Protected constructor.
  **
  protected new make()

//////////////////////////////////////////////////////////////////////////
// Lifecycle
//////////////////////////////////////////////////////////////////////////

  **
  ** Get a unique id for this run of the test method.  This id is
  ** guaranteed to be unique for the life of the VM.
  **
  Str id()

  **
  ** Setup is called before running each test method.
  **
  virtual Void setup()

  **
  ** Teardown is called after running every test method.
  **
  virtual Void teardown()

//////////////////////////////////////////////////////////////////////////
// Verify
//////////////////////////////////////////////////////////////////////////

  **
  ** Verify that cond is true, otherwise throw a test
  ** failure exception.  If msg is non-null, include it
  ** in a failure exception.
  **
  Void verify(Bool cond, Str? msg := null)

  **
  ** Verify that cond is false, otherwise throw a test
  ** failure exception.  If msg is non-null, include it
  ** in a failure exception.
  **
  Void verifyFalse(Bool cond, Str? msg := null)

  **
  ** Verify that a is null, otherwise throw a test failure
  ** exception.  If msg is non-null, include it in a failure
  ** exception.
  **
  Void verifyNull(Obj? a, Str? msg := null)

  **
  ** Verify that a is not null, otherwise throw a test failure
  ** exception.  If msg is non-null, include it in a failure
  ** exception.
  **
  Void verifyNotNull(Obj? a, Str? msg := null)

  **
  ** Verify that a == b, otherwise throw a test failure exception.
  ** If both a and b are nonnull, then this method also ensures
  ** that a.hash == b.hash, because any two objects which return
  ** true for equals() must also return the same hash code.  If
  ** msg is non-null, include it in failure exception.
  **
  Void verifyEq(Obj? a, Obj? b, Str? msg := null)

  **
  ** Verify that a != b, otherwise throw a test failure exception.
  ** If msg is non-null, include it in failure exception.
  **
  Void verifyNotEq(Obj? a, Obj? b, Str? msg := null)

  **
  ** Verify that a === b, otherwise throw a test failure exception.
  ** If msg is non-null, include it in failure exception.
  **
  Void verifySame(Obj? a, Obj? b, Str? msg := null)

  **
  ** Verify that a !== b, otherwise throw a test* failure exception.
  ** If msg is non-null, include it in failure exception.
  **
  Void verifyNotSame(Obj? a, Obj? b, Str? msg := null)

  **
  ** Verify that the function throws an Err of the
  ** exact same type as err (compare using === operator).
  **
  ** Examples:
  **   verifyErr(ParseErr#) { Int.fromStr("@#!") }
  **
  Void verifyErr(Type errType, |This| c)

  **
  ** Throw a test failure exception.  If msg is non-null, include
  ** it in the failure exception.
  **
  Void fail(Str? msg := null)

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  **
  ** Return a temporary test directory which may used as a scratch
  ** directory.  This directory is guaranteed to be created and empty
  ** the first time this method is called for a given test run.  The
  ** test directory is "{Repo.working}/tmp/test/".
  **
  File tempDir()

}

**************************************************************************
** TestErr
**************************************************************************

internal const class TestErr : Err
{
  new make(Str? msg := null, Err? cause := null)
}