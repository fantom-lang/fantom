//
// Copyright (c) 2023, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   28 Jul 2023  Matthew Giannini  Creation
//

using compiler
using util

internal class RunCmd : NodeJsCmd
{
  override Str name() { "run" }

  override Str summary() { "Run a Fantom script in Node.js" }

  @Opt { help = "Don't delete Node.js environment when done" }
  Bool keep

  @Arg { help = "Fantom script" }
  File? script

  const Str tempPod := "temp${Duration.now.toMillis}"

  override Int run()
  {
    if (!script.exists) return err("${script} not found")

    // compile the script
    emit.withScript(this.compile)

    // write modules
    emit.writePackageJson(["name":"scriptRunner", "main":"scriptRunner.js"])
    emit.writeNodeModules

    // generate scriptRunner.js
    template := this.typeof.pod.file(`/res/scriptRunnerTemplate.js`).readAllStr
    template = template.replace("//{{include}}", emit.includeStatements)
    template = template.replace("{{tempPod}}", tempPod)
    template = template.replace("//{{envDirs}}", emit.envDirs)

    f := this.dir.plus(`scriptRunner.js`)
    f.out.writeChars(template).flush.close

    // invoke node to run the script
    Process(["node", "${f.normalize.osPath}"]).run.join

    if (!keep) this.dir.delete

    return 0
  }

  private File compile()
  {
    input := CompilerInput()
    input.podName   = tempPod
    input.summary   = ""
    input.version   = Version("0")
    input.log.level = LogLevel.silent
    input.isScript  = true
    input.srcStr    = this.script.in.readAllStr
    input.srcStrLoc = Loc("")
    input.mode      = CompilerInputMode.str
    input.output    = CompilerOutputMode.transientPod

    // compile the source
    compiler := Compiler(input)
    CompilerOutput? co := null
    try co = compiler.compile; catch {}
    if (co == null)
    {
      buf := StrBuf()
      compiler.errs.each |err| { buf.add("$err.line:$err.col:$err.msg\n") }
      throw Err.make(buf.toStr)
    }

    // configure the dependencies
    emit.withDepends(compiler.depends.map { Pod.find(it.name) })

    // return generated js
    return compiler.cjs.toBuf.toFile(`${tempPod}.js`)
  }
}

