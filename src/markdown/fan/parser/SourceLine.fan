//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   08 Oct 2024  Matthew Giannini  Creation
//

**
** A line or portion of a line from the markdown source text
**
@Js
const class SourceLine
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(Str content, SourceSpan? sourceSpan := null)
  {
    this.content = content
    this.sourceSpan = sourceSpan
  }

  ** The line content
  const Str content

  ** The source span if the parser was configured to include it
  const SourceSpan? sourceSpan

  ** Get a new source line that is a substring of this one.
  ** The beginIndex is inclusive, and the endIndex is exclusive.
  SourceLine substring(Int beginIndex, Int endIndex)
  {
    if (beginIndex < 0) throw ArgErr("beginIndex: ${beginIndex}")
    if (endIndex < 0) throw ArgErr("endIndex: ${endIndex}")
    newContent := this.content[beginIndex..<endIndex]
    SourceSpan? newSourceSpan := null
    if (sourceSpan != null)
    {
      len := endIndex - beginIndex
      if (len != 0)
      {
        columnIndex := sourceSpan.columnIndex + beginIndex
        inputIndex  := sourceSpan.inputIndex + beginIndex
        newSourceSpan = SourceSpan.of(sourceSpan.lineIndex, columnIndex, inputIndex, len)
      }
    }
    return SourceLine(newContent, newSourceSpan)
  }

  override Str toStr() { "sourceLine(content=${content})" }
}

**************************************************************************
** SourceLines
**************************************************************************

**
** A set of lines (`SourceLine`) from the input source.
**
@Js
class SourceLines
{
  static new empty() { SourceLines([,]) }

  new makeOne(SourceLine line) : this.make([line]) { }

  new make(SourceLine[] lines)
  {
    this.lines.addAll(lines)
  }

  SourceLine[] lines := [,] { private set }

  Bool isEmpty() { lines.isEmpty }

  Void addLine(SourceLine line) { lines.add(line) }

  Str content()
  {
    sb := StrBuf()
    lines.each |line, i|
    {
      if (i != 0) sb.addChar('\n')
      sb.add(line.content)
    }
    return sb.toStr
  }

  SourceSpan[] sourceSpans()
  {
    sourceSpans := SourceSpan[,]
    lines.each |line|
    {
      sourceSpan := line.sourceSpan
      if (sourceSpan != null) sourceSpans.add(sourceSpan)
    }
    return sourceSpans
  }
}
