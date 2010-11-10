//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 May 07  Brian Frank  Creation
//

using compiler
using fandoc

**
** FandocToHtml generates an HTML file for each fandoc file in pod
**
class FandocToHtml : DocCompilerStep
{

  new make(DocCompiler compiler)
    : super(compiler)
  {
  }

  Void run()
  {
    // first find all the fandoc files and see
    // if we can find the index.fandoc file
    fandocFiles := File[,]
    File? indexFile := null
    compiler.pod.files.each |File file|
    {
      if (file.name == "pod.fandoc")  // handled in PodIndexToHtml
        return
      else if (file.name == "index.fog")
        indexFile = file
      else if (file.ext == "fandoc")
        fandocFiles.add(file)
    }

    // if we have an index file process it first
    if (indexFile != null)
    {
      try
      {
        log.debug("  FandocIndex [$indexFile]")
        compiler.fandocIndex = indexFile.in.readObj
        loc := Loc.makeFile(indexFile)
        outFile := compiler.podOutDir + `index.html`
        FandocIndexToHtmlGenerator(compiler, loc, outFile.out).generate
      }
      catch (Err e)
      {
        errReport(CompilerErr("Cannot read index.fog",
          Loc.makeFile(indexFile), e))
      }
    }

    // process rest of the files
    fandocFiles.each |File file| { generate(file) }
  }

  Doc? generate(File inFile)

  {
    log.debug("  Fandoc [$inFile]")
    try
    {
      doc := FandocParser().parse(inFile.name, inFile.in)
      loc := Loc("${compiler.pod}::${inFile.name}")

      outFile := compiler.podOutDir + `${inFile.basename}.html`
      FandocToHtmlGenerator(compiler, loc, outFile, doc).generate

      return doc
    }
    catch (Err e)
    {
      errReport(CompilerErr("Cannot parse fandoc file", Loc.makeFile(inFile), e))
      return null
    }
  }

}