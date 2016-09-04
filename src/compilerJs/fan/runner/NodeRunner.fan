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
    template := this.typeof.pod.file(`/res/testRunnerTemplate.js`).readAllStr
    template = template.replace("//{{require}}", requireStatements)
    template = template.replace("//{{tests}}", testList(pod, type, method))
    template = template.replace("//{{envDirs}}", envDirs)

    // write test runner
    f := nodeDir + `testRunner.js`
    f.out.writeChars(template).flush.close

    // invoke node to run tests
    t1 := Duration.now
    Process(["node", "$f.normalize.osPath"]).run.join
    t2 := Duration.now

    echo("")
    echo("Time: ${(t2-t1).toMillis}ms")
    echo("")
  }

  private Str requireStatements()
  {
    buf := StrBuf()
    dependencies.each |pod|
    {
      if ("sys" == pod.name)
      {
        buf.add("var fan = require('${pod.name}.js');\n")
        buf.add("require('tz.js');\n")
        buf.add("require('units.js');\n")
        buf.add("require('indexed-props.js');\n")
      }
      else buf.add("require('${pod.name}.js');\n")
    }
    return buf.toStr
  }

  private Str testList(Pod pod, Str type, Str method)
  {
    buf := StrBuf()
    buf.add("var tests = [\n")

    types := type == "*" ? pod.types : [pod.type(type)]
    types.findAll { it.fits(Test#) && it.hasFacet(Js#) }.each |t|
    {
      buf.add("  {'type': fan.${pod.name}.${t.name},\n")
         .add("   'qname': '${t.qname}',\n")
         .add("   'methods': [")
      methods(t, method).each { buf.add("'${it.name}',") } ; buf.add("]\n")
      buf.add("  },\n")
    }

    return buf.add("];\n").toStr
  }

  private Str envDirs()
  {
    buf := StrBuf()
    buf.add("    fan.sys.Env.cur().m_homeDir = fan.sys.File.os(${Env.cur.homeDir.osPath.toCode});\n")
    buf.add("    fan.sys.Env.cur().m_workDir = fan.sys.File.os(${Env.cur.workDir.osPath.toCode});\n")
    buf.add("    fan.sys.Env.cur().tempDir   = fan.sys.File.os(${Env.cur.tempDir.osPath.toCode});\n")
    return buf.toStr()
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
    this.dependencies = ordered.findAll { isJsPod(it) }
  }

  private [Pod:Pod[]] buildGraph(Pod p, Pod:Pod[] graph := [:])
  {
    graph[p] = p.depends.map { Pod.find(it.name) }
    p.depends.each |d| { buildGraph(Pod.find(d.name), graph) }
    return graph
  }

  private Bool isJsPod(Pod pod)
  {
    return pod.file(`/${pod.name}.js`, false) != null
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
}
