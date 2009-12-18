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
    verifySame(Type.of(err), Err#)
    verifySame(Type.of(err).base, Obj#)
    verifyEq(Type.of(err).qname, "sys::Err")
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
    verifyTrace(line++) |->| { throw Err.make("foo") }
    verifyTrace(line++) |->| { Obj x := 3; ((Str)x).size }
    verifyTrace(line++) |->| { Pod? x := null; x.name }
    verifyTrace(line++) |->| { try { throw Err.make("cause") } catch (Err e) { throw Err.make("foo", e) } }
  }

  Void verifyTrace(Int line, Func f)
  {
    Err? err
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

  Void testTraceMaxDepth()
  {
    Err? err
    try { doThrow(30) } catch (Err e) { err = e }

    // default is 20
    buf := Buf()
    err.trace(buf.out)
    lines := buf.flip.readAllLines
    verifyEq(lines.size, 20+2) // toStr + More...
    verify(lines.last.contains("More"))

    // with maxDepth
    err.trace(buf.clear.out, ["maxDepth":4])
    lines = buf.flip.readAllLines
    verifyEq(lines.size, 4+2)
    verify(lines.last.contains("More"))

    // with maxDepth
    err.trace(buf.clear.out, ["maxDepth":Int.maxVal])
    lines = buf.flip.readAllLines
    verify(lines.size > 30)
  }

  Void doThrow(Int depth)
  {
    if (depth == 0) throw Err()
    doThrow(depth-1)
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
    cause := Err("cause")
    Err? err

    // ArgErr
    err = verifyErrType(ArgErr("msg", cause), ArgErr#, "sys::ArgErr")
    verify(err is ArgErr)
    verifyNull(ArgErr().message)

    // CastErr
    err = verifyErrType(CastErr("msg", cause), CastErr#, "sys::CastErr")
    verify(err is CastErr)
    verifyNull(CastErr().message)

    // CancelledErr
    err = verifyErrType(CancelledErr("msg", cause), CancelledErr#, "sys::CancelledErr")
    verify(err is CancelledErr)
    verifyNull(CancelledErr().message)

    // ConstErr
    err = verifyErrType(ConstErr("msg", cause), ConstErr#, "sys::ConstErr")
    verify(err is ConstErr)
    verifyNull(ConstErr().message)

    // IndexErr
    err = verifyErrType(IndexErr("msg", cause), IndexErr#, "sys::IndexErr")
    verify(err is IndexErr)
    verifyNull(IndexErr().message)

    // InterruptedErr
    err = verifyErrType(InterruptedErr("msg", cause), InterruptedErr#, "sys::InterruptedErr")
    verify(err is InterruptedErr)
    verifyNull(InterruptedErr().message)

    // IOErr
    err = verifyErrType(IOErr("msg", cause), IOErr#, "sys::IOErr")
    verify(err is IOErr)
    verifyNull(IOErr().message)

    // NotImmutableErr
    err = verifyErrType(NotImmutableErr("msg", cause), NotImmutableErr#, "sys::NotImmutableErr")
    verify(err is NotImmutableErr)
    verifyNull(NotImmutableErr().message)

    // NameErr
    err = verifyErrType(NameErr("msg", cause), NameErr#, "sys::NameErr")
    verify(err is NameErr)
    verifyNull(NameErr().message)

    // NullErr
    err = verifyErrType(NullErr("msg", cause), NullErr#, "sys::NullErr")
    verify(err is NullErr)
    verifyNull(NullErr().message)

    // ParseErr
    err = verifyErrType(ParseErr("msg", cause), ParseErr#, "sys::ParseErr")
    verify(err is ParseErr)
    verifyNull(ParseErr().message)

    // ReadonlyErr
    err = verifyErrType(ReadonlyErr("msg", cause), ReadonlyErr#, "sys::ReadonlyErr")
    verify(err is ReadonlyErr)
    verifyNull(ReadonlyErr().message)

    // TimeoutErr
    err = verifyErrType(TimeoutErr("msg", cause), TimeoutErr#, "sys::TimeoutErr")
    verify(err is TimeoutErr)
    verifyNull(TimeoutErr().message)

    // UnknownPodErr
    err = verifyErrType(UnknownPodErr("msg", cause), UnknownPodErr#, "sys::UnknownPodErr")
    verify(err is UnknownPodErr)
    verifyNull(UnknownPodErr().message)

    // UnknownSlotErr
    err = verifyErrType(UnknownSlotErr("msg", cause), UnknownSlotErr#, "sys::UnknownSlotErr")
    verify(err is UnknownSlotErr)
    verifyNull(UnknownSlotErr().message)

    // UnknownTypeErr
    err = verifyErrType(UnknownTypeErr("msg", cause), UnknownTypeErr#, "sys::UnknownTypeErr")
    verify(err is UnknownTypeErr)
    verifyNull(UnknownTypeErr().message)

    // UnsupportedErr
    err = verifyErrType(UnsupportedErr("msg", cause), UnsupportedErr#, "sys::UnsupportedErr")
    verify(err is UnsupportedErr)
    verifyNull(UnsupportedErr().message)
  }

  Err verifyErrType(Err err, Type t, Str qname)
  {
    verifySame(Type.of(err), t)
    verifyEq(Type.of(err).qname, qname)
    verifyEq(Type.of(err).base, Err#)
    verifyEq(Type.of(err).base.base, Obj#)
    verify(err is Err)
    verify(err is Obj)
    verifySame(err.message, "msg")
    verifySame(err.cause.message, "cause")
    return err
  }

//////////////////////////////////////////////////////////////////////////
// Subclassing
//////////////////////////////////////////////////////////////////////////

  Void testSubclassing()
  {
    cause := Err("cause")

    // create TestOneErr with both params
    err := TestOneErr("msg", cause)
    verifyErrType(err,TestOneErr#, "testSys::TestOneErr")
    verify(err is TestOneErr)
    verifyEq(err.r, -3f)

    // verify TestOneErr with 2 default params
    err = TestOneErr()
    verifySame(Type.of(err), TestOneErr#)
    verify(err.message === null)
    verify(err.cause === null)

    // verify TestOneErr with 1 default params
    err = TestOneErr.make("foobar")
    verifySame(Type.of(err), TestOneErr#)
    verify(err.message === "foobar")
    verify(err.cause === null)

    // verify TestTwoErr which subclasses from TestOneErr
    err2 := TestTwoErr.make()
    verifySame(Type.of(err2), TestTwoErr#)
    verifySame(Type.of(err2).base, TestOneErr#)
    verifySame(Type.of(err2).base.base, Err#)
    verifyEq(Type.of(err2).qname, "testSys::TestTwoErr")
    verify(err2 is TestTwoErr)
    verify(err2 is TestOneErr)
    verify(err is Err)
    verify(err is Obj)
    verifyEq(err2.r, -3f)
    verifyEq(err2.i, 77)
    verifyEq(err2.s, "hello world")

    // verify TestIOErr which subclasses from IOErr
    errIO := TestIOErr.make()
    verifySame(Type.of(errIO), TestIOErr#)
    verifySame(Type.of(errIO).base, IOErr#)
    verifySame(Type.of(errIO).base.base, Err#)
    verifyEq(Type.of(errIO).qname, "testSys::TestIOErr")
    verify(errIO is TestIOErr)
    verify(errIO is IOErr)
    verify(errIO is Err)
    verify(errIO is Obj)
    verifyEq(errIO.s, "memorial day")

    // verify throws works correctly
    verifyErr(TestOneErr#) { throw TestOneErr.make }
    verifyErr(TestTwoErr#) { throw TestTwoErr.make }
    verifyErr(TestIOErr#)  { throw TestIOErr.make }
    verifyErr(TestIOErr#)  { throw TestIOErr.make }
  }

}

//////////////////////////////////////////////////////////////////////////
// Supplemental classes
//////////////////////////////////////////////////////////////////////////

const class TestOneErr : Err
{
  new make(Str? msg := null, Err? cause := null) : super(msg, cause) {}
  const Float r := -3f
}

const class TestTwoErr : TestOneErr
{
  new make(Str? msg := null, Err? cause := null) : super(msg, cause) {}

  const Int i := 77
  const Str s := "hello world"
}

const class TestIOErr : IOErr
{
  new make(Str? msg := null, Err? cause := null) : super(msg, cause) {}

  const Str s := "memorial day"
}