//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Dec 08  Andy Frank  Creation
//

using [java] java.lang
using [java] javax.script

**
** TestRunner is the command line tool to run Fan unit tests
** against their Javascript implementations.
**
class TestRunner
{

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

  Void main()
  {
    if (Sys.args.size != 1)
    {
      help
      Sys.exit(-1)
    }

    // get args
    arg    := Sys.args.first
    pod    := arg
    type   := "*"
    method := "*"

    // check for type
    if (pod.contains("::"))
    {
      i := pod.index("::")
      type = pod[i+2..-1]
      pod  = pod[0..i-1]
    }

    // check for method
    if (type.contains("."))
    {
      i := type.index(".")
      method = type[i+1..-1]
      type   = type[0..i-1]
    }

    // create engine and eval pods
    p := Pod.find(pod)
    engine = ScriptEngineManager().getEngineByName("js");
    Runner.evalPodScript(engine, p)

    // run tests
    t1 := Duration.now
    if (type != "*")
    {
      runTests(Type.find("$pod::$type"), method)
    }
    else if (pod != null)
    {
      p.types.each |Type t| { if (t.fits(Test#)) runTests(t, "*") }
    }
    else throw Err("Pattern not supported: $arg")
    t2 := Duration.now

    echo("")
    echo("Time: ${(t2-t1).toMillis}ms")
    echo("")

    if (failureNames.size > 0)
    {
      echo("Failed:")
      failureNames.each |Str s| { echo("  $s") }
      echo("")
    }

    echo("***")
    echo("*** " +
      (failures == 0 ? "All tests passed!" : "$failures  FAILURES") +
      " [$testCount tests, $methodCount methods, $totalVerifyCount verifies]")
    echo("***")
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  Void runTests(Type type, Str methodName := "*")
  {
    echo("")
    methods := methods(type, methodName)
    methods.each |Method m|
    {
      echo("-- Run: ${m}...")
      verifyCount := runTest(m)
      if (verifyCount < 0)
      {
        failures++
        failureNames.add(m.qname)
      }
      else
      {
        echo("   Pass: $m  [$verifyCount]");
        methodCount++
        totalVerifyCount += verifyCount;
      }
      testCount++
    }
  }

  Method[] methods(Type type, Str methodName)
  {
    if (methodName != "*") return [type.method(methodName)]
    return type.methods.findAll |Method m->Bool|
    {
      return m.name.startsWith("test") && !m.isAbstract
    }
  }

  Int runTest(Method m)
  {
    try
    {
      // TODO - setup/teardown
      js  := m.parent.qname.replace("::", "_")
      ret := engine.eval(
       "var testRunner = function()
        {
          try
          {
            var test = new $js();
            test.$m.name();
            return test.verifyCount;
          }
          catch (err)
          {
            var file = err.fileName;   if (file == null) file = 'Unknown';
            var line = err.lineNumber; if (line == null) line = 'Unknown';
            println(err + ' (' + file + ':' + line + ')');
            return -1;
          }
        }
        testRunner();")
      return ret->toInt
    }
    catch (Err e)
    {
      echo("")
      echo("TEST FAILED")
      e.trace
      return -1
    }
  }

  Void help()
  {
    echo("Fan Test");
    echo("Usage:");
    //echo("  fant [options] -all");
    //echo("  fant [options] <pod> [pod]*");
    echo("  fant [options] <pod>");
    echo("  fant [options] <pod>::<test>");
    echo("  fant [options] <pod>::<test>.<method>");
    //echo("Note:");
    //echo("  You can use * to indicate wildcard for all pods");
    //echo("Options:");
    //echo("  -help, -h, -?  print usage help");
    //echo("  -version       print version");
    //echo("  -v             verbose mode");
    //echo("  -all           test all pods");
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  ScriptEngine engine
  Int testCount        := 0
  Int methodCount      := 0
  Int totalVerifyCount := 0
  Int failures         := 0
  Str[] failureNames   := [,]

}