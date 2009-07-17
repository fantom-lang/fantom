//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Dec 05  Brian Frank  Creation
//   3 Jun 06  Brian Frank  Port from Java to Fan
//

**
** Search the module's source tree for all the fan source files and
** map them to SourceFile instances and store to Compiler.srcFiles.
** Also find all the resource files and map them to Compiler.resFiles.
** For right now, resource files are anything found in {srcDir}/res.
** Summary:
**   Compiler.srcDir/*.fan -> Compiler.srcFiles
**   Compiler.srcDir/res/* -> Compiler.resFiles
**
** During the standard pipeline this step is called by the InitInput step.
**
class FindSourceFiles : CompilerStep
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(Compiler compiler)
    : super(compiler)
  {
  }

//////////////////////////////////////////////////////////////////////////
// Run
//////////////////////////////////////////////////////////////////////////

  override Void run()
  {
    findSrcFiles
    findResFiles

    if (compiler.srcFiles.isEmpty && compiler.resFiles.isEmpty)
      throw err("No fan source files found", null)
  }

//////////////////////////////////////////////////////////////////////////
// Source Files
//////////////////////////////////////////////////////////////////////////

  private Void findSrcFiles()
  {
    srcFiles := File[,]
    compiler.input.srcDirs.each |File dir| { find(dir, srcFiles, "fan") }
    compiler.srcFiles = srcFiles

    // TODO-SYM
    podFan := compiler.input.homeDir + `pod.fan`
    if (podFan.exists) compiler.srcFiles.insert(0, podFan)

    if (log.isDebug)
    {
      log.debug("FindSourceFiles [${srcFiles.size} files]")
      log.indent
      srcFiles.each |File f| { log.debug("[$f]") }
      log.unindent
    }
    else
    {
      log.info("FindSourceFiles [${srcFiles.size} files]")
    }
  }

//////////////////////////////////////////////////////////////////////////
// Resource Files
//////////////////////////////////////////////////////////////////////////

  private Void findResFiles()
  {
    resFiles := File[,]
    compiler.input.resDirs.each |File dir| { find(dir, resFiles, null) }
    compiler.resFiles = resFiles

    if (log.isDebug)
    {
      log.debug("ResourceFiles [${resFiles.size} files]")
      log.indent
      resFiles.each |File f| { log.debug("[$f]") }
      log.unindent
    }
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  private Void find(File dir, File[] acc, Str? ext)
  {
    if (!dir.isDir) throw err("Invalid directory", Location.makeFile(dir))
    dir.list.each |File f|
    {
      if (f.isDir) return
      if (ext == null || f.ext == ext) acc.add(f)
    }
  }

}