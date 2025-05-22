//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 May 2025  Matthew Giannini  Creation
//

using build
using compiler
using compilerEs
using fanc

**
** JavaScript transpiler command
**
internal class JsCmd : TranspileCmd
{

//////////////////////////////////////////////////////////////////////////
// TranspileCmd
//////////////////////////////////////////////////////////////////////////

  override Str name() { "js" }

  override Str summary() { "Transpile to JavaScript" }

  override Int usage(OutStream out := Env.cur.out)
  {
    ret := super.usage(out)
    return ret
  }

//////////////////////////////////////////////////////////////////////////
// Run
//////////////////////////////////////////////////////////////////////////

  private ModuleSystem? ms

  override Int run()
  {
    super.run
    writePackageJson
    writeFanJs

    info("")
    info("NPM module written to ${outDir.osPath}")
    info("")

    return 0
  }

  override Void compilePod(TranspilePod pod)
  {
    info("## Transpile ${this.name} [${pod.name}]")

    // special handling for sys
    if (pod.name == "sys") return jsInit

    input := stdCompilerInput(pod) { it.forceJs = true }

    // run the frontend to compile the javascript
    c := Compiler(input)
    c.log.level = LogLevel.err
    c.frontend

    // write it to our output directory
    f := ms.file(pod.name)
    f.out.writeChars(c.esm).flush.close

    // always emit typescript definitions
    decl := f.parent.plus(`${pod.name}.d.ts`).out
    GenTsDecl(decl, c.pod, ["allTypes":true]).run
    decl.flush.close
  }

  private Void jsInit()
  {
    // initialize js
    cmd := InitCmd()
    cmd.log.level = LogLevel.silent
    cmd.dir = outDir
    cmd.run
    this.ms = cmd.ms
  }

  private Void writePackageJson()
  {
    outDir.plus(`package.json`).out.writeChars(
      """{
           "name": "@todo/package",
           "version": "0.0.1",
           "type": "module",
           "files": [
             "esm/"
           ]
         }"""
    ).close
  }

  private Void writeFanJs()
  {
    outDir.plus(`fan.js`).out.writeChars(
      """#!/usr/bin/env node
         import {boot} from './esm/fantom.js';
         const sys = await boot();
         export {sys};
         """
    ).close
  }
}