//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Mar 06  Brian Frank  Creation
//

**
** PodTest
**
@Js
class PodTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  Void testIdentity()
  {
    pod := Pod.of(this)
    verifyEq(pod.name,  "testSys")
    verifyEq(pod.toStr, "testSys")
    verifyEq(pod.uri,   `fan://testSys`)
    verifySame(pod.uri.get, pod)
    verifySame(pod, Type.of(this).pod)
  }

//////////////////////////////////////////////////////////////////////////
// Find
//////////////////////////////////////////////////////////////////////////

  Void testFind()
  {
    verifySame(Pod.find("sys"), Bool#.pod)
    verifySame(Pod.find("notHereFoo", false), null)
    verifyErr(UnknownPodErr#) { Pod.find("notHereFoo") }
  }

//////////////////////////////////////////////////////////////////////////
// List
//////////////////////////////////////////////////////////////////////////

  Void testList()
  {
    pods := Pod.list
    verify(pods.isRO)
    verifyType(pods, Pod[]#)
    verify(pods.contains(Pod.find("sys")))
    verify(pods.contains(Pod.find("testSys")))
  }

//////////////////////////////////////////////////////////////////////////
// Meta
//////////////////////////////////////////////////////////////////////////

  Void testMeta()
  {
    sys := Pod.find("sys")
    verifyEq(sys.name, "sys")
    verifyEq(sys.depends.size, 0)
    verifyEq(sys.meta["pod.docApi"], "true")
    verifyEq(sys.meta["pod.docSrc"], "true")
    verifyMeta(sys)

    testSys := Pod.find("testSys")
    verifyEq(testSys.meta["testSys.foo"], "got\n it \u0123")
    verifyEq(testSys.meta["pod.docApi"], "false")
    verifyEq(testSys.meta["pod.docSrc"], "false")
    verifyEq(testSys.name, "testSys")
    verifyEq(testSys.depends.size, 2)
    verifyEq(testSys.depends[0].name, "sys")
    verifyEq(testSys.depends[1].name, "concurrent")
    verifyMeta(testSys)
  }

  Void verifyMeta(Pod pod)
  {
    verify(pod.version >= Version.fromStr("1.0.14"))
    verifyEq(pod.version.major, 1)
    verifyEq(pod.version.minor, 0)

    verify(pod.depends.isImmutable)
    verifyEq(pod.depends.typeof, Depend[]#)

    verify(pod.meta.isImmutable)
    verifyEq(pod.meta.typeof, Str:Str#)

    verifyEq(pod.meta["pod.name"], pod.name)
    verifyEq(pod.meta["pod.version"], pod.version.toStr)
    verify(pod.meta.containsKey("pod.depends"))
    verify(pod.meta.containsKey("build.host"))
    verify(pod.meta.containsKey("build.user"))
    verify(pod.meta.containsKey("build.time"))
  }

//////////////////////////////////////////////////////////////////////////
// Files
//////////////////////////////////////////////////////////////////////////

  Void testFiles()
  {
    pod := typeof.pod
    verifyEq(pod.files.isImmutable, true)
    verifySame(pod.files, pod.files)

    f := pod.file(`/locale/en.props`)
    verifyEq(f.uri, `fan://testSys/locale/en.props`)
    verifySame(f, pod.files.find {it.name=="en.props"})

    f = pod.file(`fan://testSys/res/test.txt`)
    verifyEq(f.uri, `fan://testSys/res/test.txt`)
    verifyEq(f.name, "test.txt")
    verifyEq(f.size, 19)
    verifyEq(f.readAllStr, "hello world\nline 2")

    verifyErr(ArgErr#) { pod.file(`res/test.txt`) }
    verifyErr(ArgErr#) { pod.file(`fan://foo/res/test.txt`) }
    verifyErr(ArgErr#) { pod.file(`//testSys/res/test.txt`) }

    verifyNull(pod.file(`fan://testSys/bad/file`, false))
    verifyErr(UnresolvedErr#) { pod.file(`fan://testSys/bad/file`) }
    verifyErr(UnresolvedErr#) { pod.file(`fan://testSys/bad/file`, true) }
  }

//////////////////////////////////////////////////////////////////////////
// Log
//////////////////////////////////////////////////////////////////////////

  Void testLog()
  {
    verifyEq(Pod.of(this).log.name, "testSys")
  }

//////////////////////////////////////////////////////////////////////////
// Props
//////////////////////////////////////////////////////////////////////////

  Void testProps()
  {
    pod := typeof.pod
    verifyEq(pod.props(`res/podtest.props`, 1ms)["barney"], "stinson")
    verifyEq(pod.props(`res/podtest.props`, 1ms).isImmutable, true)

    verifyEq(pod.props(`not/found`, 1ms).size, 0)
    verifyEq(pod.props(`not/found`, 1ms).isImmutable, true)

    verifySame(pod.props(`res/podtest.props`, 1ms), pod.props(`res/podtest.props`, 1ms))
    verifySame(pod.props(`not/found`, 1ms), pod.props(`not/found`, 1ms))
  }

}