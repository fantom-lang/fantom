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
class PodTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  Void testIdentity()
  {
    pod := type.pod
    verifyEq(pod.name,  "testSys")
    verifyEq(pod.toStr, "testSys")
    verifyEq(pod.uri,   `fan:/sys/pod/testSys/`)
    verifySame(pod.uri.get, pod)
  }

//////////////////////////////////////////////////////////////////////////
// Find
//////////////////////////////////////////////////////////////////////////

  Void testFind()
  {
    verifySame(Pod.find("sys"), Bool#.pod)
    verifySame(Pod.find("notHereFoo", false), null)
    verifyErr(UnknownPodErr#) |,| { Pod.find("notHereFoo") }
  }

//////////////////////////////////////////////////////////////////////////
// List
//////////////////////////////////////////////////////////////////////////

  Void testList()
  {
    pods := Pod.list
    verify(pods.isRO)
    verifyEq(pods.type, Pod[]#)
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

    testSys := Pod.find("testSys")
    verifyEq(testSys.name, "testSys")
    verifyEq(testSys.depends.size, 1)
    verifyEq(testSys.depends[0].name, "sys")
    verifyMeta(testSys)
  }

  Void verifyMeta(Pod pod)
  {
    if (false)
    {
      echo("verifyMeta")
      echo("  name    = $pod.name")
      echo("  version = $pod.version")
      echo("  depends = $pod.depends")
      echo("  facets  = $pod.facets")
    }

    verify(pod.version >= Version.fromStr("1.0.14"))
    verifyEq(pod.version.major, 1)
    verifyEq(pod.version.minor, 0)
    verify(pod.depends.isRO)
// TODO-SYM
//    verify(pod.facets["description"] != null)
    verifyEq(pod.facets.type, [Symbol:Obj?]#)
    verifyEq(pod.facets.findAll |v,s| { s.qname == "build::buildTime" }.size, 1)
  }

//////////////////////////////////////////////////////////////////////////
// Files
//////////////////////////////////////////////////////////////////////////

  Void testFiles()
  {
    files := type.pod.files
    verify(files.containsKey(`/locale/en.props`))
    verify(files.containsKey(`/locale/en-US.props`))
    verify(files.containsKey(`/locale/es.props`))
    verify(files.containsKey(`/locale/es-MX.props`))

    f := type.pod.files[`/res/test.txt`]
    verify(f != null)
    verifyEq(f.name, "test.txt")
    verifyEq(f.size, 19)
    verifyEq(f.readAllStr, "hello world\nline 2")
  }

//////////////////////////////////////////////////////////////////////////
// Log
//////////////////////////////////////////////////////////////////////////

  Void testLog()
  {
    verifyEq(type.pod.log.name, "testSys")
    verifySame(type.log, type.pod.log)
  }


}