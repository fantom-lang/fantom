//
// Copyright (c) 2016, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   02 Sep 16  Matthew Giannini  Creation
//

class NodeRunner
{

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

  Int main(Str[] args := Env.cur.args)
  {
    try
    {
      parseArgs(args)
      initDirs
      if (hasArg("test")) doTest
      else throw ArgErr("Invalid options")
    }
    catch (ArgErr e)
    {
      Env.cur.err.printLine("${e.msg}\n")
      help
      return -1
    }
    return 0
  }

  private Void help()
  {
    echo("NodeRunner")
    echo("Usage:")
    echo("  NodeRunner [options] -test <pod>[::<test>[.<method>]]")
    echo("Options:")
    echo("  -keep      Keep intermediate test scripts")
  }

  private Void initDirs()
  {
    this.nodeDir = Env.cur.tempDir + `nodeRunner/`
    if (hasArg("dir"))
      nodeDir = arg("dir").toUri.plusSlash.toFile
    nodeDir = nodeDir.normalize
  }

//////////////////////////////////////////////////////////////////////////
// Args
//////////////////////////////////////////////////////////////////////////

  private Bool hasArg(Str n) { argsMap.containsKey(n) }

  private Str? arg(Str n) { argsMap[n] }

  private Void parseArgs(Str[] envArgs)
  {
    this.argsMap = Str:Str[:]

    // parse command lines arg "-key [val]"
    envArgs.each |s, i|
    {
      if (!s.startsWith("-") || s.size < 2) return
      name := s[1..-1]
      val  := "true"
      if (i+1 < envArgs.size && !envArgs[i+1].startsWith("-"))
        val = envArgs[i+1]
      this.argsMap[name] = val
    }
  }

//////////////////////////////////////////////////////////////////////////
// Test
//////////////////////////////////////////////////////////////////////////

  private Void doTest()
  {
    pod    := arg("test") ?: throw ArgErr("No test specified")
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

    p := Pod.find(pod)
    sortDepends(p)
    writeNodeModules
    testRunner(p, type, method)

    // cleanup
    if (!hasArg("keep")) nodeDir.delete
  }

