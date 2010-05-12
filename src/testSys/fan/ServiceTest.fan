//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jan 07  Brian Frank  Creation
//   26 Mar 09  Brian Frank  Split from old ThreadTest
//

using concurrent

**
** ServiceTest
**
class ServiceTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Lifecycle
//////////////////////////////////////////////////////////////////////////

  Void testLifecycle()
  {
    s := TestServiceB()

    // initial state
    verifyEq(s.isInstalled, false)
    verifyEq(s.isRunning, false)
    verifyEq(Actor.locals["TestServiceB"], null)
    verifyService(TestServiceB#, null)

    // install
    verifySame(s.install, s)
    verifySame(s.install, s)
    verifyEq(s.isInstalled, true)
    verifyEq(s.isRunning, false)
    verifyEq(Actor.locals["TestServiceB"], null)
    verifyService(TestServiceB#, s)

    // start
    verifySame(s.start, s)
    verifySame(s.start, s)
    verifyEq(s.isInstalled, true)
    verifyEq(s.isRunning, true)
    verifyEq(Actor.locals["TestServiceB"], "onStart")
    verifyService(TestServiceB#, s)

    // stop
    verifySame(s.stop, s)
    verifySame(s.stop, s)
    verifyEq(s.isInstalled, true)
    verifyEq(s.isRunning, false)
    verifyEq(Actor.locals["TestServiceB"], "onStop")
    verifyService(TestServiceB#, s)

    // uninstall
    verifySame(s.uninstall, s)
    verifySame(s.uninstall, s)
    verifyEq(s.isInstalled, false)
    verifyEq(s.isRunning, false)
    verifyEq(Actor.locals["TestServiceB"], "onStop")
    verifyService(TestServiceB#, null)

    // stop doesn't hurt anything after until
    verifySame(s.stop, s)
    verifyEq(s.isInstalled, false)
    verifyEq(s.isRunning, false)
    verifyEq(Actor.locals["TestServiceB"], "onStop")
    verifyService(TestServiceB#, null)

    // start implies
    verifySame(s.start, s)
    verifyEq(s.isInstalled, true)
    verifyEq(s.isRunning, true)
    verifyEq(Actor.locals["TestServiceB"], "onStart")
    verifyService(TestServiceB#, s)

    // uninstall implies stop
    verifySame(s.uninstall, s)
    verifyEq(s.isInstalled, false)
    verifyEq(s.isRunning, false)
    verifyEq(Actor.locals["TestServiceB"], "onStop")
    verifyService(TestServiceB#, null)
  }

//////////////////////////////////////////////////////////////////////////
// Registry
//////////////////////////////////////////////////////////////////////////

  Void testRegistry()
  {
    a  := TestServiceA()
    b  := TestServiceB()
    a2 := TestServiceA()
    b2 := TestServiceB()

    // starting state
    verifyService(ServiceTest#,  null)
    verifyService(TestServiceM#, null)
    verifyService(TestServiceA#, null)
    verifyService(TestServiceB#, null)

    // install a
    verifySame(a.install, a)
    verifyService(ServiceTest#,  null)
    verifyService(TestServiceM#, a)
    verifyService(TestServiceA#, a)
    verifyService(TestServiceB#, null)

    // install a again
    verifySame(a.install, a)
    verifyService(ServiceTest#,  null)
    verifyService(TestServiceM#, a)
    verifyService(TestServiceA#, a)
    verifyService(TestServiceB#, null)

    // uninstall a
    verifySame(a.uninstall, a)
    verifyService(ServiceTest#,  null)
    verifyService(TestServiceM#, null)
    verifyService(TestServiceA#, null)
    verifyService(TestServiceB#, null)

    // re-install a
    verifySame(a.install, a)
    verifyService(ServiceTest#,  null)
    verifyService(TestServiceM#, a)
    verifyService(TestServiceA#, a)
    verifyService(TestServiceB#, null)

    // install b
    verifySame(b.install, b)
    verifyService(ServiceTest#,  null)
    verifyService(TestServiceM#, a)
    verifyService(TestServiceA#, a)
    verifyService(TestServiceB#, b)

    // install b2
    verifySame(b2.install, b2)
    verifyService(ServiceTest#,  null)
    verifyService(TestServiceM#, a)
    verifyService(TestServiceA#, a)
    verifyService(TestServiceB#, b)
    verify(Service.findAll(TestServiceM#).contains(b2))
    verify(Service.findAll(TestServiceA#).contains(b2))
    verify(Service.findAll(TestServiceB#).contains(b2))

    // install a2
    verifySame(a2.install, a2)
    verifyService(ServiceTest#,  null)
    verifyService(TestServiceM#, a)
    verifyService(TestServiceA#, a)
    verifyService(TestServiceB#, b)
    verify(Service.findAll(TestServiceM#).contains(a2))
    verify(Service.findAll(TestServiceA#).contains(a2))

    // uninstall b
    verifySame(b.uninstall, b)
    verifySame(b.uninstall, b)
    verifyService(ServiceTest#,  null)
    verifyService(TestServiceM#, a)
    verifyService(TestServiceA#, a)
    verifyService(TestServiceB#, b2)

    // uninstall a
    verifySame(a.uninstall, a)
    verifyService(ServiceTest#,  null)
    verifyService(TestServiceM#, b2)
    verifyService(TestServiceA#, b2)
    verifyService(TestServiceB#, b2)

    // uninstall b2
    verifySame(b2.uninstall, b2)
    verifyService(ServiceTest#,  null)
    verifyService(TestServiceM#, a2)
    verifyService(TestServiceA#, a2)
    verifyService(TestServiceB#, null)

    // uninstall a2
    verifySame(a2.uninstall, a2)
    verifyService(ServiceTest#,  null)
    verifyService(TestServiceM#, null)
    verifyService(TestServiceA#, null)
    verifyService(TestServiceB#, null)
  }

  Void verifyService(Type t, Service? s)
  {
    uri := "/sys/service/$t.qname".toUri
    if (s == null)
    {
      verifyEq(Service.find(t, false), null)
      verifyErr(UnknownServiceErr#) { Service.find(t) }
      verifyErr(UnknownServiceErr#) { Service.find(t, true) }
    }
    else
    {
      verify(Service.list.contains(s))
      verify(Service.findAll(t).contains(s))
      verifySame(Service.find(t), s)
      verifySame(Service.find(t, false), s)
      verifySame(Service.find(t, true), s)
    }
  }

}

**************************************************************************
** TestServices
**************************************************************************

mixin TestServiceM {}
const class TestServiceA : TestServiceM, Service {}
const class TestServiceB : TestServiceA
{
  protected override Void onStart() { Actor.locals["TestServiceB"] = "onStart" }
  protected override Void onStop()  { Actor.locals["TestServiceB"] = "onStop" }
}