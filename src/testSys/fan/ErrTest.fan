//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 May 06  Brian Frank  Creation
//

**
** ErrTest
**
class ErrTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Type
//////////////////////////////////////////////////////////////////////////

  Void testType()
  {
    err := Err.make
    verifySame(err.type, Err#)
    verifySame(err.type.base, Obj#)
    verifyEq(err.type.qname, "sys::Err")
    verify(err is Err)
    verify(err is Obj)
  }

//////////////////////////////////////////////////////////////////////////
// Trace
//////////////////////////////////////////////////////////////////////////

  Void a(Func f) { b(f) }
  Void b(Func f) { c(f) }
  Void c(Func f) { f() }

  Void testTrace()
  {
    Int line := #testTrace->lineNumber; line += 3 // next line
    verifyTrace(line++) |,| { throw Err.make("foo") }
    verifyTrace(line++) |,| { Obj x := 3; ((Str)x).size }
    verifyTrace(line++) |,| { Pod x := null; x.name }
    verifyTrace(line++) |,| { try { throw Err.make("cause") } catch (Err e) { throw Err.make("foo", e) } }
  }

  Void verifyTrace(Int line, Func f)
  {
    Err err
    try { a(f) } catch (Err e) { err = e }

    buf := Buf.make
    err.trace(buf.out)
    lines := buf.flip.readAllLines

    verifyEq(err.traceToStr, buf.seek(0).readAllStr)

    verifyEq(lines[0], err.toStr)
    verifyEq(lines[1], "  testSys::ErrTest.testTrace (ErrTest.fan:$line)")
    verifyEq(lines[2], "  testSys::ErrTest.c (ErrTest.fan:35)")
    verifyEq(lines[3], "  testSys::ErrTest.b (ErrTest.fan:34)")
    verifyEq(lines[4], "  testSys::ErrTest.a (ErrTest.fan:33)")

    if (err.cause != null)
    {
      causeStart := lines.index("Cause:")
      verifyEq(lines[causeStart+1], "  " + err.cause.toStr)
      verifyEq(lines[causeStart+2], "    testSys::ErrTest.testTrace (ErrTest.fan:$line)")
    }
  }

//////////////////////////////////////////////////////////////////////////
// Consturctors
//////////////////////////////////////////////////////////////////////////

  Void testCtor()
  {
    cause := Err.make

    err := Err.make
    verifyEq(err.message, null)
    verifyEq(err.cause, null)
    verifyEq(err.toStr, "sys::Err")

    err = Err.make("foo")
    verifyEq(err.message, "foo")
    verifyEq(err.cause, null)
    verifyEq(err.toStr, "sys::Err: foo")

    err = Err.make("foo", cause)
    verifyEq(err.message, "foo")
    verifySame(err.cause, cause)
    verifyEq(err.toStr, "sys::Err: foo")
  }

//////////////////////////////////////////////////////////////////////////
// All Sys Errs
//////////////////////////////////////////////////////////////////////////

  Void testAllSysErrs()
  {
    cause := Err.make
    Err err

    // ArgErr
    err = ArgErr.make("msg", cause)
    verifySame(err.type, ArgErr#)
    verifySame(err.type.base, Err#)
    verifyEq(err.type.qname, "sys::ArgErr")
    verify(err is ArgErr)
    verify(err is Err)
    verify(err is Obj)
    verify(err.message === "msg")
    verify(err.cause === cause)
    err = ArgErr.make
    verify(err.message === null)
    verify(err.cause === null)

    // CastErr
    err = CastErr.make("msg", cause)
    verifySame(err.type, CastErr#)
    verifySame(err.type.base, Err#)
    verifyEq(err.type.qname, "sys::CastErr")
    verify(err is CastErr)
    verify(err is Err)
    verify(err is Obj)
    verify(err.message === "msg")
    verify(err.cause === cause)
    err = CastErr.make
    verify(err.message === null)
    verify(err.cause === null)

    // IndexErr
    err = IndexErr.make("msg", cause)
    verifySame(err.type, IndexErr#)
    verifySame(err.type.base, Err#)
    verifyEq(err.type.qname, "sys::IndexErr")
    verify(err is IndexErr)
    verify(err is Err)
    verify(err is Obj)
    verify(err.message === "msg")
    verify(err.cause === cause)
    err = IndexErr.make
    verify(err.message === null)
    verify(err.cause === null)

    // IOErr
    err = IOErr.make("msg", cause)
    verifySame(err.type, IOErr#)
    verifySame(err.type.base, Err#)
    verifyEq(err.type.qname, "sys::IOErr")
    verify(err is IOErr)
    verify(err is Err)
    verify(err is Obj)
    verify(err.message === "msg")
    verify(err.cause === cause)
    err = IOErr.make
    verify(err.message === null)
    verify(err.cause === null)

    // NullErr
    err = NullErr.make("msg", cause)
    verifySame(err.type, NullErr#)
    verifySame(err.type.base, Err#)
    verifyEq(err.type.qname, "sys::NullErr")
    verify(err is NullErr)
    verify(err is Err)
    verify(err is Obj)
    verify(err.message === "msg")
    verify(err.cause === cause)
    err = NullErr.make
    verify(err.message === null)
    verify(err.cause === null)

    // ReadonlyErr
    err = ReadonlyErr.make("msg", cause)
    verifySame(err.type, ReadonlyErr#)
    verifySame(err.type.base, Err#)
    verifyEq(err.type.qname, "sys::ReadonlyErr")
    verify(err is ReadonlyErr)
    verify(err is Err)
    verify(err is Obj)
    verify(err.message === "msg")
    verify(err.cause === cause)
    err = ReadonlyErr.make
    verify(err.message === null)
    verify(err.cause === null)

    // UnknownPodErr
    err = UnknownPodErr.make("msg", cause)
    verifySame(err.type, UnknownPodErr#)
    verifySame(err.type.base, Err#)
    verifyEq(err.type.qname, "sys::UnknownPodErr")
    verify(err is UnknownPodErr)
    verify(err is Err)
    verify(err is Obj)
    verify(err.message === "msg")
    verify(err.cause === cause)
    err = UnknownPodErr.make
    verify(err.message === null)
    verify(err.cause === null)

    // UnknownSlotErr
    err = UnknownSlotErr.make("msg", cause)
    verifySame(err.type, UnknownSlotErr#)
    verifySame(err.type.base, Err#)
    verifyEq(err.type.qname, "sys::UnknownSlotErr")
    verify(err is UnknownSlotErr)
    verify(err is Err)
    verify(err is Obj)
    verify(err.message === "msg")
    verify(err.cause === cause)
    err = UnknownSlotErr.make
    verify(err.message === null)
    verify(err.cause === null)

    // UnknownTypeErr
    err = UnknownTypeErr.make("msg", cause)
    verifySame(err.type, UnknownTypeErr#)
    verifySame(err.type.base, Err#)
    verifyEq(err.type.qname, "sys::UnknownTypeErr")
    verify(err is UnknownTypeErr)
    verify(err is Err)
    verify(err is Obj)
    verify(err.message === "msg")
    verify(err.cause === cause)
    err = UnknownTypeErr.make
    verify(err.message === null)
    verify(err.cause === null)

    // UnsupportedErr
    err = UnsupportedErr.make("msg", cause)
    verifySame(err.type, UnsupportedErr#)
    verifySame(err.type.base, Err#)
    verifyEq(err.type.qname, "sys::UnsupportedErr")
    verify(err is UnsupportedErr)
    verify(err is Err)
    verify(err is Obj)
    verify(err.message === "msg")
    verify(err.cause === cause)
    err = UnsupportedErr.make
    verify(err.message === null)
    verify(err.cause === null)
  }

//////////////////////////////////////////////////////////////////////////
// Subclassing
//////////////////////////////////////////////////////////////////////////

  Void testSubclassing()
  {
    cause := Err.make

    // create TestOneErr with both params
    err := TestOneErr.make("msg", cause)
    verifySame(err.type, TestOneErr#)
    verifySame(err.type.base, Err#)
    verifyEq(err.type.qname, "testSys::TestOneErr")
    verify(err is TestOneErr)
    verify(err is Err)
    verify(err is Obj)
    verify(err.message === "msg")
    verify(err.cause === cause)
    verifyEq(err.r, -3f)

    // verify TestOneErr with 2 default params
    err = TestOneErr.make()
    verifySame(err.type, TestOneErr#)
    verify(err.message === null)
    verify(err.cause === null)

    // verify TestOneErr with 1 default params
    err = TestOneErr.make("foobar")
    verifySame(err.type, TestOneErr#)
    verify(err.message === "foobar")
    verify(err.cause === null)

    // verify TestTwoErr which subclasses from TestOneErr
    err2 := TestTwoErr.make()
    verifySame(err2.type, TestTwoErr#)
    verifySame(err2.type.base, TestOneErr#)
    verifySame(err2.type.base.base, Err#)
    verifyEq(err2.type.qname, "testSys::TestTwoErr")
    verify(err2 is TestTwoErr)
    verify(err2 is TestOneErr)
    verify(err is Err)
    verify(err is Obj)
    verifyEq(err2.r, -3f)
    verifyEq(err2.i, 77)
    verifyEq(err2.s, "hello world")

    // verify TestIOErr which subclasses from IOErr
    errIO := TestIOErr.make()
    verifySame(errIO.type, TestIOErr#)
    verifySame(errIO.type.base, IOErr#)
    verifySame(errIO.type.base.base, Err#)
    verifyEq(errIO.type.qname, "testSys::TestIOErr")
    verify(errIO is TestIOErr)
    verify(errIO is IOErr)
    verify(errIO is Err)
    verify(errIO is Obj)
    verifyEq(errIO.s, "memorial day")

    // verify throws works correctly
    verifyErr(TestOneErr#) |,| { throw TestOneErr.make }
    verifyErr(TestTwoErr#) |,| { throw TestTwoErr.make }
    verifyErr(TestIOErr#)  |,| { throw TestIOErr.make }
  }

}

//////////////////////////////////////////////////////////////////////////
// Supplemental classes
//////////////////////////////////////////////////////////////////////////

const class TestOneErr : Err
{
  new make(Str msg := null, Err cause := null) : super(msg, cause) {}
  const Float r := -3f
}

const class TestTwoErr : TestOneErr
{
  new make(Str msg := null, Err cause := null) : super(msg, cause) {}

  const Int i := 77
  const Str s := "hello world"
}

const class TestIOErr : IOErr
{
  new make(Str msg := null, Err cause := null) : super(msg, cause) {}

  const Str s := "memorial day"
}