  private Void testRunner(Pod pod, Str type, Str method)
  {
    t1 := Duration.now
    if (type != "*")
    {
      runTests(pod.type(type), method)
    }
    else
    {
      pod.types.each |t| { if (t.fits(Test#) && t.hasFacet(Js#)) runTests(t, "*") }
    }
    t2 := Duration.now

    echo("")
    echo("Time: ${(t2-t1).toMillis}ms")
    echo("")
    results
  }

  private Void runTests(Type type, Str methodName := "*")
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
    }
    testCount++
  }

  private Method[] methods(Type type, Str methodName)
  {
    return type.methods.findAll |Method m->Bool|
    {
      if (m.isAbstract) return false
      if (m.name.startsWith("test"))
      {
        if (methodName == "*") return true
        return methodName == m.name
      }
      return false
    }
  }

  private Int runTest(Method m)
  {
    try
    {
      // env dirs
      homeDir := Env.cur.homeDir
      workDir := Env.cur.workDir
      tempDir := Env.cur.tempDir

      js          := "fan.${m.parent.pod}.${m.parent.name}"
      testName    := "${js}-${m.name}"
      testResults := (nodeDir + `${testName}.results`).deleteOnExit
      script := Buf()
      dependencies.each |pod|
      {
        if ("sys" == pod.name)
        {
          script.printLine("var fan = require('${pod.name}.js');")
          script.printLine("require('tz.js');")
          script.printLine("require('units.js');")
          script.printLine("require('indexed-props.js');")
        }
        else script.printLine("require('${pod.name}.js');")
      }
      script.printLine("var fs=require('fs');")
      script.printLine(
       "var testRunner = function()
        {
          var test;
          var doCatchErr = function(err)
          {
            if (err == undefined) print('Undefined error\\n');
            else if (err.trace) err.trace();
            else
            {
              var file = err.fileName;   if (file == null) file = 'Unknown';
              var line = err.lineNumber; if (line == null) line = 'Unknown';
              fan.sys.Env.cur().out().printLine(err + ' (' + file + ':' + line + ')\\n');
            }
          }

          try
          {
            fan.sys.Env.cur().m_homeDir = fan.sys.File.os($homeDir.osPath.toCode);
            fan.sys.Env.cur().m_workDir = fan.sys.File.os($workDir.osPath.toCode);
            fan.sys.Env.cur().m_tempDir = fan.sys.File.os($tempDir.osPath.toCode);

            test = ${js}.make();
            test.setup();
            test.${m.name}();
            fs.writeFileSync('${testResults.normalize.osPath}', 'verify.count=' + test.verifyCount);
            process.exit(0);
          }
          catch (err)
          {
            doCatchErr(err);
            fs.writeFileSync('${testResults.normalize.osPath}', 'verify.count=-1');
            process.exit(1);
          }
          finally
          {
            try { test.teardown(); }
            catch (err) { doCatchErr(err); }
          }
        }
        testRunner();")

      // write test script
      f := nodeDir + `${testName}.js`
      f.out.writeChars(script.flip.readAllStr).flush.close

      // invoke node
      Process(["node", "$f.normalize.osPath"]).run.join
      return testResults.readProps["verify.count"].toInt(10);
    }
    catch (Err e)
    {
      echo("")
      echo("TEST FAILED")
      e.trace
      return -1
    }
  }

  Void results()
  {
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
// Dependency Graphing
//////////////////////////////////////////////////////////////////////////

  private Void sortDepends(Pod p)
  {
    graph   := buildGraph(p)
    ordered := Pod[,]
    visited := Pod[,]
    path    := Pod[,]
    graph.keys.each |pod|
    {
      path.push(pod)
      while (!path.isEmpty)
      {
        cur := path.pop
        if (visited.contains(cur)) continue

        todo := graph[cur]

        if (todo.isEmpty)
        {
          ordered.add(cur)
          visited.add(cur)
        }
        else
        {
          path.push(cur)
          next := todo.pop
          if (path.contains(next)) throw Err("Circular dependency between ${cur} and ${next} : ${path}")
          path.push(next)
        }
      }
    }
    this.dependencies = ordered
  }

  private [Pod:Pod[]] buildGraph(Pod p, Pod:Pod[] graph := [:])
  {
    graph[p] = p.depends.map { Pod.find(it.name) }
    p.depends.each |d| { buildGraph(Pod.find(d.name), graph) }
    return graph
  }

//////////////////////////////////////////////////////////////////////////
// Node
//////////////////////////////////////////////////////////////////////////

  ** Copy all pod js files into <nodeDir>/node_modules
  ** Also copies in tz.js, units.js, and indexed-props.js
  private Void writeNodeModules()
  {
    moduleDir := nodeDir + `node_modules/`
    copyOpts  := ["overwrite": true]

    // pod js files
    dependencies.each |pod|
    {
      script := "${pod.name}.js"
      file   := pod.file(`/$script`, false)
      if (file != null)
      file.copyTo(moduleDir + `$script`, copyOpts)
    }

    // tz.js
    (Env.cur.homeDir + `etc/sys/tz.js`).copyTo(moduleDir + `tz.js`, copyOpts)

    // units.js
    out := (moduleDir + `units.js`).out
    JsUnitDatabase().write(out)
    out.flush.close

    // indexed-props
    out = (moduleDir + `indexed-props.js`).out
    JsIndexedProps().write(out, dependencies)
    out.flush.close
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private [Str:Str]? argsMap      // parseArgs
  private File? nodeDir           // initDirs
  private Pod[]? dependencies     // sortDepens

  // Test
  private Int testCount        := 0
  private Int methodCount      := 0
  private Int totalVerifyCount := 0
  private Int failures         := 0
  Str[] failureNames           := [,]

}
