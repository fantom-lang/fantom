//
// Copyright (c) 2023, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   27 Jul 2023  Matthew Giannini  Creation
//

using compilerEs
using util

**
** Utility for emitting various JS code
**
internal class EmitUtil
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(NodeJsCmd cmd)
  {
    this.cmd = cmd
  }

  private NodeJsCmd cmd
  private Pod[] depends := [Pod.find("sys")]
  private File? scriptJs := null
  private ModuleSystem ms() { cmd.ms }
  private Bool isCjs() { ms.moduleType == "cjs" }

//////////////////////////////////////////////////////////////////////////
// Configure Dependencies
//////////////////////////////////////////////////////////////////////////

  ** Configure the pod dependencies before emitting any code
  This withDepends(Pod[] pods)
  {
    this.depends = Pod.orderByDepends(Pod.flattenDepends(pods))
    return this
  }

  ** Configure the script js for a Fantom script
  This withScript(File scriptJs)
  {
    this.scriptJs = scriptJs
    return this
  }

//////////////////////////////////////////////////////////////////////////
// Util
//////////////////////////////////////////////////////////////////////////

  private File? podJsFile(Pod pod, Str name := pod.name)
  {
    ext    := isCjs ? "js" : "mjs"
    script := "${name}.${ext}"
    return pod.file(`/js/$script`, false)
  }

//////////////////////////////////////////////////////////////////////////
// Emit
//////////////////////////////////////////////////////////////////////////

  Void writePackageJson([Str:Obj?] json := [:])
  {
    if (json["name"] == null) json["name"] = "@fantom/fan"
    if (json["version"] == null) json["version"] = Pod.find("sys").version.toStr
    ms.writePackageJson(json)
  }

  ** Copy all pod js files into '<dir>/node_modules/'.
  // ** Also copies in mime.js, units.js, and indexed-props.js
  Void writeNodeModules()
  {
    writeFanJs
    writeNode
    writeDepends
    writeScriptJs
    writeMimeJs
    writeUnitsJs
    // TODO: indexed-props?
  }

  ** Write 'es6.js' (grab it from sys.js)
  Void writeFanJs()
  {
    out := ms.file("fan").out
    podJsFile(Pod.find("sys"), "fan").in.pipe(out)
    out.flush.close
  }


  ** Write 'es6.js' (grab it from sys.js)
  Void writeEs6()
  {
    out := ms.file("es6").out
    podJsFile(Pod.find("sys"), "es6").in.pipe(out)
    out.flush.close
  }

  ** Write 'node.js'
  Void writeNode()
  {
    modules := ["os", "path", "fs", "crypto", "url", "zlib"]
    out := ms.file("node").out
    ms.writeBeginModule(out)
    modules.each |m, i| { ms.writeInclude(out, m) }
    ms.writeExports(out, modules)
    ms.writeEndModule(out).flush.close
  }

  ** Write js from configured pod dependencies
  Void writeDepends()
  {
    copyOpts  := ["overwrite": true]

    this.depends.each |pod|
    {
      file   := podJsFile(pod)
      target := ms.file(pod.name)
      if (file != null)
      {
        file.copyTo(target, copyOpts)
        // if (pod.name == "sys")
        // {
        //   out := target.out
        //   file.in.pipe(out)
        //   out.flush.close
        // }
        // else file.copyTo(target, copyOpts)
      }
    }
  }

  ** Write the fantom script if one was configured
  Void writeScriptJs()
  {
    if (scriptJs == null) return
    out := ms.file(scriptJs.basename).out
    try
    {
      scriptJs.in.pipe(out)
    }
    finally out.flush.close
  }

  ** Write the code for configuring MIME types to 'fan_mime.js'
  Void writeMimeJs()
  {
    out := ms.file("fan_mime").out
    JsExtToMime(ms).write(out)
    out.flush.close
  }

  ** Write the unit database to 'fan_units.js'
  Void writeUnitsJs()
  {
    out := ms.file("fan_units").out
    JsUnitDatabase(ms).write(out)
    out.flush.close
  }

//////////////////////////////////////////////////////////////////////////
// Str
//////////////////////////////////////////////////////////////////////////

  ** Get a Str with all the include statements for the configured
  ** dependencies that is targetted for the current module system
  ** This method assumes the script importing the modules is in
  ** the parent directory.
  Str includeStatements()
  {
    baseDir := "./${ms.moduleDir.name}/"
    buf     := Buf()
    this.depends.each |pod|
    {
      if ("sys" == pod.name)
      {
        // need explicit js ext because node has built-in lib named sys
        ms.writeInclude(buf.out, "sys.ext", baseDir)
        ms.writeInclude(buf.out, "fan_mime.ext", baseDir)
      }
      else ms.writeInclude(buf.out, "${pod.name}.ext", baseDir)
    }
    if (scriptJs != null) throw Err("TODO: script js")
    // if (scriptJs != null)
    //   buf.add("import * as ${scriptJs.basename} from './${ms.moduleType}/${scriptJs.name}';\n")
    return buf.flip.readAllStr
  }

  ** Get the JS code to configure the Env home, work and temp directories.
  Str envDirs()
  {
    buf := StrBuf()
    buf.add("  sys.Env.cur().__homeDir = sys.File.os(${Env.cur.homeDir.pathStr.toCode});\n")
    buf.add("  sys.Env.cur().__workDir = sys.File.os(${Env.cur.workDir.pathStr.toCode});\n")
    buf.add("  sys.Env.cur().__tempDir = sys.File.os(${Env.cur.tempDir.pathStr.toCode});\n")
    return buf.toStr
  }
}