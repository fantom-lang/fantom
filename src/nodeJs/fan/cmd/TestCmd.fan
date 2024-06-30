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
  Str[]? targets

  override Int run()
  {
    if (!checkForNode) return 1
    if (targets == null) return usage

    emit.withDepends(targetPods)
    emit.writePackageJson(["name":"testRunner", "main":"testRunner.js"])
    emit.writeNodeModules
    testRunner
    if (!keep) this.dir.delete

    return 0
  }

  ** Get all pods from target specifications. Always include 'util'
  ** so that we can reflect to run TestRunner
  private Pod[] targetPods()
  {
    pods := targets.map |Str spec->Pod|
    {
      name := spec
      if (spec.contains("::"))
      {
        i := spec.index("::")
        name = spec[0..i-1]
      }
      return Pod.find(name)
    }
    return pods.add(Pod.find("util")).unique
  }

  ** Write the testRunner.js and run it in Node.js
  private Void testRunner()
  {
    template := this.typeof.pod.file(`/res/testRunnerTemplate.js`).readAllStr
    template = template.replace("//{{include}}", emit.includeStatements)
    template = template.replace("//{{targets}}", fanTargets)
    template = template.replace("//{{envDirs}}", emit.envDirs)

    // write test runner
    f := this.dir.plus(`testRunner.js`)
    f.out.writeChars(template).flush.close

    // invoke node to run tests
    Process(["node", "${f.normalize.osPath}"]).run.join
  }

  ** Get javascript for constructing a Fantom List of the target specs
  private Str fanTargets()
  {
    s := StrBuf()
    s.add("""const targets = sys.List.make(sys.Type.find("sys::Str"),[""")
    this.targets.each |spec,i| {
      if (i > 0) s.add(",")
      s.add(spec.toCode)
    }
    return s.add("]);\n").toStr
  }
}