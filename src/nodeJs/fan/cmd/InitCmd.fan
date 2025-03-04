//
// Copyright (c) 2023, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   27 Jul 2023  Matthew Giannini  Creation
//

using compiler
using util

internal class InitCmd : NodeJsCmd
{
  override Str name() { "init" }

  override Str summary() { "Initialize Node.js environment for running Fantom modules" }

  @Opt { help = "Root directory for staging Node.js environment"; aliases = ["-d"] }
  override File dir := Env.cur.homeDir.plus(`lib/es/`)

  override Int run()
  {
    emit.writePackageJson
    emit.writeNodeModules
    writeFantomJs
    writeTsDecl
    log.info("Initialized Node.js in: ${this.dir}")
    return 0
  }

  ** Write 'fantom.js' which ensures that all the supporting
  ** sys libraries are run.
  private Void writeFantomJs()
  {
    out := ms.file("fantom").out
    ms.writeBeginModule(out)
    ["sys", "fan_indexed_props", "fan_mime", "fan_units"].each |m| { ms.writeInclude(out, "${m}.ext") }
    ["os", "path", "fs", "url"].each |m| { ms.writeInclude(out, "${m}") }

    template := this.typeof.pod.file(`/res/fantomTemplate.js`).readAllStr
    out.writeChars(template)

    ms.writeExports(out, ["sys", "boot"])
    ms.writeEndModule(out).flush.close
  }

  ** Write 'sys.t.ds'
  private Void writeTsDecl()
  {
    sysDecl := ms.moduleDir.plus(`sys.d.ts`)
    out := sysDecl.out
    GenTsDecl.genForPod(Pod.find("sys"), out, ["allTypes":true])
    out.flush.close
  }
}
