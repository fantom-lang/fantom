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
    errs = CompilerErr[,]
    warns = CompilerErr[,]
    outDir = Env.cur.homeDir + `doc/`
    uriMapper = UriMapper(this)
    htmlTheme = HtmlTheme()
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
    CopyResources(this, pod, podOutDir).run
    if (!errs.isEmpty) throw errs.last
  }

  Void compileTopIndexToHtml()
  {
    log.info("DocCompiler [top index]")
    TopIndexToHtml(this).run
    BuildSearchIndex(this).run
    CopyResources(this, DocCompiler#.pod, outDir).run
    if (!errs.isEmpty) throw errs.last
  }

  Void compileSourceToHtml(Type t, File from, File to, Str podHeading, Str typeHeading)
  {
    loc := Loc.makeFile(from)
    gen := SourceToHtmlGenerator(this, loc, to.out, t, from)
    {
      it.isScript    = true
      it.podHeading  = podHeading
      it.typeHeading = typeHeading
    }
    gen.generate
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  CompilerLog log           // ctor
  CompilerErr[] errs        // accumulated errors
  CompilerErr[] warns       // accumulated warnings
  File? srcDir              // source tree (required for docsrc)
  File outDir               // top level output directory
  File? podOutDir           // Init: outDir + podName
  Pod? pod                  // pod to compile
  UriMapper uriMapper       // normalizes fandoc URIs to HTML
  Obj[]? fandocIndex        // FandocToHtml if we have "index.fog"
  Type? curType             // if running Api generation
  HtmlTheme htmlTheme       // html theme to use

}