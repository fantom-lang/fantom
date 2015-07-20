//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   02 Jul 15  Matthew Giannini  Creation
//

using compiler

class SourceMap
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(JsCompilerSupport support)
  {
    this.support = support
    this.c = support.compiler
  }

//////////////////////////////////////////////////////////////////////////
// SourceMap
//////////////////////////////////////////////////////////////////////////

  This add(Str text, Loc genLoc, Loc srcLoc, Str? name := null)
  {
    // map source
    File? source := files.getOrAdd(srcLoc.file) |->File?| { findSource(srcLoc) }
    if (source == null) return this

    // add map field
    fields.add(MapField(text, genLoc, srcLoc, name))
    return this
  }

  private File? findSource(Loc loc)
  {
    c.srcFiles?.find { it.osPath == File.os(loc.file).osPath }
  }

//////////////////////////////////////////////////////////////////////////
// Output
//////////////////////////////////////////////////////////////////////////

  Void write(OutStream out := Env.cur.out)
  {
    pod := support.pod.name
    out.writeChars("{\n")
    out.writeChars("\"version\": 3,\n")
    out.writeChars("\"file\": \"${pod}.js\",\n")
    out.writeChars("\"sourceRoot\": \"/dev/${pod}/\",\n")
    writeSources(out)
    writeMappings(out)
    out.writeChars("}\n")
    out.flush
  }

  private Void writeSources(OutStream out)
  {
    // write sources
    out.writeChars("\"sources\": [")
    files.vals.each |file, i|
    {
      if (i > 0) out.writeChars(",")
      if (file == null) out.writeChars("null")
      else out.writeChars("\"${file.name}\"")
    }
    out.writeChars("],\n")
  }

  private Void writeMappings(OutStream out)
  {
    // map source index
    srcIdx := [Str:Int][:]
    files.keys.each |k, i| { srcIdx[k] = i }

    out.writeChars("\"mappings\": \"")
    prevLine := 0
    prevIdx  := 0
    MapField? prevField
    fields.each |MapField f|
    {
      genLine := f.genLoc.line
      if (genLine < prevLine) throw Err("${f} is before line ${prevLine}")

      // calculate diffs
      genColDiff  := f.genLoc.col - (prevField?.genLoc?.col ?: 0)
      srcDiff     := srcIdx[f.srcLoc.file] - prevIdx
      srcLineDiff := f.srcLine - (prevField?.srcLine ?: 0)
      srcColDiff  := f.srcCol - (prevField?.srcCol ?: 0)

      // write missing new lines if necessary
      isNewline := prevLine < genLine || genLine == 0
      while (prevLine < genLine)
      {
        out.writeChar(';')
        ++prevLine
      }
      if (!isNewline) out.writeChar(',')

      // write segment fields
      out.writeChars(Base64VLQ.encode(genColDiff))
         .writeChars(Base64VLQ.encode(srcDiff))
         .writeChars(Base64VLQ.encode(srcLineDiff))
         .writeChars(Base64VLQ.encode(srcColDiff))

      // update prev state
      prevIdx = srcIdx[f.srcLoc.file]
      prevField = f
    }
    out.writeChars(";\"\n")
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private JsCompilerSupport support
  private Compiler c
  private [Str:File?] files := [Str:File][:] { ordered = true }
  private MapField[] fields := [,]
}

class MapField
{
  new make(Str text, Loc genLoc, Loc srcLoc, Str? name)
  {
    this.text = text
    this.genLoc = genLoc
    this.srcLoc = srcLoc
    this.name = name
  }

  ** zero-indexed line from original source file
  Int srcLine() { srcLoc.line - 1 }
  ** zero-indexed column from original source file
  Int srcCol() { srcLoc.col - 1 }

  override Str toStr()
  {
    "([${srcLoc.file}, ${srcLine}, ${srcCol}], [${genLoc.line}, ${genLoc.col}], ${name}, ${text})"
  }

  Str text
  Loc genLoc
  Loc srcLoc
  Str? name
}
