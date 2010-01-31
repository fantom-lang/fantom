//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Jul 09  Brian Frank  Creation
//

using compiler

**
** EnvTest is used to define a new working dir which is used to
** compile new pods and then execute them in another process.
**
class EnvTest : Test
{

  File workHome := tempDir + `testenv/`
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
    dir := workHome + `$podA/`

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
    dir := workHome + `$podB/`

    // pod.fan
    podFile := (dir+`pod.fan`)
    podFile.out.print(
    """@podDepends=[Depend("sys 1.0"), Depend("util 1.0"), Depend("$podA 1.0")]
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
    """using util
       using $podA
       class TheTest : Test
       {
         // test env
         Void testEnv()
         {
           verifyEq(Env.cur.typeof, PathEnv#)
           env := (PathEnv)Env.cur
           verifyEq(env.path.size, 2)
           verifyEq(env.path[0].uri, `$workHome`)
           verifyEq(env.path[1].uri, `$Env.cur.homeDir`)
         }

         // test pods
         Void testPods()
         {
           pods := Pod.list
           verify(pods.contains(Pod.find("$podA")))
           verify(pods.contains(Pod.find("$podB")))
           verify(pods.contains(Pod.find("sys")))
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
             echo("-- EnvTest: \${m.name}...")
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
    verify((workHome + `lib/fan/${podName}.pod`).exists)
  }

  Void run(Str target)
  {
    isWindows := Env.cur.os == "win32"
    exeExt := isWindows ? ".exe" : ""
    fan := "fan" + exeExt
    p := Process([fan, target])
    p.env["FAN_ENV"]      = "util::PathEnv"
    p.env["FAN_ENV_PATH"] = workHome.uri.relToAuth.toStr
    status := p.run.join
    verifyEq(status, 0)
  }

}