//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   6 Feb 10  Andy Frank  Creation
//

using compiler
using fandoc

**
** PodDocGenerator generates pod-doc from pod.fandoc.
**
class PodDocGenerator : FandocToHtmlGenerator
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(DocCompiler compiler, Loc loc, File file)
    : super(compiler, loc, file, null)
  {
    this.pod = compiler.pod
    this.in  = pod.file(`/doc/pod.fandoc`, false)
    if (in != null)
    {
      try
        this.doc = FandocParser().parse(in.name, in.in)
      catch (Err e)
        errReport(CompilerErr("Cannot parse fandoc file", Loc.makeFile(in), e))
    }
  }

//////////////////////////////////////////////////////////////////////////
// Generator
//////////////////////////////////////////////////////////////////////////

  ** Doc title.
  override Str title() { "$pod.name PodDoc" }

  ** PodDoc content.
  override Void content()
  {
    // pod name
    out.printLine(
      "<div class='type'>
        <div class='overview'>
         <h2>pod</h2>
         <h1>$pod.name</h1>
        </div>
       </div>")

    // fandoc
    doc?.children?.each |node| { node.write(this) }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Pod pod   // current pod
  File? in  // pod.fandoc

}