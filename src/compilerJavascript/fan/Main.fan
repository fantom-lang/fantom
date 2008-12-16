//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Dec 08  Andy Frank  Creation
//

using build
using compiler

**
** The command line Javascript compiler.
**
class Main
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

    pod := Pod.find(Sys.args.first)
    scriptFile := Sys.homeDir + "src/$pod.name/build.fan".toUri
    tempDir := scriptFile.parent + `temp-javascript/`
    tempDir.delete
    tempDir.create

    echo("javascript [$pod.name]")
    script := Sys.compile(scriptFile).make
    compile(script, tempDir)
    assemble(script, tempDir)

    tempDir.delete
  }

  Void help()
  {
    echo("Fan Javascript Compiler");
    echo("Usage:");
    echo("  compilerJavascript <podName>");
  }

//////////////////////////////////////////////////////////////////////////
// Compile
//////////////////////////////////////////////////////////////////////////

  Void compile(BuildPod script, File outDir)
  {
    input := CompilerInput.make
    input.inputLoc    = Location.makeFile(script.scriptFile)
    input.podName     = script.podName
    input.version     = script.version
    input.description = script.description
    input.podFacets   = script->podFacets
    input.depends     = script->parseDepends
    input.dependsDir  = resolveDir(script.scriptDir, script->dependsDir, true)
    input.log         = script.log
    input.mode        = CompilerInputMode.file
    input.homeDir     = script.scriptDir
    input.srcDirs     = resolveDirs(script.scriptDir, script.srcDirs)
    input.outDir      = script.libFanDir
    input.output      = CompilerOutputMode.podFile
    script.log.indent
    CompilerJavascript.make(input) { outDir = outDir }.compile
  }

//////////////////////////////////////////////////////////////////////////
// Assemble
//////////////////////////////////////////////////////////////////////////

  Void assemble(BuildPod script, File srcDir)
  {
    // TODO - we can't stick inside the pod file unless we run
    // with rel install, so just stick in /lib/javascript for now

    /*
    jar := JdkTask.make(script).jarExe
    pod := Sys.homeDir + "lib/fan/${script->podName}.pod".toUri
    Exec.make(script, [jar.osPath, "fu", pod.osPath, "-C", srcDir.osPath, "."], srcDir).run
    */

    js := srcDir + "${script.podName}.js".toUri
    js.copyTo(Sys.homeDir + "lib/javascript/$js.name".toUri, ["overwrite":true])
  }

//////////////////////////////////////////////////////////////////////////
// Support
//////////////////////////////////////////////////////////////////////////

  private File? resolveDir(File scriptDir, Uri? uri, Bool nullOk := false)
  {
    return resolveUris(scriptDir, [uri], nullOk, true)[0]
  }

  private File?[] resolveDirs(File scriptDir, Uri?[]? uris, Bool nullOk := false)
  {
    return resolveUris(scriptDir, uris, nullOk, true)
  }

  private File?[] resolveUris(File scriptDir, Uri?[]? uris, Bool nullOk, Bool expectDir)
  {
    files := File?[,]
    if (uris == null) return files

    files.capacity = uris.size
    ok := true
    uris.each |Uri? uri|
    {
      if (uri == null)
      {
        if (!nullOk) throw FatalBuildErr.make("Unexpected null Uri")
        files.add(null)
        return
      }

      file := scriptDir + uri
      if (!file.exists || file.isDir != expectDir )
      {
        ok = false
        if (expectDir)
          echo("Invalid directory [$uri]")
        else
          echo("Invalid file [$uri]")
      }
      files.add(file)
    }
    if (!ok) throw FatalBuildErr.make
    return files
  }

}