//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 May 06  Brian Frank  Creation
//

using compiler
using fandoc

**
** DocCompiler manages the pipeline of compiling API and
** stand-alone fandoc documents into HTML.
**
class DocCompiler
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make()
  {
    log = CompilerLog()
    errors = CompilerErr[,]
    outDir = Repo.boot.home + `doc/`
    uriMapper = UriMapper(this)
  }

//////////////////////////////////////////////////////////////////////////
// Compile
//////////////////////////////////////////////////////////////////////////

  Void compilePodToHtml()
  {
    log.info("DocCompiler [$pod]")
    Init(this).run
    ApiToHtml(this).run
    SourceToHtml(this).run
    FandocToHtml(this).run
    PodIndexToHtml(this).run
    SymbolsToHtml(this).run
    CopyResources(this, pod, podDir).run
    if (!errors.isEmpty) throw errors.last
  }

  Void compileTopIndexToHtml()
  {
    log.info("DocCompiler [top index]")
    TopIndexToHtml(this).run
    BuildSearchIndex(this).run
    CopyResources(this, DocCompiler#.pod, outDir).run
    if (!errors.isEmpty) throw errors.last
  }

//////////////////////////////////////////////////////////////////////////
// Errors
//////////////////////////////////////////////////////////////////////////

  **
  ** Create, log, and return a CompilerErr.
  **
  CompilerErr err(Str msg, Location loc)
  {
    return errReport(CompilerErr(msg, loc))
  }

  **
  ** Log, store, and return the specified CompilerErr.
  **
  CompilerErr errReport(CompilerErr e)
  {
    log.compilerErr(e)
    errors.add(e)
    return e
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  CompilerLog log           // ctor
  CompilerErr[] errors      // accumulated errors
  File outDir               // output directory
  Pod? pod                  // pod to compile
  UriMapper uriMapper       // normalizes fandoc URIs to HTML
  File? podDir              // Init: outDir/podName
  Obj[]? fandocIndex        // FandocToHtml if we have "index.fog"
  Type? curType             // if running Api generation

}