//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jan 07  Brian Frank  Creation
//   26 Mar 09  Brian Frank  Split from old ThreadTest
//

**
** ServiceTest
**
class ServiceTest : Test
{

  Void testService()
  {
    a  := TestServiceA()
    b  := TestServiceB()
    a2 := TestServiceA()
    b2 := TestServiceB()

    // start
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
    verify(Service.findAll(TestServiceM#).containsSame(b2))
    verify(Service.findAll(TestServiceA#).containsSame(b2))
    verify(Service.findAll(TestServiceB#).containsSame(b2))

    // install a2
    verifySame(a2.install, a2)
    verifyService(ServiceTest#,  null)
    verifyService(TestServiceM#, a)
    verifyService(TestServiceA#, a)
    verifyService(TestServiceB#, b)
    verify(Service.findAll(TestServiceM#).containsSame(a2))
    verify(Service.findAll(TestServiceA#).containsSame(a2))

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
      verifyErr(UnknownServiceErr#) |,| { Service.find(t) }
      verifyErr(UnknownServiceErr#) |,| { Service.find(t, true) }

/* TODO
      verifyEq(Sys.ns.get(uri, false), null)
      verifyErr(UnresolvedErr#) |,| { Sys.ns.get(uri) }
      verifyErr(UnresolvedErr#) |,| { Sys.ns.get(uri, true) }
*/
    }
    else
    {
      verify(Service.list.containsSame(s))
      verify(Service.findAll(t).containsSame(s))
      verifySame(Service.find(t), s)
      verifySame(Service.find(t, false), s)
      verifySame(Service.find(t, true), s)

/* TODO
      verifySame(Sys.ns[uri], s)
      verifySame(Sys.ns.get(uri, false), s)
      verifySame(Sys.ns.get(uri, true), s)
*/
    }
  }

}

**************************************************************************
** TestServices
**************************************************************************

mixin TestServiceM {}
const class TestServiceA : TestServiceM, Service {}
const class TestServiceB : TestServiceA {}