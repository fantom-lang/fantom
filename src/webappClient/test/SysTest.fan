//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Mar 09  Andy Frank  Creation
//

**
** SysTest
**
internal class SysTest : Test
{
  override Void setup()
  {
    try
    {
      // recompile testSys and force javascript compilation
      script   := Sys.homeDir + `src/testSys/build.fan`
      compiler := Type.find("compilerJavascript::Main").make
      Int r := compiler->run(script.uri, true)
      if (r != 0) throw Err("Cannot compile javascript for testSys")
    }
    catch (Err err)
    {
      fail("Failed to recompile testSys")
      err.trace
    }
  }

  //Void test() { doTest }
  internal Void doTest(Str tp := "*", Str mp := "*")
  {
    pod := Pod.find("testSys")
    runner := Type.find("compilerJavascript::TestRunner").make
    runner->evalPod(Pod.find("webappClient"))
    runner->evalPod(pod)
    if (tp == "*")
    {
      pod.types.each |Type t| { runner->runTests(t) }
    }
    else
    {
      runner->runTests(pod.findType(tp), mp)
    }
    runner->results
    if (runner->failureNames->size > 0) fail
  }

  Void main()
  {
    arg  := Sys.args.first
    type := arg ?: "*"
    meth := "*"
    if (type.contains("."))
    {
      i := type.index(".")
      meth = type[i+1..-1]
      type = type[0..i-1]
    }
    test := SysTest()
    test.setup
    test.doTest(type, meth)
  }
}