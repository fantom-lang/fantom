//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Jul 09  Brian Frank  Creation
//

using compiler

**
** RepoTest is used to define a new repo which is used to compile
** new pods and then execute them in another process.
**
class RepoTest : Test
{

  File repoHome := tempDir + `testrepo/`
  File outFile  := tempDir + `test-output.txt`
  Str podA := "testAx" + Int.random(0..0xffff).toHex.upper
  Str podB := "testBx" + Int.random(0..0xffff).toHex.upper

//////////////////////////////////////////////////////////////////////////
// Test
//////////////////////////////////////////////////////////////////////////

  Void test()
  {
    genPodA
    genPodB
    run("$podB::TheTest")
    verifyOutFile
  }

//////////////////////////////////////////////////////////////////////////
// PodA
//////////////////////////////////////////////////////////////////////////

  Void genPodA()
  {
    dir := repoHome + `$podA/`

    // pod.fan
    podFile := (dir+`pod.fan`)
    podFile.out.print(
    """@podDepends=[Depend("sys 1.0")]
       @podSrcDirs=[`fan/`]
       @podIndexFacets=[@foo]
       pod $podA
       {
         foo := ""
       }""").close

    // build.fan
    buildFile := dir+`build.fan`
    buildFile.out.print(
    """class Build : build::BuildPod
       {
         override Void setup() { podName = "$podA" }
       }""").close

    // src.fan
    srcFile := dir+`fan/src.fan`
    srcFile.out.print(
    """@foo="alpha"
       class A
       {
         static Str a() { return "a" }
       }""").close

    compile(podA, buildFile)
  }

//////////////////////////////////////////////////////////////////////////
// PodB
//////////////////////////////////////////////////////////////////////////

  Void genPodB()
  {
    dir := repoHome + `$podB/`

    // pod.fan
    podFile := (dir+`pod.fan`)
    podFile.out.print(
    """@podDepends=[Depend("sys 1.0"), Depend("$podA 1.0")]
       @podSrcDirs=[`fan/`]
       pod $podB {}""").close

    // build.fan
    buildFile := dir+`build.fan`
    buildFile.out.print(
    """class Build : build::BuildPod
       {
         override Void setup() { podName = "$podB" }
       }""").close

    // src.fan
    srcFile := dir+`fan/src.fan`
    srcFile.out.print(
    """using $podA
       class TheTest : Test
       {
         // test repos
         Void testRepos()
         {
           verifyEq(Repo.list.size, 2)
           verifySame(Repo.list[0], Repo.working)
           verifySame(Repo.list[1], Repo.boot)
           verifyEq(Repo.working.name, "working")
           verifyEq(Repo.working.home.uri, `$repoHome`)
           verifyEq(Repo.boot.name, "boot")
           verifyEq(Repo.boot.home.uri, `$Repo.boot.home`)
         }

         // test pods
         Void testPods()
         {
           verifySame(Pod.find("$podA").repo, Repo.working)
           verifySame(Pod.find("$podB").repo, Repo.working)
           verifySame(Pod.find("sys").repo,   Repo.boot)
           pods := Pod.list
           verify(pods.containsSame(Pod.find("$podA")))
           verify(pods.containsSame(Pod.find("$podB")))
           verify(pods.containsSame(Pod.find("sys")))
         }

         // test facets
         Void testFacets()
         {
           verifyEq(A#.facet(@foo), "alpha")
           verifyEq(B#.facet(@foo), "beta")
           verifyEq(Type.findByFacet(@foo, "alpha"),[A#])
           verifyEq(Type.findByFacet(@foo, "beta"), [B#])
           verifyEq(Type.findByFacet(@foo, "????"), Type[,])
         }

         static Void main()
         {
           out := File($outFile.uri.toCode).out
           t := TheTest()
           TheTest#.methods.each |m|
           {
             if (m.isStatic || m.isCtor || m.parent != TheTest#) return
             echo("-- RepoTest: \${m.name}...")
             try
             {
               m.callOn(t, [,])
               out.printLine("\$m.name pass")
             }
             catch (Err e)
             {
               e.trace
               out.printLine("\$m.name fail \$e")
             }
           }
           out.close
         }
       }

       @foo="beta"
       class B {}
       """).close

    compile(podB, buildFile)
  }

//////////////////////////////////////////////////////////////////////////
// Verify Out File
//////////////////////////////////////////////////////////////////////////

  Void verifyOutFile()
  {
    lines := outFile.readAllLines
    verify(lines.size > 0)
    lines.each |line| { verify(line.endsWith("pass"), line) }
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  Void compile(Str podName, File buildFile)
  {
    run(buildFile.osPath)
    verify((repoHome + `lib/fan/${podName}.pod`).exists)
  }

  Void run(Str target)
  {
    isWindows := Sys.env.get("os.name", "?").lower.contains("win")
    exeExt := isWindows ? ".exe" : ""
    fan := "fan" + exeExt
    p := Process([fan, target])
    p.env["FAN_REPO"] = repoHome.uri.relToAuth.toStr
    status := p.run.join
    verifyEq(status, 0)
  }

}