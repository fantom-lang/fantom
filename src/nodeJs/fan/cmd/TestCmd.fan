//
// Copyright (c) 2023, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   27 Jul 2023  Matthew Giannini  Creation
//

using util

internal class TestCmd : NodeJsCmd
{
  override Str name() { "test" }

  override Str summary() { "Run tests in Node.js" }

  @Opt { help = "Don't delete Node.js environment when done" }
  Bool keep

  @Arg { help = "<pod>[::<test>[.<method>]]" }
  Str? spec

  override Int run()
  {
    if (!checkForNode) return 1

    pod    := this.spec
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
    emit.withDepends([p])
    emit.writePackageJson(["name":"testRunner", "main":"testRunner.js"])
    emit.writeNodeModules
    testRunner(p, type, method)

    if (!keep) this.dir.delete

    return 0
  }

  private Void testRunner(Pod pod, Str type, Str method)
  {
    template := this.typeof.pod.file(`/res/testRunnerTemplate.js`).readAllStr
    template = template.replace("//{{include}}", emit.includeStatements)
    template = template.replace("//{{tests}}", testList(pod, type, method))
    template = template.replace("//{{envDirs}}", emit.envDirs)

    // write test runner
    f := this.dir.plus(`testRunner.js`)
    f.out.writeChars(template).flush.close

    // invoke node to run tests
    t1 := Duration.now
    Process(["node", "${f.normalize.osPath}"]).run.join
    t2 := Duration.now

    printLine
    printLine("Time: ${(t2-t1).toLocale}")
    printLine
  }

  private Str testList(Pod pod, Str type, Str method)
  {
    buf := StrBuf()
    buf.add("const tests = [\n")

    types := type == "*" ? pod.types : [pod.type(type)]
    types.findAll { it.fits(Test#) && it.hasFacet(Js#) }.each |t|
    {
      buf.add("  {'type': ${pod.name}.${t.name},\n")
         .add("   'qname': '${t.qname}',\n")
         .add("   'methods': [")
      methods(t, method).each { buf.add("'${it.name}',") } ; buf.add("]\n")
      buf.add("  },\n")
    }
    return buf.add("];\n").toStr
  }

  private static Method[] methods(Type type, Str methodName)
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

}