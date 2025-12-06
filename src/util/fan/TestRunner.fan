//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Jun 24  Brian Frank  Creation
//

**
** TestRunner executes `sys::Test` classes and reports success/failure.
**
@Js
class TestRunner
{

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

  ** Run with given command line arguments
  static Int main(Str[] args)
  {
    targets := Str[,]
    runner  := TestRunner()
    isAll   := false
    isJs    := false
    isEs    := false

    // parse args
    for (i:=0; i<args.size; ++i)
    {
      arg := args[i]
      if (arg == "-help" || arg == "-h" || arg == "-?")
      {
        runner.printUsage
        return -1
      }
      if (arg == "-version")
      {
        runner.printVersion
        return -1
      }
      if (arg == "-v")
      {
        runner.isVerbose = true
        continue
      }
      if (arg == "-all")
      {
        isAll = true
        continue
      }
      if (arg == "-es")
      {
        isEs = true
        continue
      }
      if (arg == "-js")
      {
        isJs = true
        continue
      }
      if (arg.startsWith("-"))
      {
        echo("WARNING: Unknown option: $arg")
        continue
      }
      targets.add(arg)
    }

    // handle js/es re-routing
    if (isEs) return runner.runEs(targets)
    if (isJs) return runner.runJs(targets)

    // run tests
    if (isAll)
    {
      runner.runAll
    }
    else
    {
      if (targets.isEmpty)
      {
        runner.printUsage
        return -1
      }
      runner.runTargets(targets)
    }

    // report sumary and return non-zero if we had failures
    runner.reportSummary
    return runner.numFailures
  }

  ** Print usage
  Void printUsage()
  {
    out.printLine
    out.printLine(
     """Fantom Test Runner
        Usage:
          fant [options] <target>*
        Target:
          <pod>
          <pod>::<Type>
          <pod>::<Type>.<method>
        Options:
          -help, -h, -?  print usage help
          -version       print version
          -v             verbose mode
          -all           test all pods
          -es            test new ECMA JavaScript environment
          -js            test legacy JavaScript environment
        """)
  }

  ** Print version
  Void printVersion()
  {
    out.printLine
    out.printLine(
     """Fantom Test Runner
        Copyright (c) 2006-$Date.today.year, Brian Frank and Andy Frank
        Licensed under the Academic Free License version 3.0

        fan.version:  $typeof.pod.version
        fan.runtime:  $Env.cur.runtime
        fan.platform: $Env.cur.platform
        """)
     out.printLine("Env path:")
     Env.cur.path.each |f| { out.printLine("  $f.osPath") }
     out.printLine
  }

  ** Run new ECMA JS code
  private Int runEs(Str[] targets)
  {
    args := Str[,].add("test").addAll(targets)
    type := Type.find("nodeJs::Main")
    return type.make->main(args)
  }

  ** Run legacy JS code
  private Int runJs(Str[] targets)
  {
    args := Str[,].add("-test").addAll(targets)
    type := Type.find("compilerJs::NodeRunner")
    return type.make->main(args)
  }

//////////////////////////////////////////////////////////////////////////
// Runs
//////////////////////////////////////////////////////////////////////////

  ** Run list of targets from an argument string
  virtual This runTargets(Str[] targets)
  {
    targets.each |target, i|
    {
      if (i > 0) out.printLine
      runTarget(target)
    }
    return this
  }

  ** Run target from an argument string
  virtual This runTarget(Str target)
  {
    // pod
    colons := target.index("::")
    if (colons == null) return runPod(Pod.find(target))

    // pod::Type
    podName := target[0..<colons]
    pod := Pod.find(podName)
    rest := target[colons+2..-1]
    dot := rest.index(".")
    if (dot == null) return runType(pod.type(rest))

    // pod::Type.method
    typeName := rest[0..<dot]
    methodName := rest[dot+1..-1]
    type := pod.type(typeName)
    method := type.method(methodName)
    return runMethod(type, method)
  }

  ** Run on every installed pod
  virtual This runAll()
  {
    Pod.list.each |pod| { doRunPod(pod, true) }
    return this
  }

  ** Run all tests in given pod
  virtual This runPod(Pod pod) { doRunPod(pod, false) }
  private This doRunPod(Pod pod, Bool blankLine)
  {
    types := Type[,]
    pod.types.dup.sort.each |type|
    {
      if (type.fits(Test#) && !type.isAbstract) types.add(type)
    }
    if (types.isEmpty) return this

    if (blankLine) out.printLine
    types.each |type| { runType(type) }

    return this
  }

  ** Run all test methods on a given type
  virtual This runType(Type type)
  {
    numTypes++
    type.methods.each |method|
    {
      if (method.name.startsWith("test") && !method.isAbstract)
        runMethod(type, method)
    }
    return this
  }

  ** Run test method
  virtual This runMethod(Type type, Method method)
  {
    reportStart(type, method)
    Test? test := null
    verifies := 0
    try
    {
      test = type.make
      test->curTestMethod = method
      test->verbose = isVerbose
      onSetup(test)
      method.callOn(test, [,])
      verifies = (Int)test->verifyCount
      reportSuccess(type, method, verifies)
    }
    catch (Err e)
    {
      if (test != null) verifies = test->verifyCount
      failures.add(qname(type, method))
      reportFailure(type, method, e)
    }
    finally
    {
      try
      {
        if (test != null) onTeardown(test)
      }
      catch (Err e)  e.trace
    }
    numMethods += 1
    numVerifies += verifies
    return this
  }

  ** Callback to invoke setup
  virtual Void onSetup(Test test) { test.setup }

  ** Callback to invoke teardown
  virtual Void onTeardown(Test test) { test.teardown }

//////////////////////////////////////////////////////////////////////////
// Reporting
//////////////////////////////////////////////////////////////////////////

  ** Report the start of a test method
  virtual Void reportStart(Type type, Method method)
  {
    out.printLine("-- Run: ${qname(type, method)}")
  }

  ** Report the success and number of verifies
  virtual Void reportSuccess(Type type, Method method, Int verifies)
  {
    out.printLine("   Pass: ${qname(type, method)} [$verifies]")
  }

  ** Report the failure and exception raised
  virtual Void reportFailure(Type type, Method method, Err err)
  {
    out.printLine
    out.printLine("TEST FAILED")
    err.trace(out)
  }

  ** Report summary of tests
  virtual Void reportSummary()
  {
    elapsed := Duration.now - startTicks
    elapsedStr := elapsed > 10sec ? elapsed.toLocale : "${elapsed.toMillis}ms"

    out.printLine
    out.printLine("Time: $elapsedStr")
    out.printLine

    summary := "All tests passed!"
    if (!failures.isEmpty)
    {
      summary = "$failures.size FAILURES"
      out.printLine("Failed:")
      failures.each |qname| { out.printLine("  $qname") }
      out.printLine
    }

    out.printLine("***")
    out.printLine("*** $summary [$numTypes types, $numMethods methods, $numVerifies verifies]")
    out.printLine("***")
  }

  ** Qualified name of a given test type and method
  private Str qname(Type type, Method method)
  {
    type.qname + "." + method.name
  }

/////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  ** Output stream for built-in reporting
  OutStream out := Env.cur.out

  ** Should tests be run in verbose mode
  Bool isVerbose

  private Str[] failures := [,]
  private Int numFailures() { failures.size }
  private Duration startTicks := Duration.now
  private Int numTypes
  private Int numMethods
  private Int numVerifies
}

